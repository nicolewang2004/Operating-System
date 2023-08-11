
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	91013103          	ld	sp,-1776(sp) # 80008910 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	fe078793          	addi	a5,a5,-32 # 80009030 <timer_scratch>
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
    80000066:	2be78793          	addi	a5,a5,702 # 80006320 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffa27d7>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	3ba78793          	addi	a5,a5,954 # 80001466 <main>
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
    80000104:	8a2a                	mv	s4,a0
    80000106:	892e                	mv	s2,a1
    80000108:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010a:	00011517          	auipc	a0,0x11
    8000010e:	06650513          	addi	a0,a0,102 # 80011170 <cons>
    80000112:	00001097          	auipc	ra,0x1
    80000116:	d74080e7          	jalr	-652(ra) # 80000e86 <acquire>
  for(i = 0; i < n; i++){
    8000011a:	05305b63          	blez	s3,80000170 <consolewrite+0x7e>
    8000011e:	4481                	li	s1,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	864a                	mv	a2,s2
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	8dc080e7          	jalr	-1828(ra) # 80002a08 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x5a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	7ee080e7          	jalr	2030(ra) # 8000092a <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2485                	addiw	s1,s1,1
    80000146:	0905                	addi	s2,s2,1
    80000148:	fc999de3          	bne	s3,s1,80000122 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014c:	00011517          	auipc	a0,0x11
    80000150:	02450513          	addi	a0,a0,36 # 80011170 <cons>
    80000154:	00001097          	auipc	ra,0x1
    80000158:	e02080e7          	jalr	-510(ra) # 80000f56 <release>

  return i;
}
    8000015c:	8526                	mv	a0,s1
    8000015e:	60a6                	ld	ra,72(sp)
    80000160:	6406                	ld	s0,64(sp)
    80000162:	74e2                	ld	s1,56(sp)
    80000164:	7942                	ld	s2,48(sp)
    80000166:	79a2                	ld	s3,40(sp)
    80000168:	7a02                	ld	s4,32(sp)
    8000016a:	6ae2                	ld	s5,24(sp)
    8000016c:	6161                	addi	sp,sp,80
    8000016e:	8082                	ret
  for(i = 0; i < n; i++){
    80000170:	4481                	li	s1,0
    80000172:	bfe9                	j	8000014c <consolewrite+0x5a>

0000000080000174 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000174:	7119                	addi	sp,sp,-128
    80000176:	fc86                	sd	ra,120(sp)
    80000178:	f8a2                	sd	s0,112(sp)
    8000017a:	f4a6                	sd	s1,104(sp)
    8000017c:	f0ca                	sd	s2,96(sp)
    8000017e:	ecce                	sd	s3,88(sp)
    80000180:	e8d2                	sd	s4,80(sp)
    80000182:	e4d6                	sd	s5,72(sp)
    80000184:	e0da                	sd	s6,64(sp)
    80000186:	fc5e                	sd	s7,56(sp)
    80000188:	f862                	sd	s8,48(sp)
    8000018a:	f466                	sd	s9,40(sp)
    8000018c:	f06a                	sd	s10,32(sp)
    8000018e:	ec6e                	sd	s11,24(sp)
    80000190:	0100                	addi	s0,sp,128
    80000192:	8caa                	mv	s9,a0
    80000194:	8aae                	mv	s5,a1
    80000196:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000198:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000019c:	00011517          	auipc	a0,0x11
    800001a0:	fd450513          	addi	a0,a0,-44 # 80011170 <cons>
    800001a4:	00001097          	auipc	ra,0x1
    800001a8:	ce2080e7          	jalr	-798(ra) # 80000e86 <acquire>
  while(n > 0){
    800001ac:	09405663          	blez	s4,80000238 <consoleread+0xc4>
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001b0:	00011497          	auipc	s1,0x11
    800001b4:	fc048493          	addi	s1,s1,-64 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b8:	89a6                	mv	s3,s1
    800001ba:	00011917          	auipc	s2,0x11
    800001be:	05690913          	addi	s2,s2,86 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c2:	4c11                	li	s8,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c4:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c6:	4da9                	li	s11,10
    while(cons.r == cons.w){
    800001c8:	0a04a783          	lw	a5,160(s1)
    800001cc:	0a44a703          	lw	a4,164(s1)
    800001d0:	02f71463          	bne	a4,a5,800001f8 <consoleread+0x84>
      if(myproc()->killed){
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	d62080e7          	jalr	-670(ra) # 80001f36 <myproc>
    800001dc:	5d1c                	lw	a5,56(a0)
    800001de:	eba5                	bnez	a5,8000024e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001e0:	85ce                	mv	a1,s3
    800001e2:	854a                	mv	a0,s2
    800001e4:	00002097          	auipc	ra,0x2
    800001e8:	56c080e7          	jalr	1388(ra) # 80002750 <sleep>
    while(cons.r == cons.w){
    800001ec:	0a04a783          	lw	a5,160(s1)
    800001f0:	0a44a703          	lw	a4,164(s1)
    800001f4:	fef700e3          	beq	a4,a5,800001d4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f8:	0017871b          	addiw	a4,a5,1
    800001fc:	0ae4a023          	sw	a4,160(s1)
    80000200:	07f7f713          	andi	a4,a5,127
    80000204:	9726                	add	a4,a4,s1
    80000206:	02074703          	lbu	a4,32(a4)
    8000020a:	00070b9b          	sext.w	s7,a4
    if(c == C('D')){  // end-of-file
    8000020e:	078b8863          	beq	s7,s8,8000027e <consoleread+0x10a>
    cbuf = c;
    80000212:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000216:	4685                	li	a3,1
    80000218:	f8f40613          	addi	a2,s0,-113
    8000021c:	85d6                	mv	a1,s5
    8000021e:	8566                	mv	a0,s9
    80000220:	00002097          	auipc	ra,0x2
    80000224:	792080e7          	jalr	1938(ra) # 800029b2 <either_copyout>
    80000228:	01a50863          	beq	a0,s10,80000238 <consoleread+0xc4>
    dst++;
    8000022c:	0a85                	addi	s5,s5,1
    --n;
    8000022e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000230:	01bb8463          	beq	s7,s11,80000238 <consoleread+0xc4>
  while(n > 0){
    80000234:	f80a1ae3          	bnez	s4,800001c8 <consoleread+0x54>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000238:	00011517          	auipc	a0,0x11
    8000023c:	f3850513          	addi	a0,a0,-200 # 80011170 <cons>
    80000240:	00001097          	auipc	ra,0x1
    80000244:	d16080e7          	jalr	-746(ra) # 80000f56 <release>

  return target - n;
    80000248:	414b053b          	subw	a0,s6,s4
    8000024c:	a811                	j	80000260 <consoleread+0xec>
        release(&cons.lock);
    8000024e:	00011517          	auipc	a0,0x11
    80000252:	f2250513          	addi	a0,a0,-222 # 80011170 <cons>
    80000256:	00001097          	auipc	ra,0x1
    8000025a:	d00080e7          	jalr	-768(ra) # 80000f56 <release>
        return -1;
    8000025e:	557d                	li	a0,-1
}
    80000260:	70e6                	ld	ra,120(sp)
    80000262:	7446                	ld	s0,112(sp)
    80000264:	74a6                	ld	s1,104(sp)
    80000266:	7906                	ld	s2,96(sp)
    80000268:	69e6                	ld	s3,88(sp)
    8000026a:	6a46                	ld	s4,80(sp)
    8000026c:	6aa6                	ld	s5,72(sp)
    8000026e:	6b06                	ld	s6,64(sp)
    80000270:	7be2                	ld	s7,56(sp)
    80000272:	7c42                	ld	s8,48(sp)
    80000274:	7ca2                	ld	s9,40(sp)
    80000276:	7d02                	ld	s10,32(sp)
    80000278:	6de2                	ld	s11,24(sp)
    8000027a:	6109                	addi	sp,sp,128
    8000027c:	8082                	ret
      if(n < target){
    8000027e:	000a071b          	sext.w	a4,s4
    80000282:	fb677be3          	bleu	s6,a4,80000238 <consoleread+0xc4>
        cons.r--;
    80000286:	00011717          	auipc	a4,0x11
    8000028a:	f8f72523          	sw	a5,-118(a4) # 80011210 <cons+0xa0>
    8000028e:	b76d                	j	80000238 <consoleread+0xc4>

0000000080000290 <consputc>:
{
    80000290:	1141                	addi	sp,sp,-16
    80000292:	e406                	sd	ra,8(sp)
    80000294:	e022                	sd	s0,0(sp)
    80000296:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000298:	10000793          	li	a5,256
    8000029c:	00f50a63          	beq	a0,a5,800002b0 <consputc+0x20>
    uartputc_sync(c);
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	58a080e7          	jalr	1418(ra) # 8000082a <uartputc_sync>
}
    800002a8:	60a2                	ld	ra,8(sp)
    800002aa:	6402                	ld	s0,0(sp)
    800002ac:	0141                	addi	sp,sp,16
    800002ae:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002b0:	4521                	li	a0,8
    800002b2:	00000097          	auipc	ra,0x0
    800002b6:	578080e7          	jalr	1400(ra) # 8000082a <uartputc_sync>
    800002ba:	02000513          	li	a0,32
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	56c080e7          	jalr	1388(ra) # 8000082a <uartputc_sync>
    800002c6:	4521                	li	a0,8
    800002c8:	00000097          	auipc	ra,0x0
    800002cc:	562080e7          	jalr	1378(ra) # 8000082a <uartputc_sync>
    800002d0:	bfe1                	j	800002a8 <consputc+0x18>

00000000800002d2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d2:	1101                	addi	sp,sp,-32
    800002d4:	ec06                	sd	ra,24(sp)
    800002d6:	e822                	sd	s0,16(sp)
    800002d8:	e426                	sd	s1,8(sp)
    800002da:	e04a                	sd	s2,0(sp)
    800002dc:	1000                	addi	s0,sp,32
    800002de:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002e0:	00011517          	auipc	a0,0x11
    800002e4:	e9050513          	addi	a0,a0,-368 # 80011170 <cons>
    800002e8:	00001097          	auipc	ra,0x1
    800002ec:	b9e080e7          	jalr	-1122(ra) # 80000e86 <acquire>

  switch(c){
    800002f0:	47c1                	li	a5,16
    800002f2:	12f48463          	beq	s1,a5,8000041a <consoleintr+0x148>
    800002f6:	0297df63          	ble	s1,a5,80000334 <consoleintr+0x62>
    800002fa:	47d5                	li	a5,21
    800002fc:	0af48863          	beq	s1,a5,800003ac <consoleintr+0xda>
    80000300:	07f00793          	li	a5,127
    80000304:	02f49b63          	bne	s1,a5,8000033a <consoleintr+0x68>
      consputc(BACKSPACE);
    }
    break;
  case C('H'): // Backspace
  case '\x7f':
    if(cons.e != cons.w){
    80000308:	00011717          	auipc	a4,0x11
    8000030c:	e6870713          	addi	a4,a4,-408 # 80011170 <cons>
    80000310:	0a872783          	lw	a5,168(a4)
    80000314:	0a472703          	lw	a4,164(a4)
    80000318:	10f70563          	beq	a4,a5,80000422 <consoleintr+0x150>
      cons.e--;
    8000031c:	37fd                	addiw	a5,a5,-1
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	eef72d23          	sw	a5,-262(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000326:	10000513          	li	a0,256
    8000032a:	00000097          	auipc	ra,0x0
    8000032e:	f66080e7          	jalr	-154(ra) # 80000290 <consputc>
    80000332:	a8c5                	j	80000422 <consoleintr+0x150>
  switch(c){
    80000334:	47a1                	li	a5,8
    80000336:	fcf489e3          	beq	s1,a5,80000308 <consoleintr+0x36>
    }
    break;
  default:
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000033a:	c4e5                	beqz	s1,80000422 <consoleintr+0x150>
    8000033c:	00011717          	auipc	a4,0x11
    80000340:	e3470713          	addi	a4,a4,-460 # 80011170 <cons>
    80000344:	0a872783          	lw	a5,168(a4)
    80000348:	0a072703          	lw	a4,160(a4)
    8000034c:	9f99                	subw	a5,a5,a4
    8000034e:	07f00713          	li	a4,127
    80000352:	0cf76863          	bltu	a4,a5,80000422 <consoleintr+0x150>
      c = (c == '\r') ? '\n' : c;
    80000356:	47b5                	li	a5,13
    80000358:	0ef48363          	beq	s1,a5,8000043e <consoleintr+0x16c>

      // echo back to the user.
      consputc(c);
    8000035c:	8526                	mv	a0,s1
    8000035e:	00000097          	auipc	ra,0x0
    80000362:	f32080e7          	jalr	-206(ra) # 80000290 <consputc>

      // store for consumption by consoleread().
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000366:	00011797          	auipc	a5,0x11
    8000036a:	e0a78793          	addi	a5,a5,-502 # 80011170 <cons>
    8000036e:	0a87a703          	lw	a4,168(a5)
    80000372:	0017069b          	addiw	a3,a4,1
    80000376:	0006861b          	sext.w	a2,a3
    8000037a:	0ad7a423          	sw	a3,168(a5)
    8000037e:	07f77713          	andi	a4,a4,127
    80000382:	97ba                	add	a5,a5,a4
    80000384:	02978023          	sb	s1,32(a5)

      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000388:	47a9                	li	a5,10
    8000038a:	0ef48163          	beq	s1,a5,8000046c <consoleintr+0x19a>
    8000038e:	4791                	li	a5,4
    80000390:	0cf48e63          	beq	s1,a5,8000046c <consoleintr+0x19a>
    80000394:	00011797          	auipc	a5,0x11
    80000398:	ddc78793          	addi	a5,a5,-548 # 80011170 <cons>
    8000039c:	0a07a783          	lw	a5,160(a5)
    800003a0:	0807879b          	addiw	a5,a5,128
    800003a4:	06f61f63          	bne	a2,a5,80000422 <consoleintr+0x150>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003a8:	863e                	mv	a2,a5
    800003aa:	a0c9                	j	8000046c <consoleintr+0x19a>
    while(cons.e != cons.w &&
    800003ac:	00011717          	auipc	a4,0x11
    800003b0:	dc470713          	addi	a4,a4,-572 # 80011170 <cons>
    800003b4:	0a872783          	lw	a5,168(a4)
    800003b8:	0a472703          	lw	a4,164(a4)
    800003bc:	06f70363          	beq	a4,a5,80000422 <consoleintr+0x150>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003c0:	37fd                	addiw	a5,a5,-1
    800003c2:	0007871b          	sext.w	a4,a5
    800003c6:	07f7f793          	andi	a5,a5,127
    800003ca:	00011697          	auipc	a3,0x11
    800003ce:	da668693          	addi	a3,a3,-602 # 80011170 <cons>
    800003d2:	97b6                	add	a5,a5,a3
    while(cons.e != cons.w &&
    800003d4:	0207c683          	lbu	a3,32(a5)
    800003d8:	47a9                	li	a5,10
      cons.e--;
    800003da:	00011497          	auipc	s1,0x11
    800003de:	d9648493          	addi	s1,s1,-618 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003e2:	4929                	li	s2,10
    800003e4:	02f68f63          	beq	a3,a5,80000422 <consoleintr+0x150>
      cons.e--;
    800003e8:	0ae4a423          	sw	a4,168(s1)
      consputc(BACKSPACE);
    800003ec:	10000513          	li	a0,256
    800003f0:	00000097          	auipc	ra,0x0
    800003f4:	ea0080e7          	jalr	-352(ra) # 80000290 <consputc>
    while(cons.e != cons.w &&
    800003f8:	0a84a783          	lw	a5,168(s1)
    800003fc:	0a44a703          	lw	a4,164(s1)
    80000400:	02f70163          	beq	a4,a5,80000422 <consoleintr+0x150>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000404:	37fd                	addiw	a5,a5,-1
    80000406:	0007871b          	sext.w	a4,a5
    8000040a:	07f7f793          	andi	a5,a5,127
    8000040e:	97a6                	add	a5,a5,s1
    while(cons.e != cons.w &&
    80000410:	0207c783          	lbu	a5,32(a5)
    80000414:	fd279ae3          	bne	a5,s2,800003e8 <consoleintr+0x116>
    80000418:	a029                	j	80000422 <consoleintr+0x150>
    procdump();
    8000041a:	00002097          	auipc	ra,0x2
    8000041e:	644080e7          	jalr	1604(ra) # 80002a5e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000422:	00011517          	auipc	a0,0x11
    80000426:	d4e50513          	addi	a0,a0,-690 # 80011170 <cons>
    8000042a:	00001097          	auipc	ra,0x1
    8000042e:	b2c080e7          	jalr	-1236(ra) # 80000f56 <release>
}
    80000432:	60e2                	ld	ra,24(sp)
    80000434:	6442                	ld	s0,16(sp)
    80000436:	64a2                	ld	s1,8(sp)
    80000438:	6902                	ld	s2,0(sp)
    8000043a:	6105                	addi	sp,sp,32
    8000043c:	8082                	ret
      consputc(c);
    8000043e:	4529                	li	a0,10
    80000440:	00000097          	auipc	ra,0x0
    80000444:	e50080e7          	jalr	-432(ra) # 80000290 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000448:	00011797          	auipc	a5,0x11
    8000044c:	d2878793          	addi	a5,a5,-728 # 80011170 <cons>
    80000450:	0a87a703          	lw	a4,168(a5)
    80000454:	0017069b          	addiw	a3,a4,1
    80000458:	0006861b          	sext.w	a2,a3
    8000045c:	0ad7a423          	sw	a3,168(a5)
    80000460:	07f77713          	andi	a4,a4,127
    80000464:	97ba                	add	a5,a5,a4
    80000466:	4729                	li	a4,10
    80000468:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    8000046c:	00011797          	auipc	a5,0x11
    80000470:	dac7a423          	sw	a2,-600(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    80000474:	00011517          	auipc	a0,0x11
    80000478:	d9c50513          	addi	a0,a0,-612 # 80011210 <cons+0xa0>
    8000047c:	00002097          	auipc	ra,0x2
    80000480:	45a080e7          	jalr	1114(ra) # 800028d6 <wakeup>
    80000484:	bf79                	j	80000422 <consoleintr+0x150>

0000000080000486 <consoleinit>:

void
consoleinit(void)
{
    80000486:	1141                	addi	sp,sp,-16
    80000488:	e406                	sd	ra,8(sp)
    8000048a:	e022                	sd	s0,0(sp)
    8000048c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000048e:	00008597          	auipc	a1,0x8
    80000492:	b8258593          	addi	a1,a1,-1150 # 80008010 <etext+0x10>
    80000496:	00011517          	auipc	a0,0x11
    8000049a:	cda50513          	addi	a0,a0,-806 # 80011170 <cons>
    8000049e:	00001097          	auipc	ra,0x1
    800004a2:	b74080e7          	jalr	-1164(ra) # 80001012 <initlock>

  uartinit();
    800004a6:	00000097          	auipc	ra,0x0
    800004aa:	334080e7          	jalr	820(ra) # 800007da <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    800004ae:	00056797          	auipc	a5,0x56
    800004b2:	f7a78793          	addi	a5,a5,-134 # 80056428 <devsw>
    800004b6:	00000717          	auipc	a4,0x0
    800004ba:	cbe70713          	addi	a4,a4,-834 # 80000174 <consoleread>
    800004be:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004c0:	00000717          	auipc	a4,0x0
    800004c4:	c3270713          	addi	a4,a4,-974 # 800000f2 <consolewrite>
    800004c8:	ef98                	sd	a4,24(a5)
}
    800004ca:	60a2                	ld	ra,8(sp)
    800004cc:	6402                	ld	s0,0(sp)
    800004ce:	0141                	addi	sp,sp,16
    800004d0:	8082                	ret

00000000800004d2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004d2:	7179                	addi	sp,sp,-48
    800004d4:	f406                	sd	ra,40(sp)
    800004d6:	f022                	sd	s0,32(sp)
    800004d8:	ec26                	sd	s1,24(sp)
    800004da:	e84a                	sd	s2,16(sp)
    800004dc:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004de:	c219                	beqz	a2,800004e4 <printint+0x12>
    800004e0:	00054d63          	bltz	a0,800004fa <printint+0x28>
    x = -xx;
  else
    x = xx;
    800004e4:	2501                	sext.w	a0,a0
    800004e6:	4881                	li	a7,0
    800004e8:	fd040713          	addi	a4,s0,-48

  i = 0;
    800004ec:	4601                	li	a2,0
  do {
    buf[i++] = digits[x % base];
    800004ee:	2581                	sext.w	a1,a1
    800004f0:	00008817          	auipc	a6,0x8
    800004f4:	b2880813          	addi	a6,a6,-1240 # 80008018 <digits>
    800004f8:	a801                	j	80000508 <printint+0x36>
    x = -xx;
    800004fa:	40a0053b          	negw	a0,a0
    800004fe:	2501                	sext.w	a0,a0
  if(sign && (sign = xx < 0))
    80000500:	4885                	li	a7,1
    x = -xx;
    80000502:	b7dd                	j	800004e8 <printint+0x16>
  } while((x /= base) != 0);
    80000504:	853e                	mv	a0,a5
    buf[i++] = digits[x % base];
    80000506:	8636                	mv	a2,a3
    80000508:	0016069b          	addiw	a3,a2,1
    8000050c:	02b577bb          	remuw	a5,a0,a1
    80000510:	1782                	slli	a5,a5,0x20
    80000512:	9381                	srli	a5,a5,0x20
    80000514:	97c2                	add	a5,a5,a6
    80000516:	0007c783          	lbu	a5,0(a5)
    8000051a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000051e:	0705                	addi	a4,a4,1
    80000520:	02b557bb          	divuw	a5,a0,a1
    80000524:	feb570e3          	bleu	a1,a0,80000504 <printint+0x32>

  if(sign)
    80000528:	00088b63          	beqz	a7,8000053e <printint+0x6c>
    buf[i++] = '-';
    8000052c:	fe040793          	addi	a5,s0,-32
    80000530:	96be                	add	a3,a3,a5
    80000532:	02d00793          	li	a5,45
    80000536:	fef68823          	sb	a5,-16(a3)
    8000053a:	0026069b          	addiw	a3,a2,2

  while(--i >= 0)
    8000053e:	02d05763          	blez	a3,8000056c <printint+0x9a>
    80000542:	fd040793          	addi	a5,s0,-48
    80000546:	00d784b3          	add	s1,a5,a3
    8000054a:	fff78913          	addi	s2,a5,-1
    8000054e:	9936                	add	s2,s2,a3
    80000550:	36fd                	addiw	a3,a3,-1
    80000552:	1682                	slli	a3,a3,0x20
    80000554:	9281                	srli	a3,a3,0x20
    80000556:	40d90933          	sub	s2,s2,a3
    consputc(buf[i]);
    8000055a:	fff4c503          	lbu	a0,-1(s1)
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	d32080e7          	jalr	-718(ra) # 80000290 <consputc>
  while(--i >= 0)
    80000566:	14fd                	addi	s1,s1,-1
    80000568:	ff2499e3          	bne	s1,s2,8000055a <printint+0x88>
}
    8000056c:	70a2                	ld	ra,40(sp)
    8000056e:	7402                	ld	s0,32(sp)
    80000570:	64e2                	ld	s1,24(sp)
    80000572:	6942                	ld	s2,16(sp)
    80000574:	6145                	addi	sp,sp,48
    80000576:	8082                	ret

0000000080000578 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000578:	1101                	addi	sp,sp,-32
    8000057a:	ec06                	sd	ra,24(sp)
    8000057c:	e822                	sd	s0,16(sp)
    8000057e:	e426                	sd	s1,8(sp)
    80000580:	1000                	addi	s0,sp,32
    80000582:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000584:	00011797          	auipc	a5,0x11
    80000588:	ca07ae23          	sw	zero,-836(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    8000058c:	00008517          	auipc	a0,0x8
    80000590:	aa450513          	addi	a0,a0,-1372 # 80008030 <digits+0x18>
    80000594:	00000097          	auipc	ra,0x0
    80000598:	02e080e7          	jalr	46(ra) # 800005c2 <printf>
  printf(s);
    8000059c:	8526                	mv	a0,s1
    8000059e:	00000097          	auipc	ra,0x0
    800005a2:	024080e7          	jalr	36(ra) # 800005c2 <printf>
  printf("\n");
    800005a6:	00008517          	auipc	a0,0x8
    800005aa:	bc250513          	addi	a0,a0,-1086 # 80008168 <digits+0x150>
    800005ae:	00000097          	auipc	ra,0x0
    800005b2:	014080e7          	jalr	20(ra) # 800005c2 <printf>
  panicked = 1; // freeze uart output from other CPUs
    800005b6:	4785                	li	a5,1
    800005b8:	00009717          	auipc	a4,0x9
    800005bc:	a4f72423          	sw	a5,-1464(a4) # 80009000 <panicked>
  for(;;)
    800005c0:	a001                	j	800005c0 <panic+0x48>

00000000800005c2 <printf>:
{
    800005c2:	7131                	addi	sp,sp,-192
    800005c4:	fc86                	sd	ra,120(sp)
    800005c6:	f8a2                	sd	s0,112(sp)
    800005c8:	f4a6                	sd	s1,104(sp)
    800005ca:	f0ca                	sd	s2,96(sp)
    800005cc:	ecce                	sd	s3,88(sp)
    800005ce:	e8d2                	sd	s4,80(sp)
    800005d0:	e4d6                	sd	s5,72(sp)
    800005d2:	e0da                	sd	s6,64(sp)
    800005d4:	fc5e                	sd	s7,56(sp)
    800005d6:	f862                	sd	s8,48(sp)
    800005d8:	f466                	sd	s9,40(sp)
    800005da:	f06a                	sd	s10,32(sp)
    800005dc:	ec6e                	sd	s11,24(sp)
    800005de:	0100                	addi	s0,sp,128
    800005e0:	8aaa                	mv	s5,a0
    800005e2:	e40c                	sd	a1,8(s0)
    800005e4:	e810                	sd	a2,16(s0)
    800005e6:	ec14                	sd	a3,24(s0)
    800005e8:	f018                	sd	a4,32(s0)
    800005ea:	f41c                	sd	a5,40(s0)
    800005ec:	03043823          	sd	a6,48(s0)
    800005f0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005f4:	00011797          	auipc	a5,0x11
    800005f8:	c2c78793          	addi	a5,a5,-980 # 80011220 <pr>
    800005fc:	0207ad83          	lw	s11,32(a5)
  if(locking)
    80000600:	020d9b63          	bnez	s11,80000636 <printf+0x74>
  if (fmt == 0)
    80000604:	020a8f63          	beqz	s5,80000642 <printf+0x80>
  va_start(ap, fmt);
    80000608:	00840793          	addi	a5,s0,8
    8000060c:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000610:	000ac503          	lbu	a0,0(s5)
    80000614:	16050063          	beqz	a0,80000774 <printf+0x1b2>
    80000618:	4481                	li	s1,0
    if(c != '%'){
    8000061a:	02500a13          	li	s4,37
    switch(c){
    8000061e:	07000b13          	li	s6,112
  consputc('x');
    80000622:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000624:	00008b97          	auipc	s7,0x8
    80000628:	9f4b8b93          	addi	s7,s7,-1548 # 80008018 <digits>
    switch(c){
    8000062c:	07300c93          	li	s9,115
    80000630:	06400c13          	li	s8,100
    80000634:	a815                	j	80000668 <printf+0xa6>
    acquire(&pr.lock);
    80000636:	853e                	mv	a0,a5
    80000638:	00001097          	auipc	ra,0x1
    8000063c:	84e080e7          	jalr	-1970(ra) # 80000e86 <acquire>
    80000640:	b7d1                	j	80000604 <printf+0x42>
    panic("null fmt");
    80000642:	00008517          	auipc	a0,0x8
    80000646:	9fe50513          	addi	a0,a0,-1538 # 80008040 <digits+0x28>
    8000064a:	00000097          	auipc	ra,0x0
    8000064e:	f2e080e7          	jalr	-210(ra) # 80000578 <panic>
      consputc(c);
    80000652:	00000097          	auipc	ra,0x0
    80000656:	c3e080e7          	jalr	-962(ra) # 80000290 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000065a:	2485                	addiw	s1,s1,1
    8000065c:	009a87b3          	add	a5,s5,s1
    80000660:	0007c503          	lbu	a0,0(a5)
    80000664:	10050863          	beqz	a0,80000774 <printf+0x1b2>
    if(c != '%'){
    80000668:	ff4515e3          	bne	a0,s4,80000652 <printf+0x90>
    c = fmt[++i] & 0xff;
    8000066c:	2485                	addiw	s1,s1,1
    8000066e:	009a87b3          	add	a5,s5,s1
    80000672:	0007c783          	lbu	a5,0(a5)
    80000676:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000067a:	0e090d63          	beqz	s2,80000774 <printf+0x1b2>
    switch(c){
    8000067e:	05678a63          	beq	a5,s6,800006d2 <printf+0x110>
    80000682:	02fb7663          	bleu	a5,s6,800006ae <printf+0xec>
    80000686:	09978963          	beq	a5,s9,80000718 <printf+0x156>
    8000068a:	07800713          	li	a4,120
    8000068e:	0ce79863          	bne	a5,a4,8000075e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000692:	f8843783          	ld	a5,-120(s0)
    80000696:	00878713          	addi	a4,a5,8
    8000069a:	f8e43423          	sd	a4,-120(s0)
    8000069e:	4605                	li	a2,1
    800006a0:	85ea                	mv	a1,s10
    800006a2:	4388                	lw	a0,0(a5)
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	e2e080e7          	jalr	-466(ra) # 800004d2 <printint>
      break;
    800006ac:	b77d                	j	8000065a <printf+0x98>
    switch(c){
    800006ae:	0b478263          	beq	a5,s4,80000752 <printf+0x190>
    800006b2:	0b879663          	bne	a5,s8,8000075e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    800006b6:	f8843783          	ld	a5,-120(s0)
    800006ba:	00878713          	addi	a4,a5,8
    800006be:	f8e43423          	sd	a4,-120(s0)
    800006c2:	4605                	li	a2,1
    800006c4:	45a9                	li	a1,10
    800006c6:	4388                	lw	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	e0a080e7          	jalr	-502(ra) # 800004d2 <printint>
      break;
    800006d0:	b769                	j	8000065a <printf+0x98>
      printptr(va_arg(ap, uint64));
    800006d2:	f8843783          	ld	a5,-120(s0)
    800006d6:	00878713          	addi	a4,a5,8
    800006da:	f8e43423          	sd	a4,-120(s0)
    800006de:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006e2:	03000513          	li	a0,48
    800006e6:	00000097          	auipc	ra,0x0
    800006ea:	baa080e7          	jalr	-1110(ra) # 80000290 <consputc>
  consputc('x');
    800006ee:	07800513          	li	a0,120
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b9e080e7          	jalr	-1122(ra) # 80000290 <consputc>
    800006fa:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006fc:	03c9d793          	srli	a5,s3,0x3c
    80000700:	97de                	add	a5,a5,s7
    80000702:	0007c503          	lbu	a0,0(a5)
    80000706:	00000097          	auipc	ra,0x0
    8000070a:	b8a080e7          	jalr	-1142(ra) # 80000290 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000070e:	0992                	slli	s3,s3,0x4
    80000710:	397d                	addiw	s2,s2,-1
    80000712:	fe0915e3          	bnez	s2,800006fc <printf+0x13a>
    80000716:	b791                	j	8000065a <printf+0x98>
      if((s = va_arg(ap, char*)) == 0)
    80000718:	f8843783          	ld	a5,-120(s0)
    8000071c:	00878713          	addi	a4,a5,8
    80000720:	f8e43423          	sd	a4,-120(s0)
    80000724:	0007b903          	ld	s2,0(a5)
    80000728:	00090e63          	beqz	s2,80000744 <printf+0x182>
      for(; *s; s++)
    8000072c:	00094503          	lbu	a0,0(s2)
    80000730:	d50d                	beqz	a0,8000065a <printf+0x98>
        consputc(*s);
    80000732:	00000097          	auipc	ra,0x0
    80000736:	b5e080e7          	jalr	-1186(ra) # 80000290 <consputc>
      for(; *s; s++)
    8000073a:	0905                	addi	s2,s2,1
    8000073c:	00094503          	lbu	a0,0(s2)
    80000740:	f96d                	bnez	a0,80000732 <printf+0x170>
    80000742:	bf21                	j	8000065a <printf+0x98>
        s = "(null)";
    80000744:	00008917          	auipc	s2,0x8
    80000748:	8f490913          	addi	s2,s2,-1804 # 80008038 <digits+0x20>
      for(; *s; s++)
    8000074c:	02800513          	li	a0,40
    80000750:	b7cd                	j	80000732 <printf+0x170>
      consputc('%');
    80000752:	8552                	mv	a0,s4
    80000754:	00000097          	auipc	ra,0x0
    80000758:	b3c080e7          	jalr	-1220(ra) # 80000290 <consputc>
      break;
    8000075c:	bdfd                	j	8000065a <printf+0x98>
      consputc('%');
    8000075e:	8552                	mv	a0,s4
    80000760:	00000097          	auipc	ra,0x0
    80000764:	b30080e7          	jalr	-1232(ra) # 80000290 <consputc>
      consputc(c);
    80000768:	854a                	mv	a0,s2
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	b26080e7          	jalr	-1242(ra) # 80000290 <consputc>
      break;
    80000772:	b5e5                	j	8000065a <printf+0x98>
  if(locking)
    80000774:	020d9163          	bnez	s11,80000796 <printf+0x1d4>
}
    80000778:	70e6                	ld	ra,120(sp)
    8000077a:	7446                	ld	s0,112(sp)
    8000077c:	74a6                	ld	s1,104(sp)
    8000077e:	7906                	ld	s2,96(sp)
    80000780:	69e6                	ld	s3,88(sp)
    80000782:	6a46                	ld	s4,80(sp)
    80000784:	6aa6                	ld	s5,72(sp)
    80000786:	6b06                	ld	s6,64(sp)
    80000788:	7be2                	ld	s7,56(sp)
    8000078a:	7c42                	ld	s8,48(sp)
    8000078c:	7ca2                	ld	s9,40(sp)
    8000078e:	7d02                	ld	s10,32(sp)
    80000790:	6de2                	ld	s11,24(sp)
    80000792:	6129                	addi	sp,sp,192
    80000794:	8082                	ret
    release(&pr.lock);
    80000796:	00011517          	auipc	a0,0x11
    8000079a:	a8a50513          	addi	a0,a0,-1398 # 80011220 <pr>
    8000079e:	00000097          	auipc	ra,0x0
    800007a2:	7b8080e7          	jalr	1976(ra) # 80000f56 <release>
}
    800007a6:	bfc9                	j	80000778 <printf+0x1b6>

00000000800007a8 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007a8:	1101                	addi	sp,sp,-32
    800007aa:	ec06                	sd	ra,24(sp)
    800007ac:	e822                	sd	s0,16(sp)
    800007ae:	e426                	sd	s1,8(sp)
    800007b0:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007b2:	00011497          	auipc	s1,0x11
    800007b6:	a6e48493          	addi	s1,s1,-1426 # 80011220 <pr>
    800007ba:	00008597          	auipc	a1,0x8
    800007be:	89658593          	addi	a1,a1,-1898 # 80008050 <digits+0x38>
    800007c2:	8526                	mv	a0,s1
    800007c4:	00001097          	auipc	ra,0x1
    800007c8:	84e080e7          	jalr	-1970(ra) # 80001012 <initlock>
  pr.locking = 1;
    800007cc:	4785                	li	a5,1
    800007ce:	d09c                	sw	a5,32(s1)
}
    800007d0:	60e2                	ld	ra,24(sp)
    800007d2:	6442                	ld	s0,16(sp)
    800007d4:	64a2                	ld	s1,8(sp)
    800007d6:	6105                	addi	sp,sp,32
    800007d8:	8082                	ret

00000000800007da <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007da:	1141                	addi	sp,sp,-16
    800007dc:	e406                	sd	ra,8(sp)
    800007de:	e022                	sd	s0,0(sp)
    800007e0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007e2:	100007b7          	lui	a5,0x10000
    800007e6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ea:	f8000713          	li	a4,-128
    800007ee:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007f2:	470d                	li	a4,3
    800007f4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007f8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007fc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000800:	469d                	li	a3,7
    80000802:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000806:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000080a:	00008597          	auipc	a1,0x8
    8000080e:	84e58593          	addi	a1,a1,-1970 # 80008058 <digits+0x40>
    80000812:	00011517          	auipc	a0,0x11
    80000816:	a3650513          	addi	a0,a0,-1482 # 80011248 <uart_tx_lock>
    8000081a:	00000097          	auipc	ra,0x0
    8000081e:	7f8080e7          	jalr	2040(ra) # 80001012 <initlock>
}
    80000822:	60a2                	ld	ra,8(sp)
    80000824:	6402                	ld	s0,0(sp)
    80000826:	0141                	addi	sp,sp,16
    80000828:	8082                	ret

000000008000082a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000082a:	1101                	addi	sp,sp,-32
    8000082c:	ec06                	sd	ra,24(sp)
    8000082e:	e822                	sd	s0,16(sp)
    80000830:	e426                	sd	s1,8(sp)
    80000832:	1000                	addi	s0,sp,32
    80000834:	84aa                	mv	s1,a0
  push_off();
    80000836:	00000097          	auipc	ra,0x0
    8000083a:	604080e7          	jalr	1540(ra) # 80000e3a <push_off>

  if(panicked){
    8000083e:	00008797          	auipc	a5,0x8
    80000842:	7c278793          	addi	a5,a5,1986 # 80009000 <panicked>
    80000846:	439c                	lw	a5,0(a5)
    80000848:	2781                	sext.w	a5,a5
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000084a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000084e:	c391                	beqz	a5,80000852 <uartputc_sync+0x28>
    for(;;)
    80000850:	a001                	j	80000850 <uartputc_sync+0x26>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000852:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000856:	0ff7f793          	andi	a5,a5,255
    8000085a:	0207f793          	andi	a5,a5,32
    8000085e:	dbf5                	beqz	a5,80000852 <uartputc_sync+0x28>
    ;
  WriteReg(THR, c);
    80000860:	0ff4f793          	andi	a5,s1,255
    80000864:	10000737          	lui	a4,0x10000
    80000868:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000086c:	00000097          	auipc	ra,0x0
    80000870:	68a080e7          	jalr	1674(ra) # 80000ef6 <pop_off>
}
    80000874:	60e2                	ld	ra,24(sp)
    80000876:	6442                	ld	s0,16(sp)
    80000878:	64a2                	ld	s1,8(sp)
    8000087a:	6105                	addi	sp,sp,32
    8000087c:	8082                	ret

000000008000087e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000087e:	00008797          	auipc	a5,0x8
    80000882:	78678793          	addi	a5,a5,1926 # 80009004 <uart_tx_r>
    80000886:	439c                	lw	a5,0(a5)
    80000888:	00008717          	auipc	a4,0x8
    8000088c:	78070713          	addi	a4,a4,1920 # 80009008 <uart_tx_w>
    80000890:	4318                	lw	a4,0(a4)
    80000892:	08f70b63          	beq	a4,a5,80000928 <uartstart+0xaa>
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000896:	10000737          	lui	a4,0x10000
    8000089a:	00574703          	lbu	a4,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000089e:	0ff77713          	andi	a4,a4,255
    800008a2:	02077713          	andi	a4,a4,32
    800008a6:	c349                	beqz	a4,80000928 <uartstart+0xaa>
{
    800008a8:	7139                	addi	sp,sp,-64
    800008aa:	fc06                	sd	ra,56(sp)
    800008ac:	f822                	sd	s0,48(sp)
    800008ae:	f426                	sd	s1,40(sp)
    800008b0:	f04a                	sd	s2,32(sp)
    800008b2:	ec4e                	sd	s3,24(sp)
    800008b4:	e852                	sd	s4,16(sp)
    800008b6:	e456                	sd	s5,8(sp)
    800008b8:	0080                	addi	s0,sp,64
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008ba:	00011a17          	auipc	s4,0x11
    800008be:	98ea0a13          	addi	s4,s4,-1650 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008c2:	00008497          	auipc	s1,0x8
    800008c6:	74248493          	addi	s1,s1,1858 # 80009004 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008ca:	10000937          	lui	s2,0x10000
    if(uart_tx_w == uart_tx_r){
    800008ce:	00008997          	auipc	s3,0x8
    800008d2:	73a98993          	addi	s3,s3,1850 # 80009008 <uart_tx_w>
    int c = uart_tx_buf[uart_tx_r];
    800008d6:	00fa0733          	add	a4,s4,a5
    800008da:	02074a83          	lbu	s5,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008de:	2785                	addiw	a5,a5,1
    800008e0:	41f7d71b          	sraiw	a4,a5,0x1f
    800008e4:	01b7571b          	srliw	a4,a4,0x1b
    800008e8:	9fb9                	addw	a5,a5,a4
    800008ea:	8bfd                	andi	a5,a5,31
    800008ec:	9f99                	subw	a5,a5,a4
    800008ee:	c09c                	sw	a5,0(s1)
    wakeup(&uart_tx_r);
    800008f0:	8526                	mv	a0,s1
    800008f2:	00002097          	auipc	ra,0x2
    800008f6:	fe4080e7          	jalr	-28(ra) # 800028d6 <wakeup>
    WriteReg(THR, c);
    800008fa:	01590023          	sb	s5,0(s2) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008fe:	409c                	lw	a5,0(s1)
    80000900:	0009a703          	lw	a4,0(s3)
    80000904:	00f70963          	beq	a4,a5,80000916 <uartstart+0x98>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000908:	00594703          	lbu	a4,5(s2)
    8000090c:	0ff77713          	andi	a4,a4,255
    80000910:	02077713          	andi	a4,a4,32
    80000914:	f369                	bnez	a4,800008d6 <uartstart+0x58>
  }
}
    80000916:	70e2                	ld	ra,56(sp)
    80000918:	7442                	ld	s0,48(sp)
    8000091a:	74a2                	ld	s1,40(sp)
    8000091c:	7902                	ld	s2,32(sp)
    8000091e:	69e2                	ld	s3,24(sp)
    80000920:	6a42                	ld	s4,16(sp)
    80000922:	6aa2                	ld	s5,8(sp)
    80000924:	6121                	addi	sp,sp,64
    80000926:	8082                	ret
    80000928:	8082                	ret

000000008000092a <uartputc>:
{
    8000092a:	7179                	addi	sp,sp,-48
    8000092c:	f406                	sd	ra,40(sp)
    8000092e:	f022                	sd	s0,32(sp)
    80000930:	ec26                	sd	s1,24(sp)
    80000932:	e84a                	sd	s2,16(sp)
    80000934:	e44e                	sd	s3,8(sp)
    80000936:	e052                	sd	s4,0(sp)
    80000938:	1800                	addi	s0,sp,48
    8000093a:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    8000093c:	00011517          	auipc	a0,0x11
    80000940:	90c50513          	addi	a0,a0,-1780 # 80011248 <uart_tx_lock>
    80000944:	00000097          	auipc	ra,0x0
    80000948:	542080e7          	jalr	1346(ra) # 80000e86 <acquire>
  if(panicked){
    8000094c:	00008797          	auipc	a5,0x8
    80000950:	6b478793          	addi	a5,a5,1716 # 80009000 <panicked>
    80000954:	439c                	lw	a5,0(a5)
    80000956:	2781                	sext.w	a5,a5
    80000958:	c391                	beqz	a5,8000095c <uartputc+0x32>
    for(;;)
    8000095a:	a001                	j	8000095a <uartputc+0x30>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000095c:	00008797          	auipc	a5,0x8
    80000960:	6ac78793          	addi	a5,a5,1708 # 80009008 <uart_tx_w>
    80000964:	4398                	lw	a4,0(a5)
    80000966:	0017079b          	addiw	a5,a4,1
    8000096a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096e:	01b6d69b          	srliw	a3,a3,0x1b
    80000972:	9fb5                	addw	a5,a5,a3
    80000974:	8bfd                	andi	a5,a5,31
    80000976:	9f95                	subw	a5,a5,a3
    80000978:	00008697          	auipc	a3,0x8
    8000097c:	68c68693          	addi	a3,a3,1676 # 80009004 <uart_tx_r>
    80000980:	4294                	lw	a3,0(a3)
    80000982:	04f69263          	bne	a3,a5,800009c6 <uartputc+0x9c>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000986:	00011a17          	auipc	s4,0x11
    8000098a:	8c2a0a13          	addi	s4,s4,-1854 # 80011248 <uart_tx_lock>
    8000098e:	00008497          	auipc	s1,0x8
    80000992:	67648493          	addi	s1,s1,1654 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000996:	00008917          	auipc	s2,0x8
    8000099a:	67290913          	addi	s2,s2,1650 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000099e:	85d2                	mv	a1,s4
    800009a0:	8526                	mv	a0,s1
    800009a2:	00002097          	auipc	ra,0x2
    800009a6:	dae080e7          	jalr	-594(ra) # 80002750 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009aa:	00092703          	lw	a4,0(s2)
    800009ae:	0017079b          	addiw	a5,a4,1
    800009b2:	41f7d69b          	sraiw	a3,a5,0x1f
    800009b6:	01b6d69b          	srliw	a3,a3,0x1b
    800009ba:	9fb5                	addw	a5,a5,a3
    800009bc:	8bfd                	andi	a5,a5,31
    800009be:	9f95                	subw	a5,a5,a3
    800009c0:	4094                	lw	a3,0(s1)
    800009c2:	fcf68ee3          	beq	a3,a5,8000099e <uartputc+0x74>
      uart_tx_buf[uart_tx_w] = c;
    800009c6:	00011497          	auipc	s1,0x11
    800009ca:	88248493          	addi	s1,s1,-1918 # 80011248 <uart_tx_lock>
    800009ce:	9726                	add	a4,a4,s1
    800009d0:	03370023          	sb	s3,32(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009d4:	00008717          	auipc	a4,0x8
    800009d8:	62f72a23          	sw	a5,1588(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	ea2080e7          	jalr	-350(ra) # 8000087e <uartstart>
      release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	570080e7          	jalr	1392(ra) # 80000f56 <release>
}
    800009ee:	70a2                	ld	ra,40(sp)
    800009f0:	7402                	ld	s0,32(sp)
    800009f2:	64e2                	ld	s1,24(sp)
    800009f4:	6942                	ld	s2,16(sp)
    800009f6:	69a2                	ld	s3,8(sp)
    800009f8:	6a02                	ld	s4,0(sp)
    800009fa:	6145                	addi	sp,sp,48
    800009fc:	8082                	ret

00000000800009fe <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009fe:	1141                	addi	sp,sp,-16
    80000a00:	e422                	sd	s0,8(sp)
    80000a02:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a04:	100007b7          	lui	a5,0x10000
    80000a08:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a0c:	8b85                	andi	a5,a5,1
    80000a0e:	cb91                	beqz	a5,80000a22 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a10:	100007b7          	lui	a5,0x10000
    80000a14:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a18:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a1c:	6422                	ld	s0,8(sp)
    80000a1e:	0141                	addi	sp,sp,16
    80000a20:	8082                	ret
    return -1;
    80000a22:	557d                	li	a0,-1
    80000a24:	bfe5                	j	80000a1c <uartgetc+0x1e>

0000000080000a26 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a26:	1101                	addi	sp,sp,-32
    80000a28:	ec06                	sd	ra,24(sp)
    80000a2a:	e822                	sd	s0,16(sp)
    80000a2c:	e426                	sd	s1,8(sp)
    80000a2e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a30:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a32:	00000097          	auipc	ra,0x0
    80000a36:	fcc080e7          	jalr	-52(ra) # 800009fe <uartgetc>
    if(c == -1)
    80000a3a:	00950763          	beq	a0,s1,80000a48 <uartintr+0x22>
      break;
    consoleintr(c);
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	894080e7          	jalr	-1900(ra) # 800002d2 <consoleintr>
  while(1){
    80000a46:	b7f5                	j	80000a32 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a48:	00011497          	auipc	s1,0x11
    80000a4c:	80048493          	addi	s1,s1,-2048 # 80011248 <uart_tx_lock>
    80000a50:	8526                	mv	a0,s1
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	434080e7          	jalr	1076(ra) # 80000e86 <acquire>
  uartstart();
    80000a5a:	00000097          	auipc	ra,0x0
    80000a5e:	e24080e7          	jalr	-476(ra) # 8000087e <uartstart>
  release(&uart_tx_lock);
    80000a62:	8526                	mv	a0,s1
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	4f2080e7          	jalr	1266(ra) # 80000f56 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret

0000000080000a76 <initcpulocks>:
char name[NCPU][10];


void
initcpulocks()
{
    80000a76:	7139                	addi	sp,sp,-64
    80000a78:	fc06                	sd	ra,56(sp)
    80000a7a:	f822                	sd	s0,48(sp)
    80000a7c:	f426                	sd	s1,40(sp)
    80000a7e:	f04a                	sd	s2,32(sp)
    80000a80:	ec4e                	sd	s3,24(sp)
    80000a82:	e852                	sd	s4,16(sp)
    80000a84:	e456                	sd	s5,8(sp)
    80000a86:	0080                	addi	s0,sp,64
  for (int i = 0; i < NCPU; i++) {
    80000a88:	00011997          	auipc	s3,0x11
    80000a8c:	80098993          	addi	s3,s3,-2048 # 80011288 <name>
    80000a90:	00011917          	auipc	s2,0x11
    80000a94:	84890913          	addi	s2,s2,-1976 # 800112d8 <cpukmems>
    80000a98:	4481                	li	s1,0
    // 每个CPU锁的名字为kmem + CPUID
    snprintf(name[i], 10, "kmem%d", i);
    80000a9a:	00007a97          	auipc	s5,0x7
    80000a9e:	5c6a8a93          	addi	s5,s5,1478 # 80008060 <digits+0x48>
  for (int i = 0; i < NCPU; i++) {
    80000aa2:	4a21                	li	s4,8
    snprintf(name[i], 10, "kmem%d", i);
    80000aa4:	86a6                	mv	a3,s1
    80000aa6:	8656                	mv	a2,s5
    80000aa8:	45a9                	li	a1,10
    80000aaa:	854e                	mv	a0,s3
    80000aac:	00006097          	auipc	ra,0x6
    80000ab0:	098080e7          	jalr	152(ra) # 80006b44 <snprintf>
    struct kmem* curr = &cpukmems[i];
    initlock(&curr->lock, name[i]);
    80000ab4:	85ce                	mv	a1,s3
    80000ab6:	854a                	mv	a0,s2
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	55a080e7          	jalr	1370(ra) # 80001012 <initlock>
    curr->freelist = 0;
    80000ac0:	02093023          	sd	zero,32(s2)
  for (int i = 0; i < NCPU; i++) {
    80000ac4:	2485                	addiw	s1,s1,1
    80000ac6:	09a9                	addi	s3,s3,10
    80000ac8:	02890913          	addi	s2,s2,40
    80000acc:	fd449ce3          	bne	s1,s4,80000aa4 <initcpulocks+0x2e>
  }
}
    80000ad0:	70e2                	ld	ra,56(sp)
    80000ad2:	7442                	ld	s0,48(sp)
    80000ad4:	74a2                	ld	s1,40(sp)
    80000ad6:	7902                	ld	s2,32(sp)
    80000ad8:	69e2                	ld	s3,24(sp)
    80000ada:	6a42                	ld	s4,16(sp)
    80000adc:	6aa2                	ld	s5,8(sp)
    80000ade:	6121                	addi	sp,sp,64
    80000ae0:	8082                	ret

0000000080000ae2 <kfreeforcpu>:
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
// 释放特定CPU上的物理内存
void
kfreeforcpu(void *pa, int id)
{
    80000ae2:	7139                	addi	sp,sp,-64
    80000ae4:	fc06                	sd	ra,56(sp)
    80000ae6:	f822                	sd	s0,48(sp)
    80000ae8:	f426                	sd	s1,40(sp)
    80000aea:	f04a                	sd	s2,32(sp)
    80000aec:	ec4e                	sd	s3,24(sp)
    80000aee:	e852                	sd	s4,16(sp)
    80000af0:	e456                	sd	s5,8(sp)
    80000af2:	0080                	addi	s0,sp,64
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000af4:	6785                	lui	a5,0x1
    80000af6:	17fd                	addi	a5,a5,-1
    80000af8:	8fe9                	and	a5,a5,a0
    80000afa:	e3c9                	bnez	a5,80000b7c <kfreeforcpu+0x9a>
    80000afc:	892a                	mv	s2,a0
    80000afe:	89ae                	mv	s3,a1
    80000b00:	0005b797          	auipc	a5,0x5b
    80000b04:	52878793          	addi	a5,a5,1320 # 8005c028 <end>
    80000b08:	06f56a63          	bltu	a0,a5,80000b7c <kfreeforcpu+0x9a>
    80000b0c:	47c5                	li	a5,17
    80000b0e:	07ee                	slli	a5,a5,0x1b
    80000b10:	06f57663          	bleu	a5,a0,80000b7c <kfreeforcpu+0x9a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4585                	li	a1,1
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	77a080e7          	jalr	1914(ra) # 80001292 <memset>

  r = (struct run*)pa;

  struct kmem* curr = &cpukmems[id];

  acquire(&curr->lock);
    80000b20:	00010a97          	auipc	s5,0x10
    80000b24:	768a8a93          	addi	s5,s5,1896 # 80011288 <name>
    80000b28:	00299493          	slli	s1,s3,0x2
    80000b2c:	01348a33          	add	s4,s1,s3
    80000b30:	003a1793          	slli	a5,s4,0x3
    80000b34:	00010a17          	auipc	s4,0x10
    80000b38:	7a4a0a13          	addi	s4,s4,1956 # 800112d8 <cpukmems>
    80000b3c:	9a3e                	add	s4,s4,a5
    80000b3e:	8552                	mv	a0,s4
    80000b40:	00000097          	auipc	ra,0x0
    80000b44:	346080e7          	jalr	838(ra) # 80000e86 <acquire>
  r->next = curr->freelist;
    80000b48:	013487b3          	add	a5,s1,s3
    80000b4c:	078e                	slli	a5,a5,0x3
    80000b4e:	97d6                	add	a5,a5,s5
    80000b50:	7bbc                	ld	a5,112(a5)
    80000b52:	00f93023          	sd	a5,0(s2)
  curr->freelist = r;
    80000b56:	94ce                	add	s1,s1,s3
    80000b58:	048e                	slli	s1,s1,0x3
    80000b5a:	94d6                	add	s1,s1,s5
    80000b5c:	0724b823          	sd	s2,112(s1)
  release(&curr->lock);
    80000b60:	8552                	mv	a0,s4
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	3f4080e7          	jalr	1012(ra) # 80000f56 <release>
}
    80000b6a:	70e2                	ld	ra,56(sp)
    80000b6c:	7442                	ld	s0,48(sp)
    80000b6e:	74a2                	ld	s1,40(sp)
    80000b70:	7902                	ld	s2,32(sp)
    80000b72:	69e2                	ld	s3,24(sp)
    80000b74:	6a42                	ld	s4,16(sp)
    80000b76:	6aa2                	ld	s5,8(sp)
    80000b78:	6121                	addi	sp,sp,64
    80000b7a:	8082                	ret
    panic("kfree");
    80000b7c:	00007517          	auipc	a0,0x7
    80000b80:	4ec50513          	addi	a0,a0,1260 # 80008068 <digits+0x50>
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	9f4080e7          	jalr	-1548(ra) # 80000578 <panic>

0000000080000b8c <kinitforcpu>:
 * 即假设物理内存一共有100页，CPU个数为4，则每个CPU
 * 初始的物理内存个数为25。若一共102页，则最后一个CPU分配
 * 25 + 2 = 27页
 */
void
kinitforcpu(void *pa_start, void *pa_end) {
    80000b8c:	7159                	addi	sp,sp,-112
    80000b8e:	f486                	sd	ra,104(sp)
    80000b90:	f0a2                	sd	s0,96(sp)
    80000b92:	eca6                	sd	s1,88(sp)
    80000b94:	e8ca                	sd	s2,80(sp)
    80000b96:	e4ce                	sd	s3,72(sp)
    80000b98:	e0d2                	sd	s4,64(sp)
    80000b9a:	fc56                	sd	s5,56(sp)
    80000b9c:	f85a                	sd	s6,48(sp)
    80000b9e:	f45e                	sd	s7,40(sp)
    80000ba0:	f062                	sd	s8,32(sp)
    80000ba2:	ec66                	sd	s9,24(sp)
    80000ba4:	e86a                	sd	s10,16(sp)
    80000ba6:	e46e                	sd	s11,8(sp)
    80000ba8:	1880                	addi	s0,sp,112
  pa_start = (void*)PGROUNDUP((uint64)pa_start);
    80000baa:	6785                	lui	a5,0x1
    80000bac:	17fd                	addi	a5,a5,-1
    80000bae:	953e                	add	a0,a0,a5
    80000bb0:	7bfd                	lui	s7,0xfffff
    80000bb2:	017574b3          	and	s1,a0,s7
  pa_end = (void*)PGROUNDDOWN((uint64)pa_end);
    80000bb6:	0175fbb3          	and	s7,a1,s7
    80000bba:	8c5e                	mv	s8,s7
  int cnt = (pa_end - pa_start) / PGSIZE; // 物理页总个数
    80000bbc:	409b8733          	sub	a4,s7,s1
    80000bc0:	43f75b13          	srai	s6,a4,0x3f
    80000bc4:	00fb7b33          	and	s6,s6,a5
    80000bc8:	9b3a                	add	s6,s6,a4
    80000bca:	40cb5b13          	srai	s6,s6,0xc
    80000bce:	2b01                	sext.w	s6,s6
  int length = cnt / NCPU; // 每个CPU物理页的个数
    80000bd0:	41fb5a1b          	sraiw	s4,s6,0x1f
    80000bd4:	01da5a1b          	srliw	s4,s4,0x1d
    80000bd8:	016a0a3b          	addw	s4,s4,s6
    80000bdc:	403a5a1b          	sraiw	s4,s4,0x3

  void* p = pa_start;
  for (int i = 0; i < NCPU; i++) {
    80000be0:	4981                	li	s3,0
    for (int j = 0; j < length; j++) {
    80000be2:	4d9d                	li	s11,7
    80000be4:	4d01                	li	s10,0
      kfreeforcpu(p, i);  // 为该CPU分配内存
      p += PGSIZE;
    80000be6:	6a85                	lui	s5,0x1
  for (int i = 0; i < NCPU; i++) {
    80000be8:	4ca1                	li	s9,8
    for (int j = 0; j < length; j++) {
    80000bea:	896a                	mv	s2,s10
    80000bec:	016ddc63          	ble	s6,s11,80000c04 <kinitforcpu+0x78>
      kfreeforcpu(p, i);  // 为该CPU分配内存
    80000bf0:	85ce                	mv	a1,s3
    80000bf2:	8526                	mv	a0,s1
    80000bf4:	00000097          	auipc	ra,0x0
    80000bf8:	eee080e7          	jalr	-274(ra) # 80000ae2 <kfreeforcpu>
      p += PGSIZE;
    80000bfc:	94d6                	add	s1,s1,s5
    for (int j = 0; j < length; j++) {
    80000bfe:	2905                	addiw	s2,s2,1
    80000c00:	ff4948e3          	blt	s2,s4,80000bf0 <kinitforcpu+0x64>
  for (int i = 0; i < NCPU; i++) {
    80000c04:	2985                	addiw	s3,s3,1
    80000c06:	ff9992e3          	bne	s3,s9,80000bea <kinitforcpu+0x5e>
    }
  }

  // 将剩余的物理页分配为最后一个CPU
  while (p + PGSIZE <= pa_end) {
    80000c0a:	6785                	lui	a5,0x1
    80000c0c:	97a6                	add	a5,a5,s1
    80000c0e:	02fc6563          	bltu	s8,a5,80000c38 <kinitforcpu+0xac>
    80000c12:	8926                	mv	s2,s1
    80000c14:	777d                	lui	a4,0xfffff
    80000c16:	00eb87b3          	add	a5,s7,a4
    80000c1a:	8f85                	sub	a5,a5,s1
    80000c1c:	8ff9                	and	a5,a5,a4
    80000c1e:	6705                	lui	a4,0x1
    80000c20:	94ba                	add	s1,s1,a4
    80000c22:	94be                	add	s1,s1,a5
    80000c24:	6985                	lui	s3,0x1
    kfreeforcpu(p, NCPU - 1);
    80000c26:	459d                	li	a1,7
    80000c28:	854a                	mv	a0,s2
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	eb8080e7          	jalr	-328(ra) # 80000ae2 <kfreeforcpu>
  while (p + PGSIZE <= pa_end) {
    80000c32:	994e                	add	s2,s2,s3
    80000c34:	ff2499e3          	bne	s1,s2,80000c26 <kinitforcpu+0x9a>
    p += PGSIZE;
  }

}
    80000c38:	70a6                	ld	ra,104(sp)
    80000c3a:	7406                	ld	s0,96(sp)
    80000c3c:	64e6                	ld	s1,88(sp)
    80000c3e:	6946                	ld	s2,80(sp)
    80000c40:	69a6                	ld	s3,72(sp)
    80000c42:	6a06                	ld	s4,64(sp)
    80000c44:	7ae2                	ld	s5,56(sp)
    80000c46:	7b42                	ld	s6,48(sp)
    80000c48:	7ba2                	ld	s7,40(sp)
    80000c4a:	7c02                	ld	s8,32(sp)
    80000c4c:	6ce2                	ld	s9,24(sp)
    80000c4e:	6d42                	ld	s10,16(sp)
    80000c50:	6da2                	ld	s11,8(sp)
    80000c52:	6165                	addi	sp,sp,112
    80000c54:	8082                	ret

0000000080000c56 <kinit>:

void
kinit()
{
    80000c56:	1141                	addi	sp,sp,-16
    80000c58:	e406                	sd	ra,8(sp)
    80000c5a:	e022                	sd	s0,0(sp)
    80000c5c:	0800                	addi	s0,sp,16
  initcpulocks();
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	e18080e7          	jalr	-488(ra) # 80000a76 <initcpulocks>
  kinitforcpu(end, (void*)PHYSTOP);
    80000c66:	45c5                	li	a1,17
    80000c68:	05ee                	slli	a1,a1,0x1b
    80000c6a:	0005b517          	auipc	a0,0x5b
    80000c6e:	3be50513          	addi	a0,a0,958 # 8005c028 <end>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	f1a080e7          	jalr	-230(ra) # 80000b8c <kinitforcpu>
}
    80000c7a:	60a2                	ld	ra,8(sp)
    80000c7c:	6402                	ld	s0,0(sp)
    80000c7e:	0141                	addi	sp,sp,16
    80000c80:	8082                	ret

0000000080000c82 <kfree>:

void
kfree(void* pa)
{
    80000c82:	1101                	addi	sp,sp,-32
    80000c84:	ec06                	sd	ra,24(sp)
    80000c86:	e822                	sd	s0,16(sp)
    80000c88:	e426                	sd	s1,8(sp)
    80000c8a:	e04a                	sd	s2,0(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  push_off();
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	1aa080e7          	jalr	426(ra) # 80000e3a <push_off>
  int id = cpuid();
    80000c98:	00001097          	auipc	ra,0x1
    80000c9c:	272080e7          	jalr	626(ra) # 80001f0a <cpuid>
    80000ca0:	892a                	mv	s2,a0
  pop_off();
    80000ca2:	00000097          	auipc	ra,0x0
    80000ca6:	254080e7          	jalr	596(ra) # 80000ef6 <pop_off>
  kfreeforcpu(pa, id);
    80000caa:	85ca                	mv	a1,s2
    80000cac:	8526                	mv	a0,s1
    80000cae:	00000097          	auipc	ra,0x0
    80000cb2:	e34080e7          	jalr	-460(ra) # 80000ae2 <kfreeforcpu>
}
    80000cb6:	60e2                	ld	ra,24(sp)
    80000cb8:	6442                	ld	s0,16(sp)
    80000cba:	64a2                	ld	s1,8(sp)
    80000cbc:	6902                	ld	s2,0(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret

0000000080000cc2 <stealing>:

// 从剩余的CPU中偷一页内存
void*
stealing(int id)
{
    80000cc2:	7139                	addi	sp,sp,-64
    80000cc4:	fc06                	sd	ra,56(sp)
    80000cc6:	f822                	sd	s0,48(sp)
    80000cc8:	f426                	sd	s1,40(sp)
    80000cca:	f04a                	sd	s2,32(sp)
    80000ccc:	ec4e                	sd	s3,24(sp)
    80000cce:	e852                	sd	s4,16(sp)
    80000cd0:	e456                	sd	s5,8(sp)
    80000cd2:	e05a                	sd	s6,0(sp)
    80000cd4:	0080                	addi	s0,sp,64
    80000cd6:	8a2a                	mv	s4,a0
  struct run *r;
  for (int i = 0; i < NCPU; i++) {
    80000cd8:	00010917          	auipc	s2,0x10
    80000cdc:	60090913          	addi	s2,s2,1536 # 800112d8 <cpukmems>
    80000ce0:	4481                	li	s1,0
    80000ce2:	4aa1                	li	s5,8
    80000ce4:	a829                	j	80000cfe <stealing+0x3c>
    if (r) {
      memset((char *) r, 5, PGSIZE);
      return (void*)r;
    }
  }
  return 0;
    80000ce6:	4981                	li	s3,0
    80000ce8:	a8b1                	j	80000d44 <stealing+0x82>
    release(&curr->lock);
    80000cea:	854a                	mv	a0,s2
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	26a080e7          	jalr	618(ra) # 80000f56 <release>
  for (int i = 0; i < NCPU; i++) {
    80000cf4:	2485                	addiw	s1,s1,1
    80000cf6:	02890913          	addi	s2,s2,40
    80000cfa:	ff5486e3          	beq	s1,s5,80000ce6 <stealing+0x24>
    if (i == id) { // 如果是当前CPU，则跳过，因为当前CPU已经无内存
    80000cfe:	fe9a0be3          	beq	s4,s1,80000cf4 <stealing+0x32>
    acquire(&curr->lock);
    80000d02:	854a                	mv	a0,s2
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	182080e7          	jalr	386(ra) # 80000e86 <acquire>
    r = curr->freelist;
    80000d0c:	02093983          	ld	s3,32(s2)
    if (r)
    80000d10:	fc098de3          	beqz	s3,80000cea <stealing+0x28>
      curr->freelist = r->next;
    80000d14:	0009b703          	ld	a4,0(s3) # 1000 <_entry-0x7ffff000>
    80000d18:	00249793          	slli	a5,s1,0x2
    80000d1c:	94be                	add	s1,s1,a5
    80000d1e:	048e                	slli	s1,s1,0x3
    80000d20:	00010797          	auipc	a5,0x10
    80000d24:	56878793          	addi	a5,a5,1384 # 80011288 <name>
    80000d28:	94be                	add	s1,s1,a5
    80000d2a:	f8b8                	sd	a4,112(s1)
    release(&curr->lock);
    80000d2c:	854a                	mv	a0,s2
    80000d2e:	00000097          	auipc	ra,0x0
    80000d32:	228080e7          	jalr	552(ra) # 80000f56 <release>
      memset((char *) r, 5, PGSIZE);
    80000d36:	6605                	lui	a2,0x1
    80000d38:	4595                	li	a1,5
    80000d3a:	854e                	mv	a0,s3
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	556080e7          	jalr	1366(ra) # 80001292 <memset>
}
    80000d44:	854e                	mv	a0,s3
    80000d46:	70e2                	ld	ra,56(sp)
    80000d48:	7442                	ld	s0,48(sp)
    80000d4a:	74a2                	ld	s1,40(sp)
    80000d4c:	7902                	ld	s2,32(sp)
    80000d4e:	69e2                	ld	s3,24(sp)
    80000d50:	6a42                	ld	s4,16(sp)
    80000d52:	6aa2                	ld	s5,8(sp)
    80000d54:	6b02                	ld	s6,0(sp)
    80000d56:	6121                	addi	sp,sp,64
    80000d58:	8082                	ret

0000000080000d5a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000d5a:	7179                	addi	sp,sp,-48
    80000d5c:	f406                	sd	ra,40(sp)
    80000d5e:	f022                	sd	s0,32(sp)
    80000d60:	ec26                	sd	s1,24(sp)
    80000d62:	e84a                	sd	s2,16(sp)
    80000d64:	e44e                	sd	s3,8(sp)
    80000d66:	1800                	addi	s0,sp,48
  push_off();
    80000d68:	00000097          	auipc	ra,0x0
    80000d6c:	0d2080e7          	jalr	210(ra) # 80000e3a <push_off>
  int id = cpuid();
    80000d70:	00001097          	auipc	ra,0x1
    80000d74:	19a080e7          	jalr	410(ra) # 80001f0a <cpuid>
    80000d78:	892a                	mv	s2,a0
  pop_off();
    80000d7a:	00000097          	auipc	ra,0x0
    80000d7e:	17c080e7          	jalr	380(ra) # 80000ef6 <pop_off>

  struct run *r;

  struct kmem* curr = &cpukmems[id];
  acquire(&curr->lock);
    80000d82:	00291493          	slli	s1,s2,0x2
    80000d86:	012489b3          	add	s3,s1,s2
    80000d8a:	00399793          	slli	a5,s3,0x3
    80000d8e:	00010997          	auipc	s3,0x10
    80000d92:	54a98993          	addi	s3,s3,1354 # 800112d8 <cpukmems>
    80000d96:	99be                	add	s3,s3,a5
    80000d98:	854e                	mv	a0,s3
    80000d9a:	00000097          	auipc	ra,0x0
    80000d9e:	0ec080e7          	jalr	236(ra) # 80000e86 <acquire>
  r = curr->freelist;
    80000da2:	94ca                	add	s1,s1,s2
    80000da4:	048e                	slli	s1,s1,0x3
    80000da6:	00010797          	auipc	a5,0x10
    80000daa:	4e278793          	addi	a5,a5,1250 # 80011288 <name>
    80000dae:	94be                	add	s1,s1,a5
    80000db0:	78a4                	ld	s1,112(s1)
  if(r)
    80000db2:	c0a9                	beqz	s1,80000df4 <kalloc+0x9a>
    curr->freelist = r->next;
    80000db4:	6098                	ld	a4,0(s1)
    80000db6:	00291793          	slli	a5,s2,0x2
    80000dba:	993e                	add	s2,s2,a5
    80000dbc:	090e                	slli	s2,s2,0x3
    80000dbe:	00010797          	auipc	a5,0x10
    80000dc2:	4ca78793          	addi	a5,a5,1226 # 80011288 <name>
    80000dc6:	993e                	add	s2,s2,a5
    80000dc8:	06e93823          	sd	a4,112(s2)
  release(&curr->lock);
    80000dcc:	854e                	mv	a0,s3
    80000dce:	00000097          	auipc	ra,0x0
    80000dd2:	188080e7          	jalr	392(ra) # 80000f56 <release>

  if(r) { // 如果找到物理页，则返回
    memset((char *) r, 5, PGSIZE); // fill with junk
    80000dd6:	6605                	lui	a2,0x1
    80000dd8:	4595                	li	a1,5
    80000dda:	8526                	mv	a0,s1
    80000ddc:	00000097          	auipc	ra,0x0
    80000de0:	4b6080e7          	jalr	1206(ra) # 80001292 <memset>
    return (void*)r;
  } else { // 当前CPU无可用内存，则从别的CPU偷内存
    return stealing(id);
  }
}
    80000de4:	8526                	mv	a0,s1
    80000de6:	70a2                	ld	ra,40(sp)
    80000de8:	7402                	ld	s0,32(sp)
    80000dea:	64e2                	ld	s1,24(sp)
    80000dec:	6942                	ld	s2,16(sp)
    80000dee:	69a2                	ld	s3,8(sp)
    80000df0:	6145                	addi	sp,sp,48
    80000df2:	8082                	ret
  release(&curr->lock);
    80000df4:	854e                	mv	a0,s3
    80000df6:	00000097          	auipc	ra,0x0
    80000dfa:	160080e7          	jalr	352(ra) # 80000f56 <release>
    return stealing(id);
    80000dfe:	854a                	mv	a0,s2
    80000e00:	00000097          	auipc	ra,0x0
    80000e04:	ec2080e7          	jalr	-318(ra) # 80000cc2 <stealing>
    80000e08:	84aa                	mv	s1,a0
    80000e0a:	bfe9                	j	80000de4 <kalloc+0x8a>

0000000080000e0c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000e0c:	411c                	lw	a5,0(a0)
    80000e0e:	e399                	bnez	a5,80000e14 <holding+0x8>
    80000e10:	4501                	li	a0,0
  return r;
}
    80000e12:	8082                	ret
{
    80000e14:	1101                	addi	sp,sp,-32
    80000e16:	ec06                	sd	ra,24(sp)
    80000e18:	e822                	sd	s0,16(sp)
    80000e1a:	e426                	sd	s1,8(sp)
    80000e1c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000e1e:	6904                	ld	s1,16(a0)
    80000e20:	00001097          	auipc	ra,0x1
    80000e24:	0fa080e7          	jalr	250(ra) # 80001f1a <mycpu>
    80000e28:	40a48533          	sub	a0,s1,a0
    80000e2c:	00153513          	seqz	a0,a0
}
    80000e30:	60e2                	ld	ra,24(sp)
    80000e32:	6442                	ld	s0,16(sp)
    80000e34:	64a2                	ld	s1,8(sp)
    80000e36:	6105                	addi	sp,sp,32
    80000e38:	8082                	ret

0000000080000e3a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000e3a:	1101                	addi	sp,sp,-32
    80000e3c:	ec06                	sd	ra,24(sp)
    80000e3e:	e822                	sd	s0,16(sp)
    80000e40:	e426                	sd	s1,8(sp)
    80000e42:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e44:	100024f3          	csrr	s1,sstatus
    80000e48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000e4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e4e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000e52:	00001097          	auipc	ra,0x1
    80000e56:	0c8080e7          	jalr	200(ra) # 80001f1a <mycpu>
    80000e5a:	5d3c                	lw	a5,120(a0)
    80000e5c:	cf89                	beqz	a5,80000e76 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000e5e:	00001097          	auipc	ra,0x1
    80000e62:	0bc080e7          	jalr	188(ra) # 80001f1a <mycpu>
    80000e66:	5d3c                	lw	a5,120(a0)
    80000e68:	2785                	addiw	a5,a5,1
    80000e6a:	dd3c                	sw	a5,120(a0)
}
    80000e6c:	60e2                	ld	ra,24(sp)
    80000e6e:	6442                	ld	s0,16(sp)
    80000e70:	64a2                	ld	s1,8(sp)
    80000e72:	6105                	addi	sp,sp,32
    80000e74:	8082                	ret
    mycpu()->intena = old;
    80000e76:	00001097          	auipc	ra,0x1
    80000e7a:	0a4080e7          	jalr	164(ra) # 80001f1a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000e7e:	8085                	srli	s1,s1,0x1
    80000e80:	8885                	andi	s1,s1,1
    80000e82:	dd64                	sw	s1,124(a0)
    80000e84:	bfe9                	j	80000e5e <push_off+0x24>

0000000080000e86 <acquire>:
{
    80000e86:	1101                	addi	sp,sp,-32
    80000e88:	ec06                	sd	ra,24(sp)
    80000e8a:	e822                	sd	s0,16(sp)
    80000e8c:	e426                	sd	s1,8(sp)
    80000e8e:	1000                	addi	s0,sp,32
    80000e90:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000e92:	00000097          	auipc	ra,0x0
    80000e96:	fa8080e7          	jalr	-88(ra) # 80000e3a <push_off>
  if(holding(lk))
    80000e9a:	8526                	mv	a0,s1
    80000e9c:	00000097          	auipc	ra,0x0
    80000ea0:	f70080e7          	jalr	-144(ra) # 80000e0c <holding>
    80000ea4:	e50d                	bnez	a0,80000ece <acquire+0x48>
    __sync_fetch_and_add(&(lk->n), 1);
    80000ea6:	4785                	li	a5,1
    80000ea8:	01c48713          	addi	a4,s1,28
    80000eac:	0f50000f          	fence	iorw,ow
    80000eb0:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000eb4:	4705                	li	a4,1
    80000eb6:	87ba                	mv	a5,a4
    80000eb8:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000ebc:	2781                	sext.w	a5,a5
    80000ebe:	c385                	beqz	a5,80000ede <acquire+0x58>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000ec0:	01848793          	addi	a5,s1,24
    80000ec4:	0f50000f          	fence	iorw,ow
    80000ec8:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
    80000ecc:	b7ed                	j	80000eb6 <acquire+0x30>
    panic("acquire");
    80000ece:	00007517          	auipc	a0,0x7
    80000ed2:	1a250513          	addi	a0,a0,418 # 80008070 <digits+0x58>
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	6a2080e7          	jalr	1698(ra) # 80000578 <panic>
  __sync_synchronize();
    80000ede:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	038080e7          	jalr	56(ra) # 80001f1a <mycpu>
    80000eea:	e888                	sd	a0,16(s1)
}
    80000eec:	60e2                	ld	ra,24(sp)
    80000eee:	6442                	ld	s0,16(sp)
    80000ef0:	64a2                	ld	s1,8(sp)
    80000ef2:	6105                	addi	sp,sp,32
    80000ef4:	8082                	ret

0000000080000ef6 <pop_off>:

void
pop_off(void)
{
    80000ef6:	1141                	addi	sp,sp,-16
    80000ef8:	e406                	sd	ra,8(sp)
    80000efa:	e022                	sd	s0,0(sp)
    80000efc:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000efe:	00001097          	auipc	ra,0x1
    80000f02:	01c080e7          	jalr	28(ra) # 80001f1a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000f06:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000f0a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000f0c:	e78d                	bnez	a5,80000f36 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000f0e:	5d3c                	lw	a5,120(a0)
    80000f10:	02f05b63          	blez	a5,80000f46 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000f14:	37fd                	addiw	a5,a5,-1
    80000f16:	0007871b          	sext.w	a4,a5
    80000f1a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000f1c:	eb09                	bnez	a4,80000f2e <pop_off+0x38>
    80000f1e:	5d7c                	lw	a5,124(a0)
    80000f20:	c799                	beqz	a5,80000f2e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000f22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000f26:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000f2a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000f2e:	60a2                	ld	ra,8(sp)
    80000f30:	6402                	ld	s0,0(sp)
    80000f32:	0141                	addi	sp,sp,16
    80000f34:	8082                	ret
    panic("pop_off - interruptible");
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	14250513          	addi	a0,a0,322 # 80008078 <digits+0x60>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	63a080e7          	jalr	1594(ra) # 80000578 <panic>
    panic("pop_off");
    80000f46:	00007517          	auipc	a0,0x7
    80000f4a:	14a50513          	addi	a0,a0,330 # 80008090 <digits+0x78>
    80000f4e:	fffff097          	auipc	ra,0xfffff
    80000f52:	62a080e7          	jalr	1578(ra) # 80000578 <panic>

0000000080000f56 <release>:
{
    80000f56:	1101                	addi	sp,sp,-32
    80000f58:	ec06                	sd	ra,24(sp)
    80000f5a:	e822                	sd	s0,16(sp)
    80000f5c:	e426                	sd	s1,8(sp)
    80000f5e:	1000                	addi	s0,sp,32
    80000f60:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000f62:	00000097          	auipc	ra,0x0
    80000f66:	eaa080e7          	jalr	-342(ra) # 80000e0c <holding>
    80000f6a:	c115                	beqz	a0,80000f8e <release+0x38>
  lk->cpu = 0;
    80000f6c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000f70:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000f74:	0f50000f          	fence	iorw,ow
    80000f78:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000f7c:	00000097          	auipc	ra,0x0
    80000f80:	f7a080e7          	jalr	-134(ra) # 80000ef6 <pop_off>
}
    80000f84:	60e2                	ld	ra,24(sp)
    80000f86:	6442                	ld	s0,16(sp)
    80000f88:	64a2                	ld	s1,8(sp)
    80000f8a:	6105                	addi	sp,sp,32
    80000f8c:	8082                	ret
    panic("release");
    80000f8e:	00007517          	auipc	a0,0x7
    80000f92:	10a50513          	addi	a0,a0,266 # 80008098 <digits+0x80>
    80000f96:	fffff097          	auipc	ra,0xfffff
    80000f9a:	5e2080e7          	jalr	1506(ra) # 80000578 <panic>

0000000080000f9e <freelock>:
{
    80000f9e:	1101                	addi	sp,sp,-32
    80000fa0:	ec06                	sd	ra,24(sp)
    80000fa2:	e822                	sd	s0,16(sp)
    80000fa4:	e426                	sd	s1,8(sp)
    80000fa6:	1000                	addi	s0,sp,32
    80000fa8:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000faa:	00010517          	auipc	a0,0x10
    80000fae:	46e50513          	addi	a0,a0,1134 # 80011418 <lock_locks>
    80000fb2:	00000097          	auipc	ra,0x0
    80000fb6:	ed4080e7          	jalr	-300(ra) # 80000e86 <acquire>
    if(locks[i] == lk) {
    80000fba:	00010797          	auipc	a5,0x10
    80000fbe:	47e78793          	addi	a5,a5,1150 # 80011438 <locks>
    80000fc2:	639c                	ld	a5,0(a5)
    80000fc4:	02f48163          	beq	s1,a5,80000fe6 <freelock+0x48>
    80000fc8:	00010717          	auipc	a4,0x10
    80000fcc:	47870713          	addi	a4,a4,1144 # 80011440 <locks+0x8>
  for (i = 0; i < NLOCK; i++) {
    80000fd0:	4785                	li	a5,1
    80000fd2:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000fd6:	6314                	ld	a3,0(a4)
    80000fd8:	00968863          	beq	a3,s1,80000fe8 <freelock+0x4a>
  for (i = 0; i < NLOCK; i++) {
    80000fdc:	2785                	addiw	a5,a5,1
    80000fde:	0721                	addi	a4,a4,8
    80000fe0:	fec79be3          	bne	a5,a2,80000fd6 <freelock+0x38>
    80000fe4:	a811                	j	80000ff8 <freelock+0x5a>
    80000fe6:	4781                	li	a5,0
      locks[i] = 0;
    80000fe8:	078e                	slli	a5,a5,0x3
    80000fea:	00010717          	auipc	a4,0x10
    80000fee:	44e70713          	addi	a4,a4,1102 # 80011438 <locks>
    80000ff2:	97ba                	add	a5,a5,a4
    80000ff4:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000ff8:	00010517          	auipc	a0,0x10
    80000ffc:	42050513          	addi	a0,a0,1056 # 80011418 <lock_locks>
    80001000:	00000097          	auipc	ra,0x0
    80001004:	f56080e7          	jalr	-170(ra) # 80000f56 <release>
}
    80001008:	60e2                	ld	ra,24(sp)
    8000100a:	6442                	ld	s0,16(sp)
    8000100c:	64a2                	ld	s1,8(sp)
    8000100e:	6105                	addi	sp,sp,32
    80001010:	8082                	ret

0000000080001012 <initlock>:
{
    80001012:	1101                	addi	sp,sp,-32
    80001014:	ec06                	sd	ra,24(sp)
    80001016:	e822                	sd	s0,16(sp)
    80001018:	e426                	sd	s1,8(sp)
    8000101a:	1000                	addi	s0,sp,32
    8000101c:	84aa                	mv	s1,a0
  lk->name = name;
    8000101e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80001020:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80001024:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80001028:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    8000102c:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80001030:	00010517          	auipc	a0,0x10
    80001034:	3e850513          	addi	a0,a0,1000 # 80011418 <lock_locks>
    80001038:	00000097          	auipc	ra,0x0
    8000103c:	e4e080e7          	jalr	-434(ra) # 80000e86 <acquire>
    if(locks[i] == 0) {
    80001040:	00010797          	auipc	a5,0x10
    80001044:	3f878793          	addi	a5,a5,1016 # 80011438 <locks>
    80001048:	639c                	ld	a5,0(a5)
    8000104a:	c795                	beqz	a5,80001076 <initlock+0x64>
    8000104c:	00010717          	auipc	a4,0x10
    80001050:	3f470713          	addi	a4,a4,1012 # 80011440 <locks+0x8>
  for (i = 0; i < NLOCK; i++) {
    80001054:	4785                	li	a5,1
    80001056:	1f400613          	li	a2,500
    if(locks[i] == 0) {
    8000105a:	6314                	ld	a3,0(a4)
    8000105c:	ce91                	beqz	a3,80001078 <initlock+0x66>
  for (i = 0; i < NLOCK; i++) {
    8000105e:	2785                	addiw	a5,a5,1
    80001060:	0721                	addi	a4,a4,8
    80001062:	fec79ce3          	bne	a5,a2,8000105a <initlock+0x48>
  panic("findslot");
    80001066:	00007517          	auipc	a0,0x7
    8000106a:	03a50513          	addi	a0,a0,58 # 800080a0 <digits+0x88>
    8000106e:	fffff097          	auipc	ra,0xfffff
    80001072:	50a080e7          	jalr	1290(ra) # 80000578 <panic>
  for (i = 0; i < NLOCK; i++) {
    80001076:	4781                	li	a5,0
      locks[i] = lk;
    80001078:	078e                	slli	a5,a5,0x3
    8000107a:	00010717          	auipc	a4,0x10
    8000107e:	3be70713          	addi	a4,a4,958 # 80011438 <locks>
    80001082:	97ba                	add	a5,a5,a4
    80001084:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80001086:	00010517          	auipc	a0,0x10
    8000108a:	39250513          	addi	a0,a0,914 # 80011418 <lock_locks>
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	ec8080e7          	jalr	-312(ra) # 80000f56 <release>
}
    80001096:	60e2                	ld	ra,24(sp)
    80001098:	6442                	ld	s0,16(sp)
    8000109a:	64a2                	ld	s1,8(sp)
    8000109c:	6105                	addi	sp,sp,32
    8000109e:	8082                	ret

00000000800010a0 <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    800010a0:	4e5c                	lw	a5,28(a2)
    800010a2:	00f04463          	bgtz	a5,800010aa <snprint_lock+0xa>
  int n = 0;
    800010a6:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    800010a8:	8082                	ret
{
    800010aa:	1141                	addi	sp,sp,-16
    800010ac:	e406                	sd	ra,8(sp)
    800010ae:	e022                	sd	s0,0(sp)
    800010b0:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    800010b2:	4e18                	lw	a4,24(a2)
    800010b4:	6614                	ld	a3,8(a2)
    800010b6:	00007617          	auipc	a2,0x7
    800010ba:	ffa60613          	addi	a2,a2,-6 # 800080b0 <digits+0x98>
    800010be:	00006097          	auipc	ra,0x6
    800010c2:	a86080e7          	jalr	-1402(ra) # 80006b44 <snprintf>
}
    800010c6:	60a2                	ld	ra,8(sp)
    800010c8:	6402                	ld	s0,0(sp)
    800010ca:	0141                	addi	sp,sp,16
    800010cc:	8082                	ret

00000000800010ce <statslock>:

int
statslock(char *buf, int sz) {
    800010ce:	711d                	addi	sp,sp,-96
    800010d0:	ec86                	sd	ra,88(sp)
    800010d2:	e8a2                	sd	s0,80(sp)
    800010d4:	e4a6                	sd	s1,72(sp)
    800010d6:	e0ca                	sd	s2,64(sp)
    800010d8:	fc4e                	sd	s3,56(sp)
    800010da:	f852                	sd	s4,48(sp)
    800010dc:	f456                	sd	s5,40(sp)
    800010de:	f05a                	sd	s6,32(sp)
    800010e0:	ec5e                	sd	s7,24(sp)
    800010e2:	e862                	sd	s8,16(sp)
    800010e4:	e466                	sd	s9,8(sp)
    800010e6:	1080                	addi	s0,sp,96
    800010e8:	8aaa                	mv	s5,a0
    800010ea:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    800010ec:	00010517          	auipc	a0,0x10
    800010f0:	32c50513          	addi	a0,a0,812 # 80011418 <lock_locks>
    800010f4:	00000097          	auipc	ra,0x0
    800010f8:	d92080e7          	jalr	-622(ra) # 80000e86 <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    800010fc:	00007617          	auipc	a2,0x7
    80001100:	fe460613          	addi	a2,a2,-28 # 800080e0 <digits+0xc8>
    80001104:	85da                	mv	a1,s6
    80001106:	8556                	mv	a0,s5
    80001108:	00006097          	auipc	ra,0x6
    8000110c:	a3c080e7          	jalr	-1476(ra) # 80006b44 <snprintf>
    80001110:	89aa                	mv	s3,a0
  for(int i = 0; i < NLOCK; i++) {
    if(locks[i] == 0)
    80001112:	00010797          	auipc	a5,0x10
    80001116:	32678793          	addi	a5,a5,806 # 80011438 <locks>
    8000111a:	639c                	ld	a5,0(a5)
    8000111c:	cbc1                	beqz	a5,800011ac <statslock+0xde>
    8000111e:	00010497          	auipc	s1,0x10
    80001122:	31a48493          	addi	s1,s1,794 # 80011438 <locks>
    80001126:	00011c17          	auipc	s8,0x11
    8000112a:	2aac0c13          	addi	s8,s8,682 # 800123d0 <locks+0xf98>
  int tot = 0;
    8000112e:	4a01                	li	s4,0
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80001130:	00007917          	auipc	s2,0x7
    80001134:	fd090913          	addi	s2,s2,-48 # 80008100 <digits+0xe8>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80001138:	00007c97          	auipc	s9,0x7
    8000113c:	fd0c8c93          	addi	s9,s9,-48 # 80008108 <digits+0xf0>
    80001140:	a025                	j	80001168 <statslock+0x9a>
      tot += locks[i]->nts;
    80001142:	6090                	ld	a2,0(s1)
    80001144:	4e1c                	lw	a5,24(a2)
    80001146:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    8000114a:	413b05bb          	subw	a1,s6,s3
    8000114e:	013a8533          	add	a0,s5,s3
    80001152:	00000097          	auipc	ra,0x0
    80001156:	f4e080e7          	jalr	-178(ra) # 800010a0 <snprint_lock>
    8000115a:	013509bb          	addw	s3,a0,s3
  for(int i = 0; i < NLOCK; i++) {
    8000115e:	05848863          	beq	s1,s8,800011ae <statslock+0xe0>
    if(locks[i] == 0)
    80001162:	04a1                	addi	s1,s1,8
    80001164:	609c                	ld	a5,0(s1)
    80001166:	c7a1                	beqz	a5,800011ae <statslock+0xe0>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80001168:	0087bb83          	ld	s7,8(a5)
    8000116c:	854a                	mv	a0,s2
    8000116e:	00000097          	auipc	ra,0x0
    80001172:	2ce080e7          	jalr	718(ra) # 8000143c <strlen>
    80001176:	0005061b          	sext.w	a2,a0
    8000117a:	85ca                	mv	a1,s2
    8000117c:	855e                	mv	a0,s7
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	1fc080e7          	jalr	508(ra) # 8000137a <strncmp>
    80001186:	dd55                	beqz	a0,80001142 <statslock+0x74>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80001188:	609c                	ld	a5,0(s1)
    8000118a:	0087bb83          	ld	s7,8(a5)
    8000118e:	8566                	mv	a0,s9
    80001190:	00000097          	auipc	ra,0x0
    80001194:	2ac080e7          	jalr	684(ra) # 8000143c <strlen>
    80001198:	0005061b          	sext.w	a2,a0
    8000119c:	85e6                	mv	a1,s9
    8000119e:	855e                	mv	a0,s7
    800011a0:	00000097          	auipc	ra,0x0
    800011a4:	1da080e7          	jalr	474(ra) # 8000137a <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    800011a8:	f95d                	bnez	a0,8000115e <statslock+0x90>
    800011aa:	bf61                	j	80001142 <statslock+0x74>
  int tot = 0;
    800011ac:	4a01                	li	s4,0
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    800011ae:	00007617          	auipc	a2,0x7
    800011b2:	f6260613          	addi	a2,a2,-158 # 80008110 <digits+0xf8>
    800011b6:	413b05bb          	subw	a1,s6,s3
    800011ba:	013a8533          	add	a0,s5,s3
    800011be:	00006097          	auipc	ra,0x6
    800011c2:	986080e7          	jalr	-1658(ra) # 80006b44 <snprintf>
    800011c6:	013509bb          	addw	s3,a0,s3
    800011ca:	4b95                	li	s7,5
  int last = 100000000;
    800011cc:	05f5e537          	lui	a0,0x5f5e
    800011d0:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
      if(locks[i] == 0)
    800011d4:	00010497          	auipc	s1,0x10
    800011d8:	26448493          	addi	s1,s1,612 # 80011438 <locks>
    for(int i = 0; i < NLOCK; i++) {
    800011dc:	4c01                	li	s8,0
    800011de:	1f400913          	li	s2,500
    800011e2:	a891                	j	80001236 <statslock+0x168>
    800011e4:	2705                	addiw	a4,a4,1
    800011e6:	03270363          	beq	a4,s2,8000120c <statslock+0x13e>
      if(locks[i] == 0)
    800011ea:	06a1                	addi	a3,a3,8
    800011ec:	ff86b783          	ld	a5,-8(a3)
    800011f0:	cf91                	beqz	a5,8000120c <statslock+0x13e>
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    800011f2:	4f90                	lw	a2,24(a5)
    800011f4:	00359793          	slli	a5,a1,0x3
    800011f8:	97a6                	add	a5,a5,s1
    800011fa:	639c                	ld	a5,0(a5)
    800011fc:	4f9c                	lw	a5,24(a5)
    800011fe:	fec7d3e3          	ble	a2,a5,800011e4 <statslock+0x116>
    80001202:	fea651e3          	ble	a0,a2,800011e4 <statslock+0x116>
    80001206:	85ba                	mv	a1,a4
    80001208:	bff1                	j	800011e4 <statslock+0x116>
    int top = 0;
    8000120a:	85e2                	mv	a1,s8
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    8000120c:	058e                	slli	a1,a1,0x3
    8000120e:	00b48cb3          	add	s9,s1,a1
    80001212:	000cb603          	ld	a2,0(s9)
    80001216:	413b05bb          	subw	a1,s6,s3
    8000121a:	013a8533          	add	a0,s5,s3
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	e82080e7          	jalr	-382(ra) # 800010a0 <snprint_lock>
    80001226:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    8000122a:	000cb783          	ld	a5,0(s9)
    8000122e:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    80001230:	3bfd                	addiw	s7,s7,-1
    80001232:	000b8b63          	beqz	s7,80001248 <statslock+0x17a>
      if(locks[i] == 0)
    80001236:	609c                	ld	a5,0(s1)
    80001238:	dbe9                	beqz	a5,8000120a <statslock+0x13c>
    8000123a:	00010697          	auipc	a3,0x10
    8000123e:	20668693          	addi	a3,a3,518 # 80011440 <locks+0x8>
    for(int i = 0; i < NLOCK; i++) {
    80001242:	8762                	mv	a4,s8
    int top = 0;
    80001244:	85e2                	mv	a1,s8
    80001246:	b775                	j	800011f2 <statslock+0x124>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    80001248:	86d2                	mv	a3,s4
    8000124a:	00007617          	auipc	a2,0x7
    8000124e:	ee660613          	addi	a2,a2,-282 # 80008130 <digits+0x118>
    80001252:	413b05bb          	subw	a1,s6,s3
    80001256:	013a8533          	add	a0,s5,s3
    8000125a:	00006097          	auipc	ra,0x6
    8000125e:	8ea080e7          	jalr	-1814(ra) # 80006b44 <snprintf>
    80001262:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    80001266:	00010517          	auipc	a0,0x10
    8000126a:	1b250513          	addi	a0,a0,434 # 80011418 <lock_locks>
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	ce8080e7          	jalr	-792(ra) # 80000f56 <release>
  return n;
}
    80001276:	854e                	mv	a0,s3
    80001278:	60e6                	ld	ra,88(sp)
    8000127a:	6446                	ld	s0,80(sp)
    8000127c:	64a6                	ld	s1,72(sp)
    8000127e:	6906                	ld	s2,64(sp)
    80001280:	79e2                	ld	s3,56(sp)
    80001282:	7a42                	ld	s4,48(sp)
    80001284:	7aa2                	ld	s5,40(sp)
    80001286:	7b02                	ld	s6,32(sp)
    80001288:	6be2                	ld	s7,24(sp)
    8000128a:	6c42                	ld	s8,16(sp)
    8000128c:	6ca2                	ld	s9,8(sp)
    8000128e:	6125                	addi	sp,sp,96
    80001290:	8082                	ret

0000000080001292 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80001292:	1141                	addi	sp,sp,-16
    80001294:	e422                	sd	s0,8(sp)
    80001296:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80001298:	ce09                	beqz	a2,800012b2 <memset+0x20>
    8000129a:	87aa                	mv	a5,a0
    8000129c:	fff6071b          	addiw	a4,a2,-1
    800012a0:	1702                	slli	a4,a4,0x20
    800012a2:	9301                	srli	a4,a4,0x20
    800012a4:	0705                	addi	a4,a4,1
    800012a6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    800012a8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800012ac:	0785                	addi	a5,a5,1
    800012ae:	fee79de3          	bne	a5,a4,800012a8 <memset+0x16>
  }
  return dst;
}
    800012b2:	6422                	ld	s0,8(sp)
    800012b4:	0141                	addi	sp,sp,16
    800012b6:	8082                	ret

00000000800012b8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800012b8:	1141                	addi	sp,sp,-16
    800012ba:	e422                	sd	s0,8(sp)
    800012bc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800012be:	ce15                	beqz	a2,800012fa <memcmp+0x42>
    800012c0:	fff6069b          	addiw	a3,a2,-1
    if(*s1 != *s2)
    800012c4:	00054783          	lbu	a5,0(a0)
    800012c8:	0005c703          	lbu	a4,0(a1)
    800012cc:	02e79063          	bne	a5,a4,800012ec <memcmp+0x34>
    800012d0:	1682                	slli	a3,a3,0x20
    800012d2:	9281                	srli	a3,a3,0x20
    800012d4:	0685                	addi	a3,a3,1
    800012d6:	96aa                	add	a3,a3,a0
      return *s1 - *s2;
    s1++, s2++;
    800012d8:	0505                	addi	a0,a0,1
    800012da:	0585                	addi	a1,a1,1
  while(n-- > 0){
    800012dc:	00d50d63          	beq	a0,a3,800012f6 <memcmp+0x3e>
    if(*s1 != *s2)
    800012e0:	00054783          	lbu	a5,0(a0)
    800012e4:	0005c703          	lbu	a4,0(a1)
    800012e8:	fee788e3          	beq	a5,a4,800012d8 <memcmp+0x20>
      return *s1 - *s2;
    800012ec:	40e7853b          	subw	a0,a5,a4
  }

  return 0;
}
    800012f0:	6422                	ld	s0,8(sp)
    800012f2:	0141                	addi	sp,sp,16
    800012f4:	8082                	ret
  return 0;
    800012f6:	4501                	li	a0,0
    800012f8:	bfe5                	j	800012f0 <memcmp+0x38>
    800012fa:	4501                	li	a0,0
    800012fc:	bfd5                	j	800012f0 <memcmp+0x38>

00000000800012fe <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800012fe:	1141                	addi	sp,sp,-16
    80001300:	e422                	sd	s0,8(sp)
    80001302:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80001304:	00a5f963          	bleu	a0,a1,80001316 <memmove+0x18>
    80001308:	02061713          	slli	a4,a2,0x20
    8000130c:	9301                	srli	a4,a4,0x20
    8000130e:	00e587b3          	add	a5,a1,a4
    80001312:	02f56563          	bltu	a0,a5,8000133c <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001316:	fff6069b          	addiw	a3,a2,-1
    8000131a:	ce11                	beqz	a2,80001336 <memmove+0x38>
    8000131c:	1682                	slli	a3,a3,0x20
    8000131e:	9281                	srli	a3,a3,0x20
    80001320:	0685                	addi	a3,a3,1
    80001322:	96ae                	add	a3,a3,a1
    80001324:	87aa                	mv	a5,a0
      *d++ = *s++;
    80001326:	0585                	addi	a1,a1,1
    80001328:	0785                	addi	a5,a5,1
    8000132a:	fff5c703          	lbu	a4,-1(a1)
    8000132e:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80001332:	fed59ae3          	bne	a1,a3,80001326 <memmove+0x28>

  return dst;
}
    80001336:	6422                	ld	s0,8(sp)
    80001338:	0141                	addi	sp,sp,16
    8000133a:	8082                	ret
    d += n;
    8000133c:	972a                	add	a4,a4,a0
    while(n-- > 0)
    8000133e:	fff6069b          	addiw	a3,a2,-1
    80001342:	da75                	beqz	a2,80001336 <memmove+0x38>
    80001344:	02069613          	slli	a2,a3,0x20
    80001348:	9201                	srli	a2,a2,0x20
    8000134a:	fff64613          	not	a2,a2
    8000134e:	963e                	add	a2,a2,a5
      *--d = *--s;
    80001350:	17fd                	addi	a5,a5,-1
    80001352:	177d                	addi	a4,a4,-1
    80001354:	0007c683          	lbu	a3,0(a5)
    80001358:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    8000135c:	fef61ae3          	bne	a2,a5,80001350 <memmove+0x52>
    80001360:	bfd9                	j	80001336 <memmove+0x38>

0000000080001362 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001362:	1141                	addi	sp,sp,-16
    80001364:	e406                	sd	ra,8(sp)
    80001366:	e022                	sd	s0,0(sp)
    80001368:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	f94080e7          	jalr	-108(ra) # 800012fe <memmove>
}
    80001372:	60a2                	ld	ra,8(sp)
    80001374:	6402                	ld	s0,0(sp)
    80001376:	0141                	addi	sp,sp,16
    80001378:	8082                	ret

000000008000137a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    8000137a:	1141                	addi	sp,sp,-16
    8000137c:	e422                	sd	s0,8(sp)
    8000137e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80001380:	c229                	beqz	a2,800013c2 <strncmp+0x48>
    80001382:	00054783          	lbu	a5,0(a0)
    80001386:	c795                	beqz	a5,800013b2 <strncmp+0x38>
    80001388:	0005c703          	lbu	a4,0(a1)
    8000138c:	02f71363          	bne	a4,a5,800013b2 <strncmp+0x38>
    80001390:	fff6071b          	addiw	a4,a2,-1
    80001394:	1702                	slli	a4,a4,0x20
    80001396:	9301                	srli	a4,a4,0x20
    80001398:	0705                	addi	a4,a4,1
    8000139a:	972a                	add	a4,a4,a0
    n--, p++, q++;
    8000139c:	0505                	addi	a0,a0,1
    8000139e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800013a0:	02e50363          	beq	a0,a4,800013c6 <strncmp+0x4c>
    800013a4:	00054783          	lbu	a5,0(a0)
    800013a8:	c789                	beqz	a5,800013b2 <strncmp+0x38>
    800013aa:	0005c683          	lbu	a3,0(a1)
    800013ae:	fef687e3          	beq	a3,a5,8000139c <strncmp+0x22>
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
    800013b2:	00054503          	lbu	a0,0(a0)
    800013b6:	0005c783          	lbu	a5,0(a1)
    800013ba:	9d1d                	subw	a0,a0,a5
}
    800013bc:	6422                	ld	s0,8(sp)
    800013be:	0141                	addi	sp,sp,16
    800013c0:	8082                	ret
    return 0;
    800013c2:	4501                	li	a0,0
    800013c4:	bfe5                	j	800013bc <strncmp+0x42>
    800013c6:	4501                	li	a0,0
    800013c8:	bfd5                	j	800013bc <strncmp+0x42>

00000000800013ca <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800013ca:	1141                	addi	sp,sp,-16
    800013cc:	e422                	sd	s0,8(sp)
    800013ce:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800013d0:	872a                	mv	a4,a0
    800013d2:	a011                	j	800013d6 <strncpy+0xc>
    800013d4:	8636                	mv	a2,a3
    800013d6:	fff6069b          	addiw	a3,a2,-1
    800013da:	00c05963          	blez	a2,800013ec <strncpy+0x22>
    800013de:	0705                	addi	a4,a4,1
    800013e0:	0005c783          	lbu	a5,0(a1)
    800013e4:	fef70fa3          	sb	a5,-1(a4)
    800013e8:	0585                	addi	a1,a1,1
    800013ea:	f7ed                	bnez	a5,800013d4 <strncpy+0xa>
    ;
  while(n-- > 0)
    800013ec:	00d05c63          	blez	a3,80001404 <strncpy+0x3a>
    800013f0:	86ba                	mv	a3,a4
    *s++ = 0;
    800013f2:	0685                	addi	a3,a3,1
    800013f4:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    800013f8:	fff6c793          	not	a5,a3
    800013fc:	9fb9                	addw	a5,a5,a4
    800013fe:	9fb1                	addw	a5,a5,a2
    80001400:	fef049e3          	bgtz	a5,800013f2 <strncpy+0x28>
  return os;
}
    80001404:	6422                	ld	s0,8(sp)
    80001406:	0141                	addi	sp,sp,16
    80001408:	8082                	ret

000000008000140a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000140a:	1141                	addi	sp,sp,-16
    8000140c:	e422                	sd	s0,8(sp)
    8000140e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001410:	02c05363          	blez	a2,80001436 <safestrcpy+0x2c>
    80001414:	fff6069b          	addiw	a3,a2,-1
    80001418:	1682                	slli	a3,a3,0x20
    8000141a:	9281                	srli	a3,a3,0x20
    8000141c:	96ae                	add	a3,a3,a1
    8000141e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001420:	00d58963          	beq	a1,a3,80001432 <safestrcpy+0x28>
    80001424:	0585                	addi	a1,a1,1
    80001426:	0785                	addi	a5,a5,1
    80001428:	fff5c703          	lbu	a4,-1(a1)
    8000142c:	fee78fa3          	sb	a4,-1(a5)
    80001430:	fb65                	bnez	a4,80001420 <safestrcpy+0x16>
    ;
  *s = 0;
    80001432:	00078023          	sb	zero,0(a5)
  return os;
}
    80001436:	6422                	ld	s0,8(sp)
    80001438:	0141                	addi	sp,sp,16
    8000143a:	8082                	ret

000000008000143c <strlen>:

int
strlen(const char *s)
{
    8000143c:	1141                	addi	sp,sp,-16
    8000143e:	e422                	sd	s0,8(sp)
    80001440:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001442:	00054783          	lbu	a5,0(a0)
    80001446:	cf91                	beqz	a5,80001462 <strlen+0x26>
    80001448:	0505                	addi	a0,a0,1
    8000144a:	87aa                	mv	a5,a0
    8000144c:	4685                	li	a3,1
    8000144e:	9e89                	subw	a3,a3,a0
    80001450:	00f6853b          	addw	a0,a3,a5
    80001454:	0785                	addi	a5,a5,1
    80001456:	fff7c703          	lbu	a4,-1(a5)
    8000145a:	fb7d                	bnez	a4,80001450 <strlen+0x14>
    ;
  return n;
}
    8000145c:	6422                	ld	s0,8(sp)
    8000145e:	0141                	addi	sp,sp,16
    80001460:	8082                	ret
  for(n = 0; s[n]; n++)
    80001462:	4501                	li	a0,0
    80001464:	bfe5                	j	8000145c <strlen+0x20>

0000000080001466 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001466:	1141                	addi	sp,sp,-16
    80001468:	e406                	sd	ra,8(sp)
    8000146a:	e022                	sd	s0,0(sp)
    8000146c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000146e:	00001097          	auipc	ra,0x1
    80001472:	a9c080e7          	jalr	-1380(ra) # 80001f0a <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001476:	00008717          	auipc	a4,0x8
    8000147a:	b9670713          	addi	a4,a4,-1130 # 8000900c <started>
  if(cpuid() == 0){
    8000147e:	c139                	beqz	a0,800014c4 <main+0x5e>
    while(started == 0)
    80001480:	431c                	lw	a5,0(a4)
    80001482:	2781                	sext.w	a5,a5
    80001484:	dff5                	beqz	a5,80001480 <main+0x1a>
      ;
    __sync_synchronize();
    80001486:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000148a:	00001097          	auipc	ra,0x1
    8000148e:	a80080e7          	jalr	-1408(ra) # 80001f0a <cpuid>
    80001492:	85aa                	mv	a1,a0
    80001494:	00007517          	auipc	a0,0x7
    80001498:	cc450513          	addi	a0,a0,-828 # 80008158 <digits+0x140>
    8000149c:	fffff097          	auipc	ra,0xfffff
    800014a0:	126080e7          	jalr	294(ra) # 800005c2 <printf>
    kvminithart();    // turn on paging
    800014a4:	00000097          	auipc	ra,0x0
    800014a8:	186080e7          	jalr	390(ra) # 8000162a <kvminithart>
    trapinithart();   // install kernel trap vector
    800014ac:	00001097          	auipc	ra,0x1
    800014b0:	6f4080e7          	jalr	1780(ra) # 80002ba0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800014b4:	00005097          	auipc	ra,0x5
    800014b8:	eac080e7          	jalr	-340(ra) # 80006360 <plicinithart>
  }

  scheduler();        
    800014bc:	00001097          	auipc	ra,0x1
    800014c0:	fb0080e7          	jalr	-80(ra) # 8000246c <scheduler>
    consoleinit();
    800014c4:	fffff097          	auipc	ra,0xfffff
    800014c8:	fc2080e7          	jalr	-62(ra) # 80000486 <consoleinit>
    statsinit();
    800014cc:	00005097          	auipc	ra,0x5
    800014d0:	598080e7          	jalr	1432(ra) # 80006a64 <statsinit>
    printfinit();
    800014d4:	fffff097          	auipc	ra,0xfffff
    800014d8:	2d4080e7          	jalr	724(ra) # 800007a8 <printfinit>
    printf("\n");
    800014dc:	00007517          	auipc	a0,0x7
    800014e0:	c8c50513          	addi	a0,a0,-884 # 80008168 <digits+0x150>
    800014e4:	fffff097          	auipc	ra,0xfffff
    800014e8:	0de080e7          	jalr	222(ra) # 800005c2 <printf>
    printf("xv6 kernel is booting\n");
    800014ec:	00007517          	auipc	a0,0x7
    800014f0:	c5450513          	addi	a0,a0,-940 # 80008140 <digits+0x128>
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	0ce080e7          	jalr	206(ra) # 800005c2 <printf>
    printf("\n");
    800014fc:	00007517          	auipc	a0,0x7
    80001500:	c6c50513          	addi	a0,a0,-916 # 80008168 <digits+0x150>
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	0be080e7          	jalr	190(ra) # 800005c2 <printf>
    kinit();         // physical page allocator
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	74a080e7          	jalr	1866(ra) # 80000c56 <kinit>
    kvminit();       // create kernel page table
    80001514:	00000097          	auipc	ra,0x0
    80001518:	244080e7          	jalr	580(ra) # 80001758 <kvminit>
    kvminithart();   // turn on paging
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	10e080e7          	jalr	270(ra) # 8000162a <kvminithart>
    procinit();      // process table
    80001524:	00001097          	auipc	ra,0x1
    80001528:	916080e7          	jalr	-1770(ra) # 80001e3a <procinit>
    trapinit();      // trap vectors
    8000152c:	00001097          	auipc	ra,0x1
    80001530:	64c080e7          	jalr	1612(ra) # 80002b78 <trapinit>
    trapinithart();  // install kernel trap vector
    80001534:	00001097          	auipc	ra,0x1
    80001538:	66c080e7          	jalr	1644(ra) # 80002ba0 <trapinithart>
    plicinit();      // set up interrupt controller
    8000153c:	00005097          	auipc	ra,0x5
    80001540:	e0e080e7          	jalr	-498(ra) # 8000634a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001544:	00005097          	auipc	ra,0x5
    80001548:	e1c080e7          	jalr	-484(ra) # 80006360 <plicinithart>
    binit();         // buffer cache
    8000154c:	00002097          	auipc	ra,0x2
    80001550:	db8080e7          	jalr	-584(ra) # 80003304 <binit>
    iinit();         // inode cache
    80001554:	00002097          	auipc	ra,0x2
    80001558:	59a080e7          	jalr	1434(ra) # 80003aee <iinit>
    fileinit();      // file table
    8000155c:	00003097          	auipc	ra,0x3
    80001560:	576080e7          	jalr	1398(ra) # 80004ad2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001564:	00005097          	auipc	ra,0x5
    80001568:	f1e080e7          	jalr	-226(ra) # 80006482 <virtio_disk_init>
    userinit();      // first user process
    8000156c:	00001097          	auipc	ra,0x1
    80001570:	c96080e7          	jalr	-874(ra) # 80002202 <userinit>
    __sync_synchronize();
    80001574:	0ff0000f          	fence
    started = 1;
    80001578:	4785                	li	a5,1
    8000157a:	00008717          	auipc	a4,0x8
    8000157e:	a8f72923          	sw	a5,-1390(a4) # 8000900c <started>
    80001582:	bf2d                	j	800014bc <main+0x56>

0000000080001584 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001584:	7139                	addi	sp,sp,-64
    80001586:	fc06                	sd	ra,56(sp)
    80001588:	f822                	sd	s0,48(sp)
    8000158a:	f426                	sd	s1,40(sp)
    8000158c:	f04a                	sd	s2,32(sp)
    8000158e:	ec4e                	sd	s3,24(sp)
    80001590:	e852                	sd	s4,16(sp)
    80001592:	e456                	sd	s5,8(sp)
    80001594:	e05a                	sd	s6,0(sp)
    80001596:	0080                	addi	s0,sp,64
    80001598:	84aa                	mv	s1,a0
    8000159a:	89ae                	mv	s3,a1
    8000159c:	8b32                	mv	s6,a2
  if(va >= MAXVA)
    8000159e:	57fd                	li	a5,-1
    800015a0:	83e9                	srli	a5,a5,0x1a
    800015a2:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800015a4:	4ab1                	li	s5,12
  if(va >= MAXVA)
    800015a6:	04b7f263          	bleu	a1,a5,800015ea <walk+0x66>
    panic("walk");
    800015aa:	00007517          	auipc	a0,0x7
    800015ae:	bc650513          	addi	a0,a0,-1082 # 80008170 <digits+0x158>
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	fc6080e7          	jalr	-58(ra) # 80000578 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800015ba:	060b0663          	beqz	s6,80001626 <walk+0xa2>
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	79c080e7          	jalr	1948(ra) # 80000d5a <kalloc>
    800015c6:	84aa                	mv	s1,a0
    800015c8:	c529                	beqz	a0,80001612 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800015ca:	6605                	lui	a2,0x1
    800015cc:	4581                	li	a1,0
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	cc4080e7          	jalr	-828(ra) # 80001292 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800015d6:	00c4d793          	srli	a5,s1,0xc
    800015da:	07aa                	slli	a5,a5,0xa
    800015dc:	0017e793          	ori	a5,a5,1
    800015e0:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800015e4:	3a5d                	addiw	s4,s4,-9
    800015e6:	035a0063          	beq	s4,s5,80001606 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800015ea:	0149d933          	srl	s2,s3,s4
    800015ee:	1ff97913          	andi	s2,s2,511
    800015f2:	090e                	slli	s2,s2,0x3
    800015f4:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800015f6:	00093483          	ld	s1,0(s2)
    800015fa:	0014f793          	andi	a5,s1,1
    800015fe:	dfd5                	beqz	a5,800015ba <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001600:	80a9                	srli	s1,s1,0xa
    80001602:	04b2                	slli	s1,s1,0xc
    80001604:	b7c5                	j	800015e4 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001606:	00c9d513          	srli	a0,s3,0xc
    8000160a:	1ff57513          	andi	a0,a0,511
    8000160e:	050e                	slli	a0,a0,0x3
    80001610:	9526                	add	a0,a0,s1
}
    80001612:	70e2                	ld	ra,56(sp)
    80001614:	7442                	ld	s0,48(sp)
    80001616:	74a2                	ld	s1,40(sp)
    80001618:	7902                	ld	s2,32(sp)
    8000161a:	69e2                	ld	s3,24(sp)
    8000161c:	6a42                	ld	s4,16(sp)
    8000161e:	6aa2                	ld	s5,8(sp)
    80001620:	6b02                	ld	s6,0(sp)
    80001622:	6121                	addi	sp,sp,64
    80001624:	8082                	ret
        return 0;
    80001626:	4501                	li	a0,0
    80001628:	b7ed                	j	80001612 <walk+0x8e>

000000008000162a <kvminithart>:
{
    8000162a:	1141                	addi	sp,sp,-16
    8000162c:	e422                	sd	s0,8(sp)
    8000162e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001630:	00008797          	auipc	a5,0x8
    80001634:	9e078793          	addi	a5,a5,-1568 # 80009010 <kernel_pagetable>
    80001638:	639c                	ld	a5,0(a5)
    8000163a:	83b1                	srli	a5,a5,0xc
    8000163c:	577d                	li	a4,-1
    8000163e:	177e                	slli	a4,a4,0x3f
    80001640:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001642:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001646:	12000073          	sfence.vma
}
    8000164a:	6422                	ld	s0,8(sp)
    8000164c:	0141                	addi	sp,sp,16
    8000164e:	8082                	ret

0000000080001650 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001650:	57fd                	li	a5,-1
    80001652:	83e9                	srli	a5,a5,0x1a
    80001654:	00b7f463          	bleu	a1,a5,8000165c <walkaddr+0xc>
    return 0;
    80001658:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000165a:	8082                	ret
{
    8000165c:	1141                	addi	sp,sp,-16
    8000165e:	e406                	sd	ra,8(sp)
    80001660:	e022                	sd	s0,0(sp)
    80001662:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001664:	4601                	li	a2,0
    80001666:	00000097          	auipc	ra,0x0
    8000166a:	f1e080e7          	jalr	-226(ra) # 80001584 <walk>
  if(pte == 0)
    8000166e:	c105                	beqz	a0,8000168e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001670:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001672:	0117f693          	andi	a3,a5,17
    80001676:	4745                	li	a4,17
    return 0;
    80001678:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000167a:	00e68663          	beq	a3,a4,80001686 <walkaddr+0x36>
}
    8000167e:	60a2                	ld	ra,8(sp)
    80001680:	6402                	ld	s0,0(sp)
    80001682:	0141                	addi	sp,sp,16
    80001684:	8082                	ret
  pa = PTE2PA(*pte);
    80001686:	00a7d513          	srli	a0,a5,0xa
    8000168a:	0532                	slli	a0,a0,0xc
  return pa;
    8000168c:	bfcd                	j	8000167e <walkaddr+0x2e>
    return 0;
    8000168e:	4501                	li	a0,0
    80001690:	b7fd                	j	8000167e <walkaddr+0x2e>

0000000080001692 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001692:	715d                	addi	sp,sp,-80
    80001694:	e486                	sd	ra,72(sp)
    80001696:	e0a2                	sd	s0,64(sp)
    80001698:	fc26                	sd	s1,56(sp)
    8000169a:	f84a                	sd	s2,48(sp)
    8000169c:	f44e                	sd	s3,40(sp)
    8000169e:	f052                	sd	s4,32(sp)
    800016a0:	ec56                	sd	s5,24(sp)
    800016a2:	e85a                	sd	s6,16(sp)
    800016a4:	e45e                	sd	s7,8(sp)
    800016a6:	0880                	addi	s0,sp,80
    800016a8:	8aaa                	mv	s5,a0
    800016aa:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800016ac:	79fd                	lui	s3,0xfffff
    800016ae:	0135fa33          	and	s4,a1,s3
  last = PGROUNDDOWN(va + size - 1);
    800016b2:	167d                	addi	a2,a2,-1
    800016b4:	962e                	add	a2,a2,a1
    800016b6:	013679b3          	and	s3,a2,s3
  a = PGROUNDDOWN(va);
    800016ba:	8952                	mv	s2,s4
    800016bc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800016c0:	6b85                	lui	s7,0x1
    800016c2:	a811                	j	800016d6 <mappages+0x44>
      panic("remap");
    800016c4:	00007517          	auipc	a0,0x7
    800016c8:	ab450513          	addi	a0,a0,-1356 # 80008178 <digits+0x160>
    800016cc:	fffff097          	auipc	ra,0xfffff
    800016d0:	eac080e7          	jalr	-340(ra) # 80000578 <panic>
    a += PGSIZE;
    800016d4:	995e                	add	s2,s2,s7
  for(;;){
    800016d6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800016da:	4605                	li	a2,1
    800016dc:	85ca                	mv	a1,s2
    800016de:	8556                	mv	a0,s5
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	ea4080e7          	jalr	-348(ra) # 80001584 <walk>
    800016e8:	cd19                	beqz	a0,80001706 <mappages+0x74>
    if(*pte & PTE_V)
    800016ea:	611c                	ld	a5,0(a0)
    800016ec:	8b85                	andi	a5,a5,1
    800016ee:	fbf9                	bnez	a5,800016c4 <mappages+0x32>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800016f0:	80b1                	srli	s1,s1,0xc
    800016f2:	04aa                	slli	s1,s1,0xa
    800016f4:	0164e4b3          	or	s1,s1,s6
    800016f8:	0014e493          	ori	s1,s1,1
    800016fc:	e104                	sd	s1,0(a0)
    if(a == last)
    800016fe:	fd391be3          	bne	s2,s3,800016d4 <mappages+0x42>
    pa += PGSIZE;
  }
  return 0;
    80001702:	4501                	li	a0,0
    80001704:	a011                	j	80001708 <mappages+0x76>
      return -1;
    80001706:	557d                	li	a0,-1
}
    80001708:	60a6                	ld	ra,72(sp)
    8000170a:	6406                	ld	s0,64(sp)
    8000170c:	74e2                	ld	s1,56(sp)
    8000170e:	7942                	ld	s2,48(sp)
    80001710:	79a2                	ld	s3,40(sp)
    80001712:	7a02                	ld	s4,32(sp)
    80001714:	6ae2                	ld	s5,24(sp)
    80001716:	6b42                	ld	s6,16(sp)
    80001718:	6ba2                	ld	s7,8(sp)
    8000171a:	6161                	addi	sp,sp,80
    8000171c:	8082                	ret

000000008000171e <kvmmap>:
{
    8000171e:	1141                	addi	sp,sp,-16
    80001720:	e406                	sd	ra,8(sp)
    80001722:	e022                	sd	s0,0(sp)
    80001724:	0800                	addi	s0,sp,16
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001726:	8736                	mv	a4,a3
    80001728:	86ae                	mv	a3,a1
    8000172a:	85aa                	mv	a1,a0
    8000172c:	00008797          	auipc	a5,0x8
    80001730:	8e478793          	addi	a5,a5,-1820 # 80009010 <kernel_pagetable>
    80001734:	6388                	ld	a0,0(a5)
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	f5c080e7          	jalr	-164(ra) # 80001692 <mappages>
    8000173e:	e509                	bnez	a0,80001748 <kvmmap+0x2a>
}
    80001740:	60a2                	ld	ra,8(sp)
    80001742:	6402                	ld	s0,0(sp)
    80001744:	0141                	addi	sp,sp,16
    80001746:	8082                	ret
    panic("kvmmap");
    80001748:	00007517          	auipc	a0,0x7
    8000174c:	a3850513          	addi	a0,a0,-1480 # 80008180 <digits+0x168>
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	e28080e7          	jalr	-472(ra) # 80000578 <panic>

0000000080001758 <kvminit>:
{
    80001758:	1101                	addi	sp,sp,-32
    8000175a:	ec06                	sd	ra,24(sp)
    8000175c:	e822                	sd	s0,16(sp)
    8000175e:	e426                	sd	s1,8(sp)
    80001760:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	5f8080e7          	jalr	1528(ra) # 80000d5a <kalloc>
    8000176a:	00008797          	auipc	a5,0x8
    8000176e:	8aa7b323          	sd	a0,-1882(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001772:	6605                	lui	a2,0x1
    80001774:	4581                	li	a1,0
    80001776:	00000097          	auipc	ra,0x0
    8000177a:	b1c080e7          	jalr	-1252(ra) # 80001292 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000177e:	4699                	li	a3,6
    80001780:	6605                	lui	a2,0x1
    80001782:	100005b7          	lui	a1,0x10000
    80001786:	10000537          	lui	a0,0x10000
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	f94080e7          	jalr	-108(ra) # 8000171e <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001792:	4699                	li	a3,6
    80001794:	6605                	lui	a2,0x1
    80001796:	100015b7          	lui	a1,0x10001
    8000179a:	10001537          	lui	a0,0x10001
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	f80080e7          	jalr	-128(ra) # 8000171e <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800017a6:	4699                	li	a3,6
    800017a8:	00400637          	lui	a2,0x400
    800017ac:	0c0005b7          	lui	a1,0xc000
    800017b0:	0c000537          	lui	a0,0xc000
    800017b4:	00000097          	auipc	ra,0x0
    800017b8:	f6a080e7          	jalr	-150(ra) # 8000171e <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800017bc:	00007497          	auipc	s1,0x7
    800017c0:	84448493          	addi	s1,s1,-1980 # 80008000 <etext>
    800017c4:	46a9                	li	a3,10
    800017c6:	80007617          	auipc	a2,0x80007
    800017ca:	83a60613          	addi	a2,a2,-1990 # 8000 <_entry-0x7fff8000>
    800017ce:	4585                	li	a1,1
    800017d0:	05fe                	slli	a1,a1,0x1f
    800017d2:	852e                	mv	a0,a1
    800017d4:	00000097          	auipc	ra,0x0
    800017d8:	f4a080e7          	jalr	-182(ra) # 8000171e <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800017dc:	4699                	li	a3,6
    800017de:	4645                	li	a2,17
    800017e0:	066e                	slli	a2,a2,0x1b
    800017e2:	8e05                	sub	a2,a2,s1
    800017e4:	85a6                	mv	a1,s1
    800017e6:	8526                	mv	a0,s1
    800017e8:	00000097          	auipc	ra,0x0
    800017ec:	f36080e7          	jalr	-202(ra) # 8000171e <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800017f0:	46a9                	li	a3,10
    800017f2:	6605                	lui	a2,0x1
    800017f4:	00006597          	auipc	a1,0x6
    800017f8:	80c58593          	addi	a1,a1,-2036 # 80007000 <_trampoline>
    800017fc:	04000537          	lui	a0,0x4000
    80001800:	157d                	addi	a0,a0,-1
    80001802:	0532                	slli	a0,a0,0xc
    80001804:	00000097          	auipc	ra,0x0
    80001808:	f1a080e7          	jalr	-230(ra) # 8000171e <kvmmap>
}
    8000180c:	60e2                	ld	ra,24(sp)
    8000180e:	6442                	ld	s0,16(sp)
    80001810:	64a2                	ld	s1,8(sp)
    80001812:	6105                	addi	sp,sp,32
    80001814:	8082                	ret

0000000080001816 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001816:	715d                	addi	sp,sp,-80
    80001818:	e486                	sd	ra,72(sp)
    8000181a:	e0a2                	sd	s0,64(sp)
    8000181c:	fc26                	sd	s1,56(sp)
    8000181e:	f84a                	sd	s2,48(sp)
    80001820:	f44e                	sd	s3,40(sp)
    80001822:	f052                	sd	s4,32(sp)
    80001824:	ec56                	sd	s5,24(sp)
    80001826:	e85a                	sd	s6,16(sp)
    80001828:	e45e                	sd	s7,8(sp)
    8000182a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000182c:	6785                	lui	a5,0x1
    8000182e:	17fd                	addi	a5,a5,-1
    80001830:	8fed                	and	a5,a5,a1
    80001832:	e795                	bnez	a5,8000185e <uvmunmap+0x48>
    80001834:	8a2a                	mv	s4,a0
    80001836:	84ae                	mv	s1,a1
    80001838:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000183a:	0632                	slli	a2,a2,0xc
    8000183c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001840:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001842:	6b05                	lui	s6,0x1
    80001844:	0735e863          	bltu	a1,s3,800018b4 <uvmunmap+0x9e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001848:	60a6                	ld	ra,72(sp)
    8000184a:	6406                	ld	s0,64(sp)
    8000184c:	74e2                	ld	s1,56(sp)
    8000184e:	7942                	ld	s2,48(sp)
    80001850:	79a2                	ld	s3,40(sp)
    80001852:	7a02                	ld	s4,32(sp)
    80001854:	6ae2                	ld	s5,24(sp)
    80001856:	6b42                	ld	s6,16(sp)
    80001858:	6ba2                	ld	s7,8(sp)
    8000185a:	6161                	addi	sp,sp,80
    8000185c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000185e:	00007517          	auipc	a0,0x7
    80001862:	92a50513          	addi	a0,a0,-1750 # 80008188 <digits+0x170>
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	d12080e7          	jalr	-750(ra) # 80000578 <panic>
      panic("uvmunmap: walk");
    8000186e:	00007517          	auipc	a0,0x7
    80001872:	93250513          	addi	a0,a0,-1742 # 800081a0 <digits+0x188>
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	d02080e7          	jalr	-766(ra) # 80000578 <panic>
      panic("uvmunmap: not mapped");
    8000187e:	00007517          	auipc	a0,0x7
    80001882:	93250513          	addi	a0,a0,-1742 # 800081b0 <digits+0x198>
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	cf2080e7          	jalr	-782(ra) # 80000578 <panic>
      panic("uvmunmap: not a leaf");
    8000188e:	00007517          	auipc	a0,0x7
    80001892:	93a50513          	addi	a0,a0,-1734 # 800081c8 <digits+0x1b0>
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	ce2080e7          	jalr	-798(ra) # 80000578 <panic>
      uint64 pa = PTE2PA(*pte);
    8000189e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800018a0:	0532                	slli	a0,a0,0xc
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	3e0080e7          	jalr	992(ra) # 80000c82 <kfree>
    *pte = 0;
    800018aa:	00093023          	sd	zero,0(s2)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800018ae:	94da                	add	s1,s1,s6
    800018b0:	f934fce3          	bleu	s3,s1,80001848 <uvmunmap+0x32>
    if((pte = walk(pagetable, a, 0)) == 0)
    800018b4:	4601                	li	a2,0
    800018b6:	85a6                	mv	a1,s1
    800018b8:	8552                	mv	a0,s4
    800018ba:	00000097          	auipc	ra,0x0
    800018be:	cca080e7          	jalr	-822(ra) # 80001584 <walk>
    800018c2:	892a                	mv	s2,a0
    800018c4:	d54d                	beqz	a0,8000186e <uvmunmap+0x58>
    if((*pte & PTE_V) == 0)
    800018c6:	6108                	ld	a0,0(a0)
    800018c8:	00157793          	andi	a5,a0,1
    800018cc:	dbcd                	beqz	a5,8000187e <uvmunmap+0x68>
    if(PTE_FLAGS(*pte) == PTE_V)
    800018ce:	3ff57793          	andi	a5,a0,1023
    800018d2:	fb778ee3          	beq	a5,s7,8000188e <uvmunmap+0x78>
    if(do_free){
    800018d6:	fc0a8ae3          	beqz	s5,800018aa <uvmunmap+0x94>
    800018da:	b7d1                	j	8000189e <uvmunmap+0x88>

00000000800018dc <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800018dc:	1101                	addi	sp,sp,-32
    800018de:	ec06                	sd	ra,24(sp)
    800018e0:	e822                	sd	s0,16(sp)
    800018e2:	e426                	sd	s1,8(sp)
    800018e4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	474080e7          	jalr	1140(ra) # 80000d5a <kalloc>
    800018ee:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800018f0:	c519                	beqz	a0,800018fe <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800018f2:	6605                	lui	a2,0x1
    800018f4:	4581                	li	a1,0
    800018f6:	00000097          	auipc	ra,0x0
    800018fa:	99c080e7          	jalr	-1636(ra) # 80001292 <memset>
  return pagetable;
}
    800018fe:	8526                	mv	a0,s1
    80001900:	60e2                	ld	ra,24(sp)
    80001902:	6442                	ld	s0,16(sp)
    80001904:	64a2                	ld	s1,8(sp)
    80001906:	6105                	addi	sp,sp,32
    80001908:	8082                	ret

000000008000190a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000190a:	7179                	addi	sp,sp,-48
    8000190c:	f406                	sd	ra,40(sp)
    8000190e:	f022                	sd	s0,32(sp)
    80001910:	ec26                	sd	s1,24(sp)
    80001912:	e84a                	sd	s2,16(sp)
    80001914:	e44e                	sd	s3,8(sp)
    80001916:	e052                	sd	s4,0(sp)
    80001918:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000191a:	6785                	lui	a5,0x1
    8000191c:	04f67863          	bleu	a5,a2,8000196c <uvminit+0x62>
    80001920:	8a2a                	mv	s4,a0
    80001922:	89ae                	mv	s3,a1
    80001924:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	434080e7          	jalr	1076(ra) # 80000d5a <kalloc>
    8000192e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001930:	6605                	lui	a2,0x1
    80001932:	4581                	li	a1,0
    80001934:	00000097          	auipc	ra,0x0
    80001938:	95e080e7          	jalr	-1698(ra) # 80001292 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000193c:	4779                	li	a4,30
    8000193e:	86ca                	mv	a3,s2
    80001940:	6605                	lui	a2,0x1
    80001942:	4581                	li	a1,0
    80001944:	8552                	mv	a0,s4
    80001946:	00000097          	auipc	ra,0x0
    8000194a:	d4c080e7          	jalr	-692(ra) # 80001692 <mappages>
  memmove(mem, src, sz);
    8000194e:	8626                	mv	a2,s1
    80001950:	85ce                	mv	a1,s3
    80001952:	854a                	mv	a0,s2
    80001954:	00000097          	auipc	ra,0x0
    80001958:	9aa080e7          	jalr	-1622(ra) # 800012fe <memmove>
}
    8000195c:	70a2                	ld	ra,40(sp)
    8000195e:	7402                	ld	s0,32(sp)
    80001960:	64e2                	ld	s1,24(sp)
    80001962:	6942                	ld	s2,16(sp)
    80001964:	69a2                	ld	s3,8(sp)
    80001966:	6a02                	ld	s4,0(sp)
    80001968:	6145                	addi	sp,sp,48
    8000196a:	8082                	ret
    panic("inituvm: more than a page");
    8000196c:	00007517          	auipc	a0,0x7
    80001970:	87450513          	addi	a0,a0,-1932 # 800081e0 <digits+0x1c8>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	c04080e7          	jalr	-1020(ra) # 80000578 <panic>

000000008000197c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000197c:	1101                	addi	sp,sp,-32
    8000197e:	ec06                	sd	ra,24(sp)
    80001980:	e822                	sd	s0,16(sp)
    80001982:	e426                	sd	s1,8(sp)
    80001984:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001986:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001988:	00b67d63          	bleu	a1,a2,800019a2 <uvmdealloc+0x26>
    8000198c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000198e:	6605                	lui	a2,0x1
    80001990:	167d                	addi	a2,a2,-1
    80001992:	00c487b3          	add	a5,s1,a2
    80001996:	777d                	lui	a4,0xfffff
    80001998:	8ff9                	and	a5,a5,a4
    8000199a:	962e                	add	a2,a2,a1
    8000199c:	8e79                	and	a2,a2,a4
    8000199e:	00c7e863          	bltu	a5,a2,800019ae <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800019a2:	8526                	mv	a0,s1
    800019a4:	60e2                	ld	ra,24(sp)
    800019a6:	6442                	ld	s0,16(sp)
    800019a8:	64a2                	ld	s1,8(sp)
    800019aa:	6105                	addi	sp,sp,32
    800019ac:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800019ae:	8e1d                	sub	a2,a2,a5
    800019b0:	8231                	srli	a2,a2,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800019b2:	4685                	li	a3,1
    800019b4:	2601                	sext.w	a2,a2
    800019b6:	85be                	mv	a1,a5
    800019b8:	00000097          	auipc	ra,0x0
    800019bc:	e5e080e7          	jalr	-418(ra) # 80001816 <uvmunmap>
    800019c0:	b7cd                	j	800019a2 <uvmdealloc+0x26>

00000000800019c2 <uvmalloc>:
  if(newsz < oldsz)
    800019c2:	0ab66163          	bltu	a2,a1,80001a64 <uvmalloc+0xa2>
{
    800019c6:	7139                	addi	sp,sp,-64
    800019c8:	fc06                	sd	ra,56(sp)
    800019ca:	f822                	sd	s0,48(sp)
    800019cc:	f426                	sd	s1,40(sp)
    800019ce:	f04a                	sd	s2,32(sp)
    800019d0:	ec4e                	sd	s3,24(sp)
    800019d2:	e852                	sd	s4,16(sp)
    800019d4:	e456                	sd	s5,8(sp)
    800019d6:	0080                	addi	s0,sp,64
  oldsz = PGROUNDUP(oldsz);
    800019d8:	6a05                	lui	s4,0x1
    800019da:	1a7d                	addi	s4,s4,-1
    800019dc:	95d2                	add	a1,a1,s4
    800019de:	7a7d                	lui	s4,0xfffff
    800019e0:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    800019e4:	08ca7263          	bleu	a2,s4,80001a68 <uvmalloc+0xa6>
    800019e8:	89b2                	mv	s3,a2
    800019ea:	8aaa                	mv	s5,a0
    800019ec:	8952                	mv	s2,s4
    mem = kalloc();
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	36c080e7          	jalr	876(ra) # 80000d5a <kalloc>
    800019f6:	84aa                	mv	s1,a0
    if(mem == 0){
    800019f8:	c51d                	beqz	a0,80001a26 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800019fa:	6605                	lui	a2,0x1
    800019fc:	4581                	li	a1,0
    800019fe:	00000097          	auipc	ra,0x0
    80001a02:	894080e7          	jalr	-1900(ra) # 80001292 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001a06:	4779                	li	a4,30
    80001a08:	86a6                	mv	a3,s1
    80001a0a:	6605                	lui	a2,0x1
    80001a0c:	85ca                	mv	a1,s2
    80001a0e:	8556                	mv	a0,s5
    80001a10:	00000097          	auipc	ra,0x0
    80001a14:	c82080e7          	jalr	-894(ra) # 80001692 <mappages>
    80001a18:	e905                	bnez	a0,80001a48 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001a1a:	6785                	lui	a5,0x1
    80001a1c:	993e                	add	s2,s2,a5
    80001a1e:	fd3968e3          	bltu	s2,s3,800019ee <uvmalloc+0x2c>
  return newsz;
    80001a22:	854e                	mv	a0,s3
    80001a24:	a809                	j	80001a36 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001a26:	8652                	mv	a2,s4
    80001a28:	85ca                	mv	a1,s2
    80001a2a:	8556                	mv	a0,s5
    80001a2c:	00000097          	auipc	ra,0x0
    80001a30:	f50080e7          	jalr	-176(ra) # 8000197c <uvmdealloc>
      return 0;
    80001a34:	4501                	li	a0,0
}
    80001a36:	70e2                	ld	ra,56(sp)
    80001a38:	7442                	ld	s0,48(sp)
    80001a3a:	74a2                	ld	s1,40(sp)
    80001a3c:	7902                	ld	s2,32(sp)
    80001a3e:	69e2                	ld	s3,24(sp)
    80001a40:	6a42                	ld	s4,16(sp)
    80001a42:	6aa2                	ld	s5,8(sp)
    80001a44:	6121                	addi	sp,sp,64
    80001a46:	8082                	ret
      kfree(mem);
    80001a48:	8526                	mv	a0,s1
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	238080e7          	jalr	568(ra) # 80000c82 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001a52:	8652                	mv	a2,s4
    80001a54:	85ca                	mv	a1,s2
    80001a56:	8556                	mv	a0,s5
    80001a58:	00000097          	auipc	ra,0x0
    80001a5c:	f24080e7          	jalr	-220(ra) # 8000197c <uvmdealloc>
      return 0;
    80001a60:	4501                	li	a0,0
    80001a62:	bfd1                	j	80001a36 <uvmalloc+0x74>
    return oldsz;
    80001a64:	852e                	mv	a0,a1
}
    80001a66:	8082                	ret
  return newsz;
    80001a68:	8532                	mv	a0,a2
    80001a6a:	b7f1                	j	80001a36 <uvmalloc+0x74>

0000000080001a6c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001a6c:	7179                	addi	sp,sp,-48
    80001a6e:	f406                	sd	ra,40(sp)
    80001a70:	f022                	sd	s0,32(sp)
    80001a72:	ec26                	sd	s1,24(sp)
    80001a74:	e84a                	sd	s2,16(sp)
    80001a76:	e44e                	sd	s3,8(sp)
    80001a78:	e052                	sd	s4,0(sp)
    80001a7a:	1800                	addi	s0,sp,48
    80001a7c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001a7e:	84aa                	mv	s1,a0
    80001a80:	6905                	lui	s2,0x1
    80001a82:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001a84:	4985                	li	s3,1
    80001a86:	a821                	j	80001a9e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001a88:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001a8a:	0532                	slli	a0,a0,0xc
    80001a8c:	00000097          	auipc	ra,0x0
    80001a90:	fe0080e7          	jalr	-32(ra) # 80001a6c <freewalk>
      pagetable[i] = 0;
    80001a94:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001a98:	04a1                	addi	s1,s1,8
    80001a9a:	03248163          	beq	s1,s2,80001abc <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001a9e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001aa0:	00f57793          	andi	a5,a0,15
    80001aa4:	ff3782e3          	beq	a5,s3,80001a88 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001aa8:	8905                	andi	a0,a0,1
    80001aaa:	d57d                	beqz	a0,80001a98 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001aac:	00006517          	auipc	a0,0x6
    80001ab0:	75450513          	addi	a0,a0,1876 # 80008200 <digits+0x1e8>
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	ac4080e7          	jalr	-1340(ra) # 80000578 <panic>
    }
  }
  kfree((void*)pagetable);
    80001abc:	8552                	mv	a0,s4
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	1c4080e7          	jalr	452(ra) # 80000c82 <kfree>
}
    80001ac6:	70a2                	ld	ra,40(sp)
    80001ac8:	7402                	ld	s0,32(sp)
    80001aca:	64e2                	ld	s1,24(sp)
    80001acc:	6942                	ld	s2,16(sp)
    80001ace:	69a2                	ld	s3,8(sp)
    80001ad0:	6a02                	ld	s4,0(sp)
    80001ad2:	6145                	addi	sp,sp,48
    80001ad4:	8082                	ret

0000000080001ad6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001ad6:	1101                	addi	sp,sp,-32
    80001ad8:	ec06                	sd	ra,24(sp)
    80001ada:	e822                	sd	s0,16(sp)
    80001adc:	e426                	sd	s1,8(sp)
    80001ade:	1000                	addi	s0,sp,32
    80001ae0:	84aa                	mv	s1,a0
  if(sz > 0)
    80001ae2:	e999                	bnez	a1,80001af8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	00000097          	auipc	ra,0x0
    80001aea:	f86080e7          	jalr	-122(ra) # 80001a6c <freewalk>
}
    80001aee:	60e2                	ld	ra,24(sp)
    80001af0:	6442                	ld	s0,16(sp)
    80001af2:	64a2                	ld	s1,8(sp)
    80001af4:	6105                	addi	sp,sp,32
    80001af6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001af8:	6605                	lui	a2,0x1
    80001afa:	167d                	addi	a2,a2,-1
    80001afc:	962e                	add	a2,a2,a1
    80001afe:	4685                	li	a3,1
    80001b00:	8231                	srli	a2,a2,0xc
    80001b02:	4581                	li	a1,0
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	d12080e7          	jalr	-750(ra) # 80001816 <uvmunmap>
    80001b0c:	bfe1                	j	80001ae4 <uvmfree+0xe>

0000000080001b0e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001b0e:	c679                	beqz	a2,80001bdc <uvmcopy+0xce>
{
    80001b10:	715d                	addi	sp,sp,-80
    80001b12:	e486                	sd	ra,72(sp)
    80001b14:	e0a2                	sd	s0,64(sp)
    80001b16:	fc26                	sd	s1,56(sp)
    80001b18:	f84a                	sd	s2,48(sp)
    80001b1a:	f44e                	sd	s3,40(sp)
    80001b1c:	f052                	sd	s4,32(sp)
    80001b1e:	ec56                	sd	s5,24(sp)
    80001b20:	e85a                	sd	s6,16(sp)
    80001b22:	e45e                	sd	s7,8(sp)
    80001b24:	0880                	addi	s0,sp,80
    80001b26:	8ab2                	mv	s5,a2
    80001b28:	8b2e                	mv	s6,a1
    80001b2a:	8baa                	mv	s7,a0
  for(i = 0; i < sz; i += PGSIZE){
    80001b2c:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    80001b2e:	4601                	li	a2,0
    80001b30:	85ca                	mv	a1,s2
    80001b32:	855e                	mv	a0,s7
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	a50080e7          	jalr	-1456(ra) # 80001584 <walk>
    80001b3c:	c531                	beqz	a0,80001b88 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001b3e:	6118                	ld	a4,0(a0)
    80001b40:	00177793          	andi	a5,a4,1
    80001b44:	cbb1                	beqz	a5,80001b98 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001b46:	00a75593          	srli	a1,a4,0xa
    80001b4a:	00c59993          	slli	s3,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001b4e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	208080e7          	jalr	520(ra) # 80000d5a <kalloc>
    80001b5a:	8a2a                	mv	s4,a0
    80001b5c:	c939                	beqz	a0,80001bb2 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001b5e:	6605                	lui	a2,0x1
    80001b60:	85ce                	mv	a1,s3
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	79c080e7          	jalr	1948(ra) # 800012fe <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001b6a:	8726                	mv	a4,s1
    80001b6c:	86d2                	mv	a3,s4
    80001b6e:	6605                	lui	a2,0x1
    80001b70:	85ca                	mv	a1,s2
    80001b72:	855a                	mv	a0,s6
    80001b74:	00000097          	auipc	ra,0x0
    80001b78:	b1e080e7          	jalr	-1250(ra) # 80001692 <mappages>
    80001b7c:	e515                	bnez	a0,80001ba8 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001b7e:	6785                	lui	a5,0x1
    80001b80:	993e                	add	s2,s2,a5
    80001b82:	fb5966e3          	bltu	s2,s5,80001b2e <uvmcopy+0x20>
    80001b86:	a081                	j	80001bc6 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001b88:	00006517          	auipc	a0,0x6
    80001b8c:	68850513          	addi	a0,a0,1672 # 80008210 <digits+0x1f8>
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	9e8080e7          	jalr	-1560(ra) # 80000578 <panic>
      panic("uvmcopy: page not present");
    80001b98:	00006517          	auipc	a0,0x6
    80001b9c:	69850513          	addi	a0,a0,1688 # 80008230 <digits+0x218>
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	9d8080e7          	jalr	-1576(ra) # 80000578 <panic>
      kfree(mem);
    80001ba8:	8552                	mv	a0,s4
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	0d8080e7          	jalr	216(ra) # 80000c82 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001bb2:	4685                	li	a3,1
    80001bb4:	00c95613          	srli	a2,s2,0xc
    80001bb8:	4581                	li	a1,0
    80001bba:	855a                	mv	a0,s6
    80001bbc:	00000097          	auipc	ra,0x0
    80001bc0:	c5a080e7          	jalr	-934(ra) # 80001816 <uvmunmap>
  return -1;
    80001bc4:	557d                	li	a0,-1
}
    80001bc6:	60a6                	ld	ra,72(sp)
    80001bc8:	6406                	ld	s0,64(sp)
    80001bca:	74e2                	ld	s1,56(sp)
    80001bcc:	7942                	ld	s2,48(sp)
    80001bce:	79a2                	ld	s3,40(sp)
    80001bd0:	7a02                	ld	s4,32(sp)
    80001bd2:	6ae2                	ld	s5,24(sp)
    80001bd4:	6b42                	ld	s6,16(sp)
    80001bd6:	6ba2                	ld	s7,8(sp)
    80001bd8:	6161                	addi	sp,sp,80
    80001bda:	8082                	ret
  return 0;
    80001bdc:	4501                	li	a0,0
}
    80001bde:	8082                	ret

0000000080001be0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001be0:	1141                	addi	sp,sp,-16
    80001be2:	e406                	sd	ra,8(sp)
    80001be4:	e022                	sd	s0,0(sp)
    80001be6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001be8:	4601                	li	a2,0
    80001bea:	00000097          	auipc	ra,0x0
    80001bee:	99a080e7          	jalr	-1638(ra) # 80001584 <walk>
  if(pte == 0)
    80001bf2:	c901                	beqz	a0,80001c02 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001bf4:	611c                	ld	a5,0(a0)
    80001bf6:	9bbd                	andi	a5,a5,-17
    80001bf8:	e11c                	sd	a5,0(a0)
}
    80001bfa:	60a2                	ld	ra,8(sp)
    80001bfc:	6402                	ld	s0,0(sp)
    80001bfe:	0141                	addi	sp,sp,16
    80001c00:	8082                	ret
    panic("uvmclear");
    80001c02:	00006517          	auipc	a0,0x6
    80001c06:	64e50513          	addi	a0,a0,1614 # 80008250 <digits+0x238>
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	96e080e7          	jalr	-1682(ra) # 80000578 <panic>

0000000080001c12 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001c12:	c6bd                	beqz	a3,80001c80 <copyout+0x6e>
{
    80001c14:	715d                	addi	sp,sp,-80
    80001c16:	e486                	sd	ra,72(sp)
    80001c18:	e0a2                	sd	s0,64(sp)
    80001c1a:	fc26                	sd	s1,56(sp)
    80001c1c:	f84a                	sd	s2,48(sp)
    80001c1e:	f44e                	sd	s3,40(sp)
    80001c20:	f052                	sd	s4,32(sp)
    80001c22:	ec56                	sd	s5,24(sp)
    80001c24:	e85a                	sd	s6,16(sp)
    80001c26:	e45e                	sd	s7,8(sp)
    80001c28:	e062                	sd	s8,0(sp)
    80001c2a:	0880                	addi	s0,sp,80
    80001c2c:	8baa                	mv	s7,a0
    80001c2e:	8a2e                	mv	s4,a1
    80001c30:	8ab2                	mv	s5,a2
    80001c32:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001c34:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001c36:	6b05                	lui	s6,0x1
    80001c38:	a015                	j	80001c5c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001c3a:	9552                	add	a0,a0,s4
    80001c3c:	0004861b          	sext.w	a2,s1
    80001c40:	85d6                	mv	a1,s5
    80001c42:	41250533          	sub	a0,a0,s2
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	6b8080e7          	jalr	1720(ra) # 800012fe <memmove>

    len -= n;
    80001c4e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001c52:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    80001c54:	01690a33          	add	s4,s2,s6
  while(len > 0){
    80001c58:	02098263          	beqz	s3,80001c7c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001c5c:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    80001c60:	85ca                	mv	a1,s2
    80001c62:	855e                	mv	a0,s7
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	9ec080e7          	jalr	-1556(ra) # 80001650 <walkaddr>
    if(pa0 == 0)
    80001c6c:	cd01                	beqz	a0,80001c84 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001c6e:	414904b3          	sub	s1,s2,s4
    80001c72:	94da                	add	s1,s1,s6
    if(n > len)
    80001c74:	fc99f3e3          	bleu	s1,s3,80001c3a <copyout+0x28>
    80001c78:	84ce                	mv	s1,s3
    80001c7a:	b7c1                	j	80001c3a <copyout+0x28>
  }
  return 0;
    80001c7c:	4501                	li	a0,0
    80001c7e:	a021                	j	80001c86 <copyout+0x74>
    80001c80:	4501                	li	a0,0
}
    80001c82:	8082                	ret
      return -1;
    80001c84:	557d                	li	a0,-1
}
    80001c86:	60a6                	ld	ra,72(sp)
    80001c88:	6406                	ld	s0,64(sp)
    80001c8a:	74e2                	ld	s1,56(sp)
    80001c8c:	7942                	ld	s2,48(sp)
    80001c8e:	79a2                	ld	s3,40(sp)
    80001c90:	7a02                	ld	s4,32(sp)
    80001c92:	6ae2                	ld	s5,24(sp)
    80001c94:	6b42                	ld	s6,16(sp)
    80001c96:	6ba2                	ld	s7,8(sp)
    80001c98:	6c02                	ld	s8,0(sp)
    80001c9a:	6161                	addi	sp,sp,80
    80001c9c:	8082                	ret

0000000080001c9e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001c9e:	caa5                	beqz	a3,80001d0e <copyin+0x70>
{
    80001ca0:	715d                	addi	sp,sp,-80
    80001ca2:	e486                	sd	ra,72(sp)
    80001ca4:	e0a2                	sd	s0,64(sp)
    80001ca6:	fc26                	sd	s1,56(sp)
    80001ca8:	f84a                	sd	s2,48(sp)
    80001caa:	f44e                	sd	s3,40(sp)
    80001cac:	f052                	sd	s4,32(sp)
    80001cae:	ec56                	sd	s5,24(sp)
    80001cb0:	e85a                	sd	s6,16(sp)
    80001cb2:	e45e                	sd	s7,8(sp)
    80001cb4:	e062                	sd	s8,0(sp)
    80001cb6:	0880                	addi	s0,sp,80
    80001cb8:	8baa                	mv	s7,a0
    80001cba:	8aae                	mv	s5,a1
    80001cbc:	8a32                	mv	s4,a2
    80001cbe:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001cc0:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001cc2:	6b05                	lui	s6,0x1
    80001cc4:	a01d                	j	80001cea <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001cc6:	014505b3          	add	a1,a0,s4
    80001cca:	0004861b          	sext.w	a2,s1
    80001cce:	412585b3          	sub	a1,a1,s2
    80001cd2:	8556                	mv	a0,s5
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	62a080e7          	jalr	1578(ra) # 800012fe <memmove>

    len -= n;
    80001cdc:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001ce0:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001ce2:	01690a33          	add	s4,s2,s6
  while(len > 0){
    80001ce6:	02098263          	beqz	s3,80001d0a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001cea:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    80001cee:	85ca                	mv	a1,s2
    80001cf0:	855e                	mv	a0,s7
    80001cf2:	00000097          	auipc	ra,0x0
    80001cf6:	95e080e7          	jalr	-1698(ra) # 80001650 <walkaddr>
    if(pa0 == 0)
    80001cfa:	cd01                	beqz	a0,80001d12 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001cfc:	414904b3          	sub	s1,s2,s4
    80001d00:	94da                	add	s1,s1,s6
    if(n > len)
    80001d02:	fc99f2e3          	bleu	s1,s3,80001cc6 <copyin+0x28>
    80001d06:	84ce                	mv	s1,s3
    80001d08:	bf7d                	j	80001cc6 <copyin+0x28>
  }
  return 0;
    80001d0a:	4501                	li	a0,0
    80001d0c:	a021                	j	80001d14 <copyin+0x76>
    80001d0e:	4501                	li	a0,0
}
    80001d10:	8082                	ret
      return -1;
    80001d12:	557d                	li	a0,-1
}
    80001d14:	60a6                	ld	ra,72(sp)
    80001d16:	6406                	ld	s0,64(sp)
    80001d18:	74e2                	ld	s1,56(sp)
    80001d1a:	7942                	ld	s2,48(sp)
    80001d1c:	79a2                	ld	s3,40(sp)
    80001d1e:	7a02                	ld	s4,32(sp)
    80001d20:	6ae2                	ld	s5,24(sp)
    80001d22:	6b42                	ld	s6,16(sp)
    80001d24:	6ba2                	ld	s7,8(sp)
    80001d26:	6c02                	ld	s8,0(sp)
    80001d28:	6161                	addi	sp,sp,80
    80001d2a:	8082                	ret

0000000080001d2c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001d2c:	ced5                	beqz	a3,80001de8 <copyinstr+0xbc>
{
    80001d2e:	715d                	addi	sp,sp,-80
    80001d30:	e486                	sd	ra,72(sp)
    80001d32:	e0a2                	sd	s0,64(sp)
    80001d34:	fc26                	sd	s1,56(sp)
    80001d36:	f84a                	sd	s2,48(sp)
    80001d38:	f44e                	sd	s3,40(sp)
    80001d3a:	f052                	sd	s4,32(sp)
    80001d3c:	ec56                	sd	s5,24(sp)
    80001d3e:	e85a                	sd	s6,16(sp)
    80001d40:	e45e                	sd	s7,8(sp)
    80001d42:	e062                	sd	s8,0(sp)
    80001d44:	0880                	addi	s0,sp,80
    80001d46:	8aaa                	mv	s5,a0
    80001d48:	84ae                	mv	s1,a1
    80001d4a:	8c32                	mv	s8,a2
    80001d4c:	8bb6                	mv	s7,a3
    va0 = PGROUNDDOWN(srcva);
    80001d4e:	7a7d                	lui	s4,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001d50:	6985                	lui	s3,0x1
    80001d52:	4b05                	li	s6,1
    80001d54:	a801                	j	80001d64 <copyinstr+0x38>
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
    80001d56:	87a6                	mv	a5,s1
    80001d58:	a085                	j	80001db8 <copyinstr+0x8c>
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    80001d5a:	84b2                	mv	s1,a2
    }

    srcva = va0 + PGSIZE;
    80001d5c:	01390c33          	add	s8,s2,s3
  while(got_null == 0 && max > 0){
    80001d60:	080b8063          	beqz	s7,80001de0 <copyinstr+0xb4>
    va0 = PGROUNDDOWN(srcva);
    80001d64:	014c7933          	and	s2,s8,s4
    pa0 = walkaddr(pagetable, va0);
    80001d68:	85ca                	mv	a1,s2
    80001d6a:	8556                	mv	a0,s5
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	8e4080e7          	jalr	-1820(ra) # 80001650 <walkaddr>
    if(pa0 == 0)
    80001d74:	c925                	beqz	a0,80001de4 <copyinstr+0xb8>
    n = PGSIZE - (srcva - va0);
    80001d76:	41890633          	sub	a2,s2,s8
    80001d7a:	964e                	add	a2,a2,s3
    if(n > max)
    80001d7c:	00cbf363          	bleu	a2,s7,80001d82 <copyinstr+0x56>
    80001d80:	865e                	mv	a2,s7
    char *p = (char *) (pa0 + (srcva - va0));
    80001d82:	9562                	add	a0,a0,s8
    80001d84:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001d88:	da71                	beqz	a2,80001d5c <copyinstr+0x30>
      if(*p == '\0'){
    80001d8a:	00054703          	lbu	a4,0(a0)
    80001d8e:	d761                	beqz	a4,80001d56 <copyinstr+0x2a>
    80001d90:	9626                	add	a2,a2,s1
    80001d92:	87a6                	mv	a5,s1
    80001d94:	1bfd                	addi	s7,s7,-1
    80001d96:	009b86b3          	add	a3,s7,s1
    80001d9a:	409b04b3          	sub	s1,s6,s1
    80001d9e:	94aa                	add	s1,s1,a0
        *dst = *p;
    80001da0:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      --max;
    80001da4:	40f68bb3          	sub	s7,a3,a5
      p++;
    80001da8:	00f48733          	add	a4,s1,a5
      dst++;
    80001dac:	0785                	addi	a5,a5,1
    while(n > 0){
    80001dae:	faf606e3          	beq	a2,a5,80001d5a <copyinstr+0x2e>
      if(*p == '\0'){
    80001db2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffa2fd8>
    80001db6:	f76d                	bnez	a4,80001da0 <copyinstr+0x74>
        *dst = '\0';
    80001db8:	00078023          	sb	zero,0(a5)
    80001dbc:	4785                	li	a5,1
  }
  if(got_null){
    80001dbe:	0017b513          	seqz	a0,a5
    80001dc2:	40a0053b          	negw	a0,a0
    80001dc6:	2501                	sext.w	a0,a0
    return 0;
  } else {
    return -1;
  }
}
    80001dc8:	60a6                	ld	ra,72(sp)
    80001dca:	6406                	ld	s0,64(sp)
    80001dcc:	74e2                	ld	s1,56(sp)
    80001dce:	7942                	ld	s2,48(sp)
    80001dd0:	79a2                	ld	s3,40(sp)
    80001dd2:	7a02                	ld	s4,32(sp)
    80001dd4:	6ae2                	ld	s5,24(sp)
    80001dd6:	6b42                	ld	s6,16(sp)
    80001dd8:	6ba2                	ld	s7,8(sp)
    80001dda:	6c02                	ld	s8,0(sp)
    80001ddc:	6161                	addi	sp,sp,80
    80001dde:	8082                	ret
    80001de0:	4781                	li	a5,0
    80001de2:	bff1                	j	80001dbe <copyinstr+0x92>
      return -1;
    80001de4:	557d                	li	a0,-1
    80001de6:	b7cd                	j	80001dc8 <copyinstr+0x9c>
  int got_null = 0;
    80001de8:	4781                	li	a5,0
  if(got_null){
    80001dea:	0017b513          	seqz	a0,a5
    80001dee:	40a0053b          	negw	a0,a0
    80001df2:	2501                	sext.w	a0,a0
}
    80001df4:	8082                	ret

0000000080001df6 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001df6:	1101                	addi	sp,sp,-32
    80001df8:	ec06                	sd	ra,24(sp)
    80001dfa:	e822                	sd	s0,16(sp)
    80001dfc:	e426                	sd	s1,8(sp)
    80001dfe:	1000                	addi	s0,sp,32
    80001e00:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	00a080e7          	jalr	10(ra) # 80000e0c <holding>
    80001e0a:	c909                	beqz	a0,80001e1c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001e0c:	789c                	ld	a5,48(s1)
    80001e0e:	00978f63          	beq	a5,s1,80001e2c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001e12:	60e2                	ld	ra,24(sp)
    80001e14:	6442                	ld	s0,16(sp)
    80001e16:	64a2                	ld	s1,8(sp)
    80001e18:	6105                	addi	sp,sp,32
    80001e1a:	8082                	ret
    panic("wakeup1");
    80001e1c:	00006517          	auipc	a0,0x6
    80001e20:	46c50513          	addi	a0,a0,1132 # 80008288 <states.1732+0x28>
    80001e24:	ffffe097          	auipc	ra,0xffffe
    80001e28:	754080e7          	jalr	1876(ra) # 80000578 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001e2c:	5098                	lw	a4,32(s1)
    80001e2e:	4785                	li	a5,1
    80001e30:	fef711e3          	bne	a4,a5,80001e12 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001e34:	4789                	li	a5,2
    80001e36:	d09c                	sw	a5,32(s1)
}
    80001e38:	bfe9                	j	80001e12 <wakeup1+0x1c>

0000000080001e3a <procinit>:
{
    80001e3a:	715d                	addi	sp,sp,-80
    80001e3c:	e486                	sd	ra,72(sp)
    80001e3e:	e0a2                	sd	s0,64(sp)
    80001e40:	fc26                	sd	s1,56(sp)
    80001e42:	f84a                	sd	s2,48(sp)
    80001e44:	f44e                	sd	s3,40(sp)
    80001e46:	f052                	sd	s4,32(sp)
    80001e48:	ec56                	sd	s5,24(sp)
    80001e4a:	e85a                	sd	s6,16(sp)
    80001e4c:	e45e                	sd	s7,8(sp)
    80001e4e:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001e50:	00006597          	auipc	a1,0x6
    80001e54:	44058593          	addi	a1,a1,1088 # 80008290 <states.1732+0x30>
    80001e58:	00010517          	auipc	a0,0x10
    80001e5c:	58050513          	addi	a0,a0,1408 # 800123d8 <pid_lock>
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	1b2080e7          	jalr	434(ra) # 80001012 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e68:	00011917          	auipc	s2,0x11
    80001e6c:	99090913          	addi	s2,s2,-1648 # 800127f8 <proc>
      initlock(&p->lock, "proc");
    80001e70:	00006b97          	auipc	s7,0x6
    80001e74:	428b8b93          	addi	s7,s7,1064 # 80008298 <states.1732+0x38>
      uint64 va = KSTACK((int) (p - proc));
    80001e78:	8b4a                	mv	s6,s2
    80001e7a:	00006a97          	auipc	s5,0x6
    80001e7e:	186a8a93          	addi	s5,s5,390 # 80008000 <etext>
    80001e82:	040009b7          	lui	s3,0x4000
    80001e86:	19fd                	addi	s3,s3,-1
    80001e88:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e8a:	00016a17          	auipc	s4,0x16
    80001e8e:	56ea0a13          	addi	s4,s4,1390 # 800183f8 <tickslock>
      initlock(&p->lock, "proc");
    80001e92:	85de                	mv	a1,s7
    80001e94:	854a                	mv	a0,s2
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	17c080e7          	jalr	380(ra) # 80001012 <initlock>
      char *pa = kalloc();
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	ebc080e7          	jalr	-324(ra) # 80000d5a <kalloc>
    80001ea6:	85aa                	mv	a1,a0
      if(pa == 0)
    80001ea8:	c929                	beqz	a0,80001efa <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001eaa:	416904b3          	sub	s1,s2,s6
    80001eae:	8491                	srai	s1,s1,0x4
    80001eb0:	000ab783          	ld	a5,0(s5)
    80001eb4:	02f484b3          	mul	s1,s1,a5
    80001eb8:	2485                	addiw	s1,s1,1
    80001eba:	00d4949b          	slliw	s1,s1,0xd
    80001ebe:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ec2:	4699                	li	a3,6
    80001ec4:	6605                	lui	a2,0x1
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	856080e7          	jalr	-1962(ra) # 8000171e <kvmmap>
      p->kstack = va;
    80001ed0:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ed4:	17090913          	addi	s2,s2,368
    80001ed8:	fb491de3          	bne	s2,s4,80001e92 <procinit+0x58>
  kvminithart();
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	74e080e7          	jalr	1870(ra) # 8000162a <kvminithart>
}
    80001ee4:	60a6                	ld	ra,72(sp)
    80001ee6:	6406                	ld	s0,64(sp)
    80001ee8:	74e2                	ld	s1,56(sp)
    80001eea:	7942                	ld	s2,48(sp)
    80001eec:	79a2                	ld	s3,40(sp)
    80001eee:	7a02                	ld	s4,32(sp)
    80001ef0:	6ae2                	ld	s5,24(sp)
    80001ef2:	6b42                	ld	s6,16(sp)
    80001ef4:	6ba2                	ld	s7,8(sp)
    80001ef6:	6161                	addi	sp,sp,80
    80001ef8:	8082                	ret
        panic("kalloc");
    80001efa:	00006517          	auipc	a0,0x6
    80001efe:	3a650513          	addi	a0,a0,934 # 800082a0 <states.1732+0x40>
    80001f02:	ffffe097          	auipc	ra,0xffffe
    80001f06:	676080e7          	jalr	1654(ra) # 80000578 <panic>

0000000080001f0a <cpuid>:
{
    80001f0a:	1141                	addi	sp,sp,-16
    80001f0c:	e422                	sd	s0,8(sp)
    80001f0e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f10:	8512                	mv	a0,tp
}
    80001f12:	2501                	sext.w	a0,a0
    80001f14:	6422                	ld	s0,8(sp)
    80001f16:	0141                	addi	sp,sp,16
    80001f18:	8082                	ret

0000000080001f1a <mycpu>:
mycpu(void) {
    80001f1a:	1141                	addi	sp,sp,-16
    80001f1c:	e422                	sd	s0,8(sp)
    80001f1e:	0800                	addi	s0,sp,16
    80001f20:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001f22:	2781                	sext.w	a5,a5
    80001f24:	079e                	slli	a5,a5,0x7
}
    80001f26:	00010517          	auipc	a0,0x10
    80001f2a:	4d250513          	addi	a0,a0,1234 # 800123f8 <cpus>
    80001f2e:	953e                	add	a0,a0,a5
    80001f30:	6422                	ld	s0,8(sp)
    80001f32:	0141                	addi	sp,sp,16
    80001f34:	8082                	ret

0000000080001f36 <myproc>:
myproc(void) {
    80001f36:	1101                	addi	sp,sp,-32
    80001f38:	ec06                	sd	ra,24(sp)
    80001f3a:	e822                	sd	s0,16(sp)
    80001f3c:	e426                	sd	s1,8(sp)
    80001f3e:	1000                	addi	s0,sp,32
  push_off();
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	efa080e7          	jalr	-262(ra) # 80000e3a <push_off>
    80001f48:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001f4a:	2781                	sext.w	a5,a5
    80001f4c:	079e                	slli	a5,a5,0x7
    80001f4e:	00010717          	auipc	a4,0x10
    80001f52:	48a70713          	addi	a4,a4,1162 # 800123d8 <pid_lock>
    80001f56:	97ba                	add	a5,a5,a4
    80001f58:	7384                	ld	s1,32(a5)
  pop_off();
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	f9c080e7          	jalr	-100(ra) # 80000ef6 <pop_off>
}
    80001f62:	8526                	mv	a0,s1
    80001f64:	60e2                	ld	ra,24(sp)
    80001f66:	6442                	ld	s0,16(sp)
    80001f68:	64a2                	ld	s1,8(sp)
    80001f6a:	6105                	addi	sp,sp,32
    80001f6c:	8082                	ret

0000000080001f6e <forkret>:
{
    80001f6e:	1141                	addi	sp,sp,-16
    80001f70:	e406                	sd	ra,8(sp)
    80001f72:	e022                	sd	s0,0(sp)
    80001f74:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	fc0080e7          	jalr	-64(ra) # 80001f36 <myproc>
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	fd8080e7          	jalr	-40(ra) # 80000f56 <release>
  if (first) {
    80001f86:	00007797          	auipc	a5,0x7
    80001f8a:	93a78793          	addi	a5,a5,-1734 # 800088c0 <first.1692>
    80001f8e:	439c                	lw	a5,0(a5)
    80001f90:	eb89                	bnez	a5,80001fa2 <forkret+0x34>
  usertrapret();
    80001f92:	00001097          	auipc	ra,0x1
    80001f96:	c26080e7          	jalr	-986(ra) # 80002bb8 <usertrapret>
}
    80001f9a:	60a2                	ld	ra,8(sp)
    80001f9c:	6402                	ld	s0,0(sp)
    80001f9e:	0141                	addi	sp,sp,16
    80001fa0:	8082                	ret
    first = 0;
    80001fa2:	00007797          	auipc	a5,0x7
    80001fa6:	9007af23          	sw	zero,-1762(a5) # 800088c0 <first.1692>
    fsinit(ROOTDEV);
    80001faa:	4505                	li	a0,1
    80001fac:	00002097          	auipc	ra,0x2
    80001fb0:	ac4080e7          	jalr	-1340(ra) # 80003a70 <fsinit>
    80001fb4:	bff9                	j	80001f92 <forkret+0x24>

0000000080001fb6 <allocpid>:
allocpid() {
    80001fb6:	1101                	addi	sp,sp,-32
    80001fb8:	ec06                	sd	ra,24(sp)
    80001fba:	e822                	sd	s0,16(sp)
    80001fbc:	e426                	sd	s1,8(sp)
    80001fbe:	e04a                	sd	s2,0(sp)
    80001fc0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001fc2:	00010917          	auipc	s2,0x10
    80001fc6:	41690913          	addi	s2,s2,1046 # 800123d8 <pid_lock>
    80001fca:	854a                	mv	a0,s2
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	eba080e7          	jalr	-326(ra) # 80000e86 <acquire>
  pid = nextpid;
    80001fd4:	00007797          	auipc	a5,0x7
    80001fd8:	8f078793          	addi	a5,a5,-1808 # 800088c4 <nextpid>
    80001fdc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001fde:	0014871b          	addiw	a4,s1,1
    80001fe2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001fe4:	854a                	mv	a0,s2
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	f70080e7          	jalr	-144(ra) # 80000f56 <release>
}
    80001fee:	8526                	mv	a0,s1
    80001ff0:	60e2                	ld	ra,24(sp)
    80001ff2:	6442                	ld	s0,16(sp)
    80001ff4:	64a2                	ld	s1,8(sp)
    80001ff6:	6902                	ld	s2,0(sp)
    80001ff8:	6105                	addi	sp,sp,32
    80001ffa:	8082                	ret

0000000080001ffc <proc_pagetable>:
{
    80001ffc:	1101                	addi	sp,sp,-32
    80001ffe:	ec06                	sd	ra,24(sp)
    80002000:	e822                	sd	s0,16(sp)
    80002002:	e426                	sd	s1,8(sp)
    80002004:	e04a                	sd	s2,0(sp)
    80002006:	1000                	addi	s0,sp,32
    80002008:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	8d2080e7          	jalr	-1838(ra) # 800018dc <uvmcreate>
    80002012:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80002014:	c121                	beqz	a0,80002054 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80002016:	4729                	li	a4,10
    80002018:	00005697          	auipc	a3,0x5
    8000201c:	fe868693          	addi	a3,a3,-24 # 80007000 <_trampoline>
    80002020:	6605                	lui	a2,0x1
    80002022:	040005b7          	lui	a1,0x4000
    80002026:	15fd                	addi	a1,a1,-1
    80002028:	05b2                	slli	a1,a1,0xc
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	668080e7          	jalr	1640(ra) # 80001692 <mappages>
    80002032:	02054863          	bltz	a0,80002062 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002036:	4719                	li	a4,6
    80002038:	06093683          	ld	a3,96(s2)
    8000203c:	6605                	lui	a2,0x1
    8000203e:	020005b7          	lui	a1,0x2000
    80002042:	15fd                	addi	a1,a1,-1
    80002044:	05b6                	slli	a1,a1,0xd
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	64a080e7          	jalr	1610(ra) # 80001692 <mappages>
    80002050:	02054163          	bltz	a0,80002072 <proc_pagetable+0x76>
}
    80002054:	8526                	mv	a0,s1
    80002056:	60e2                	ld	ra,24(sp)
    80002058:	6442                	ld	s0,16(sp)
    8000205a:	64a2                	ld	s1,8(sp)
    8000205c:	6902                	ld	s2,0(sp)
    8000205e:	6105                	addi	sp,sp,32
    80002060:	8082                	ret
    uvmfree(pagetable, 0);
    80002062:	4581                	li	a1,0
    80002064:	8526                	mv	a0,s1
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	a70080e7          	jalr	-1424(ra) # 80001ad6 <uvmfree>
    return 0;
    8000206e:	4481                	li	s1,0
    80002070:	b7d5                	j	80002054 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002072:	4681                	li	a3,0
    80002074:	4605                	li	a2,1
    80002076:	040005b7          	lui	a1,0x4000
    8000207a:	15fd                	addi	a1,a1,-1
    8000207c:	05b2                	slli	a1,a1,0xc
    8000207e:	8526                	mv	a0,s1
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	796080e7          	jalr	1942(ra) # 80001816 <uvmunmap>
    uvmfree(pagetable, 0);
    80002088:	4581                	li	a1,0
    8000208a:	8526                	mv	a0,s1
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	a4a080e7          	jalr	-1462(ra) # 80001ad6 <uvmfree>
    return 0;
    80002094:	4481                	li	s1,0
    80002096:	bf7d                	j	80002054 <proc_pagetable+0x58>

0000000080002098 <proc_freepagetable>:
{
    80002098:	1101                	addi	sp,sp,-32
    8000209a:	ec06                	sd	ra,24(sp)
    8000209c:	e822                	sd	s0,16(sp)
    8000209e:	e426                	sd	s1,8(sp)
    800020a0:	e04a                	sd	s2,0(sp)
    800020a2:	1000                	addi	s0,sp,32
    800020a4:	84aa                	mv	s1,a0
    800020a6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800020a8:	4681                	li	a3,0
    800020aa:	4605                	li	a2,1
    800020ac:	040005b7          	lui	a1,0x4000
    800020b0:	15fd                	addi	a1,a1,-1
    800020b2:	05b2                	slli	a1,a1,0xc
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	762080e7          	jalr	1890(ra) # 80001816 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800020bc:	4681                	li	a3,0
    800020be:	4605                	li	a2,1
    800020c0:	020005b7          	lui	a1,0x2000
    800020c4:	15fd                	addi	a1,a1,-1
    800020c6:	05b6                	slli	a1,a1,0xd
    800020c8:	8526                	mv	a0,s1
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	74c080e7          	jalr	1868(ra) # 80001816 <uvmunmap>
  uvmfree(pagetable, sz);
    800020d2:	85ca                	mv	a1,s2
    800020d4:	8526                	mv	a0,s1
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	a00080e7          	jalr	-1536(ra) # 80001ad6 <uvmfree>
}
    800020de:	60e2                	ld	ra,24(sp)
    800020e0:	6442                	ld	s0,16(sp)
    800020e2:	64a2                	ld	s1,8(sp)
    800020e4:	6902                	ld	s2,0(sp)
    800020e6:	6105                	addi	sp,sp,32
    800020e8:	8082                	ret

00000000800020ea <freeproc>:
{
    800020ea:	1101                	addi	sp,sp,-32
    800020ec:	ec06                	sd	ra,24(sp)
    800020ee:	e822                	sd	s0,16(sp)
    800020f0:	e426                	sd	s1,8(sp)
    800020f2:	1000                	addi	s0,sp,32
    800020f4:	84aa                	mv	s1,a0
  if(p->trapframe)
    800020f6:	7128                	ld	a0,96(a0)
    800020f8:	c509                	beqz	a0,80002102 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	b88080e7          	jalr	-1144(ra) # 80000c82 <kfree>
  p->trapframe = 0;
    80002102:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80002106:	6ca8                	ld	a0,88(s1)
    80002108:	c511                	beqz	a0,80002114 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    8000210a:	68ac                	ld	a1,80(s1)
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	f8c080e7          	jalr	-116(ra) # 80002098 <proc_freepagetable>
  p->pagetable = 0;
    80002114:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80002118:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    8000211c:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80002120:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80002124:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80002128:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    8000212c:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80002130:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80002134:	0204a023          	sw	zero,32(s1)
}
    80002138:	60e2                	ld	ra,24(sp)
    8000213a:	6442                	ld	s0,16(sp)
    8000213c:	64a2                	ld	s1,8(sp)
    8000213e:	6105                	addi	sp,sp,32
    80002140:	8082                	ret

0000000080002142 <allocproc>:
{
    80002142:	1101                	addi	sp,sp,-32
    80002144:	ec06                	sd	ra,24(sp)
    80002146:	e822                	sd	s0,16(sp)
    80002148:	e426                	sd	s1,8(sp)
    8000214a:	e04a                	sd	s2,0(sp)
    8000214c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    8000214e:	00010497          	auipc	s1,0x10
    80002152:	6aa48493          	addi	s1,s1,1706 # 800127f8 <proc>
    80002156:	00016917          	auipc	s2,0x16
    8000215a:	2a290913          	addi	s2,s2,674 # 800183f8 <tickslock>
    acquire(&p->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	d26080e7          	jalr	-730(ra) # 80000e86 <acquire>
    if(p->state == UNUSED) {
    80002168:	509c                	lw	a5,32(s1)
    8000216a:	cf81                	beqz	a5,80002182 <allocproc+0x40>
      release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	de8080e7          	jalr	-536(ra) # 80000f56 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002176:	17048493          	addi	s1,s1,368
    8000217a:	ff2492e3          	bne	s1,s2,8000215e <allocproc+0x1c>
  return 0;
    8000217e:	4481                	li	s1,0
    80002180:	a0b9                	j	800021ce <allocproc+0x8c>
  p->pid = allocpid();
    80002182:	00000097          	auipc	ra,0x0
    80002186:	e34080e7          	jalr	-460(ra) # 80001fb6 <allocpid>
    8000218a:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	bce080e7          	jalr	-1074(ra) # 80000d5a <kalloc>
    80002194:	892a                	mv	s2,a0
    80002196:	f0a8                	sd	a0,96(s1)
    80002198:	c131                	beqz	a0,800021dc <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    8000219a:	8526                	mv	a0,s1
    8000219c:	00000097          	auipc	ra,0x0
    800021a0:	e60080e7          	jalr	-416(ra) # 80001ffc <proc_pagetable>
    800021a4:	892a                	mv	s2,a0
    800021a6:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    800021a8:	c129                	beqz	a0,800021ea <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    800021aa:	07000613          	li	a2,112
    800021ae:	4581                	li	a1,0
    800021b0:	06848513          	addi	a0,s1,104
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	0de080e7          	jalr	222(ra) # 80001292 <memset>
  p->context.ra = (uint64)forkret;
    800021bc:	00000797          	auipc	a5,0x0
    800021c0:	db278793          	addi	a5,a5,-590 # 80001f6e <forkret>
    800021c4:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    800021c6:	64bc                	ld	a5,72(s1)
    800021c8:	6705                	lui	a4,0x1
    800021ca:	97ba                	add	a5,a5,a4
    800021cc:	f8bc                	sd	a5,112(s1)
}
    800021ce:	8526                	mv	a0,s1
    800021d0:	60e2                	ld	ra,24(sp)
    800021d2:	6442                	ld	s0,16(sp)
    800021d4:	64a2                	ld	s1,8(sp)
    800021d6:	6902                	ld	s2,0(sp)
    800021d8:	6105                	addi	sp,sp,32
    800021da:	8082                	ret
    release(&p->lock);
    800021dc:	8526                	mv	a0,s1
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	d78080e7          	jalr	-648(ra) # 80000f56 <release>
    return 0;
    800021e6:	84ca                	mv	s1,s2
    800021e8:	b7dd                	j	800021ce <allocproc+0x8c>
    freeproc(p);
    800021ea:	8526                	mv	a0,s1
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	efe080e7          	jalr	-258(ra) # 800020ea <freeproc>
    release(&p->lock);
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	d60080e7          	jalr	-672(ra) # 80000f56 <release>
    return 0;
    800021fe:	84ca                	mv	s1,s2
    80002200:	b7f9                	j	800021ce <allocproc+0x8c>

0000000080002202 <userinit>:
{
    80002202:	1101                	addi	sp,sp,-32
    80002204:	ec06                	sd	ra,24(sp)
    80002206:	e822                	sd	s0,16(sp)
    80002208:	e426                	sd	s1,8(sp)
    8000220a:	1000                	addi	s0,sp,32
  p = allocproc();
    8000220c:	00000097          	auipc	ra,0x0
    80002210:	f36080e7          	jalr	-202(ra) # 80002142 <allocproc>
    80002214:	84aa                	mv	s1,a0
  initproc = p;
    80002216:	00007797          	auipc	a5,0x7
    8000221a:	e0a7b123          	sd	a0,-510(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000221e:	03400613          	li	a2,52
    80002222:	00006597          	auipc	a1,0x6
    80002226:	6ae58593          	addi	a1,a1,1710 # 800088d0 <initcode>
    8000222a:	6d28                	ld	a0,88(a0)
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	6de080e7          	jalr	1758(ra) # 8000190a <uvminit>
  p->sz = PGSIZE;
    80002234:	6785                	lui	a5,0x1
    80002236:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80002238:	70b8                	ld	a4,96(s1)
    8000223a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000223e:	70b8                	ld	a4,96(s1)
    80002240:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002242:	4641                	li	a2,16
    80002244:	00006597          	auipc	a1,0x6
    80002248:	06458593          	addi	a1,a1,100 # 800082a8 <states.1732+0x48>
    8000224c:	16048513          	addi	a0,s1,352
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	1ba080e7          	jalr	442(ra) # 8000140a <safestrcpy>
  p->cwd = namei("/");
    80002258:	00006517          	auipc	a0,0x6
    8000225c:	06050513          	addi	a0,a0,96 # 800082b8 <states.1732+0x58>
    80002260:	00002097          	auipc	ra,0x2
    80002264:	248080e7          	jalr	584(ra) # 800044a8 <namei>
    80002268:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    8000226c:	4789                	li	a5,2
    8000226e:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	ce4080e7          	jalr	-796(ra) # 80000f56 <release>
}
    8000227a:	60e2                	ld	ra,24(sp)
    8000227c:	6442                	ld	s0,16(sp)
    8000227e:	64a2                	ld	s1,8(sp)
    80002280:	6105                	addi	sp,sp,32
    80002282:	8082                	ret

0000000080002284 <growproc>:
{
    80002284:	1101                	addi	sp,sp,-32
    80002286:	ec06                	sd	ra,24(sp)
    80002288:	e822                	sd	s0,16(sp)
    8000228a:	e426                	sd	s1,8(sp)
    8000228c:	e04a                	sd	s2,0(sp)
    8000228e:	1000                	addi	s0,sp,32
    80002290:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002292:	00000097          	auipc	ra,0x0
    80002296:	ca4080e7          	jalr	-860(ra) # 80001f36 <myproc>
    8000229a:	892a                	mv	s2,a0
  sz = p->sz;
    8000229c:	692c                	ld	a1,80(a0)
    8000229e:	0005851b          	sext.w	a0,a1
  if(n > 0){
    800022a2:	00904f63          	bgtz	s1,800022c0 <growproc+0x3c>
  } else if(n < 0){
    800022a6:	0204cd63          	bltz	s1,800022e0 <growproc+0x5c>
  p->sz = sz;
    800022aa:	1502                	slli	a0,a0,0x20
    800022ac:	9101                	srli	a0,a0,0x20
    800022ae:	04a93823          	sd	a0,80(s2)
  return 0;
    800022b2:	4501                	li	a0,0
}
    800022b4:	60e2                	ld	ra,24(sp)
    800022b6:	6442                	ld	s0,16(sp)
    800022b8:	64a2                	ld	s1,8(sp)
    800022ba:	6902                	ld	s2,0(sp)
    800022bc:	6105                	addi	sp,sp,32
    800022be:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800022c0:	00a4863b          	addw	a2,s1,a0
    800022c4:	1602                	slli	a2,a2,0x20
    800022c6:	9201                	srli	a2,a2,0x20
    800022c8:	1582                	slli	a1,a1,0x20
    800022ca:	9181                	srli	a1,a1,0x20
    800022cc:	05893503          	ld	a0,88(s2)
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	6f2080e7          	jalr	1778(ra) # 800019c2 <uvmalloc>
    800022d8:	2501                	sext.w	a0,a0
    800022da:	f961                	bnez	a0,800022aa <growproc+0x26>
      return -1;
    800022dc:	557d                	li	a0,-1
    800022de:	bfd9                	j	800022b4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022e0:	00a4863b          	addw	a2,s1,a0
    800022e4:	1602                	slli	a2,a2,0x20
    800022e6:	9201                	srli	a2,a2,0x20
    800022e8:	1582                	slli	a1,a1,0x20
    800022ea:	9181                	srli	a1,a1,0x20
    800022ec:	05893503          	ld	a0,88(s2)
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	68c080e7          	jalr	1676(ra) # 8000197c <uvmdealloc>
    800022f8:	2501                	sext.w	a0,a0
    800022fa:	bf45                	j	800022aa <growproc+0x26>

00000000800022fc <fork>:
{
    800022fc:	7179                	addi	sp,sp,-48
    800022fe:	f406                	sd	ra,40(sp)
    80002300:	f022                	sd	s0,32(sp)
    80002302:	ec26                	sd	s1,24(sp)
    80002304:	e84a                	sd	s2,16(sp)
    80002306:	e44e                	sd	s3,8(sp)
    80002308:	e052                	sd	s4,0(sp)
    8000230a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000230c:	00000097          	auipc	ra,0x0
    80002310:	c2a080e7          	jalr	-982(ra) # 80001f36 <myproc>
    80002314:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002316:	00000097          	auipc	ra,0x0
    8000231a:	e2c080e7          	jalr	-468(ra) # 80002142 <allocproc>
    8000231e:	c175                	beqz	a0,80002402 <fork+0x106>
    80002320:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002322:	05093603          	ld	a2,80(s2)
    80002326:	6d2c                	ld	a1,88(a0)
    80002328:	05893503          	ld	a0,88(s2)
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	7e2080e7          	jalr	2018(ra) # 80001b0e <uvmcopy>
    80002334:	04054863          	bltz	a0,80002384 <fork+0x88>
  np->sz = p->sz;
    80002338:	05093783          	ld	a5,80(s2)
    8000233c:	04f9b823          	sd	a5,80(s3) # 4000050 <_entry-0x7bffffb0>
  np->parent = p;
    80002340:	0329b423          	sd	s2,40(s3)
  *(np->trapframe) = *(p->trapframe);
    80002344:	06093683          	ld	a3,96(s2)
    80002348:	87b6                	mv	a5,a3
    8000234a:	0609b703          	ld	a4,96(s3)
    8000234e:	12068693          	addi	a3,a3,288
    80002352:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002356:	6788                	ld	a0,8(a5)
    80002358:	6b8c                	ld	a1,16(a5)
    8000235a:	6f90                	ld	a2,24(a5)
    8000235c:	01073023          	sd	a6,0(a4)
    80002360:	e708                	sd	a0,8(a4)
    80002362:	eb0c                	sd	a1,16(a4)
    80002364:	ef10                	sd	a2,24(a4)
    80002366:	02078793          	addi	a5,a5,32
    8000236a:	02070713          	addi	a4,a4,32
    8000236e:	fed792e3          	bne	a5,a3,80002352 <fork+0x56>
  np->trapframe->a0 = 0;
    80002372:	0609b783          	ld	a5,96(s3)
    80002376:	0607b823          	sd	zero,112(a5)
    8000237a:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    8000237e:	15800a13          	li	s4,344
    80002382:	a03d                	j	800023b0 <fork+0xb4>
    freeproc(np);
    80002384:	854e                	mv	a0,s3
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	d64080e7          	jalr	-668(ra) # 800020ea <freeproc>
    release(&np->lock);
    8000238e:	854e                	mv	a0,s3
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	bc6080e7          	jalr	-1082(ra) # 80000f56 <release>
    return -1;
    80002398:	54fd                	li	s1,-1
    8000239a:	a899                	j	800023f0 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    8000239c:	00002097          	auipc	ra,0x2
    800023a0:	7dc080e7          	jalr	2012(ra) # 80004b78 <filedup>
    800023a4:	009987b3          	add	a5,s3,s1
    800023a8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800023aa:	04a1                	addi	s1,s1,8
    800023ac:	01448763          	beq	s1,s4,800023ba <fork+0xbe>
    if(p->ofile[i])
    800023b0:	009907b3          	add	a5,s2,s1
    800023b4:	6388                	ld	a0,0(a5)
    800023b6:	f17d                	bnez	a0,8000239c <fork+0xa0>
    800023b8:	bfcd                	j	800023aa <fork+0xae>
  np->cwd = idup(p->cwd);
    800023ba:	15893503          	ld	a0,344(s2)
    800023be:	00002097          	auipc	ra,0x2
    800023c2:	8ee080e7          	jalr	-1810(ra) # 80003cac <idup>
    800023c6:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800023ca:	4641                	li	a2,16
    800023cc:	16090593          	addi	a1,s2,352
    800023d0:	16098513          	addi	a0,s3,352
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	036080e7          	jalr	54(ra) # 8000140a <safestrcpy>
  pid = np->pid;
    800023dc:	0409a483          	lw	s1,64(s3)
  np->state = RUNNABLE;
    800023e0:	4789                	li	a5,2
    800023e2:	02f9a023          	sw	a5,32(s3)
  release(&np->lock);
    800023e6:	854e                	mv	a0,s3
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	b6e080e7          	jalr	-1170(ra) # 80000f56 <release>
}
    800023f0:	8526                	mv	a0,s1
    800023f2:	70a2                	ld	ra,40(sp)
    800023f4:	7402                	ld	s0,32(sp)
    800023f6:	64e2                	ld	s1,24(sp)
    800023f8:	6942                	ld	s2,16(sp)
    800023fa:	69a2                	ld	s3,8(sp)
    800023fc:	6a02                	ld	s4,0(sp)
    800023fe:	6145                	addi	sp,sp,48
    80002400:	8082                	ret
    return -1;
    80002402:	54fd                	li	s1,-1
    80002404:	b7f5                	j	800023f0 <fork+0xf4>

0000000080002406 <reparent>:
{
    80002406:	7179                	addi	sp,sp,-48
    80002408:	f406                	sd	ra,40(sp)
    8000240a:	f022                	sd	s0,32(sp)
    8000240c:	ec26                	sd	s1,24(sp)
    8000240e:	e84a                	sd	s2,16(sp)
    80002410:	e44e                	sd	s3,8(sp)
    80002412:	e052                	sd	s4,0(sp)
    80002414:	1800                	addi	s0,sp,48
    80002416:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002418:	00010497          	auipc	s1,0x10
    8000241c:	3e048493          	addi	s1,s1,992 # 800127f8 <proc>
      pp->parent = initproc;
    80002420:	00007a17          	auipc	s4,0x7
    80002424:	bf8a0a13          	addi	s4,s4,-1032 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002428:	00016917          	auipc	s2,0x16
    8000242c:	fd090913          	addi	s2,s2,-48 # 800183f8 <tickslock>
    80002430:	a029                	j	8000243a <reparent+0x34>
    80002432:	17048493          	addi	s1,s1,368
    80002436:	03248363          	beq	s1,s2,8000245c <reparent+0x56>
    if(pp->parent == p){
    8000243a:	749c                	ld	a5,40(s1)
    8000243c:	ff379be3          	bne	a5,s3,80002432 <reparent+0x2c>
      acquire(&pp->lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	a44080e7          	jalr	-1468(ra) # 80000e86 <acquire>
      pp->parent = initproc;
    8000244a:	000a3783          	ld	a5,0(s4)
    8000244e:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	b04080e7          	jalr	-1276(ra) # 80000f56 <release>
    8000245a:	bfe1                	j	80002432 <reparent+0x2c>
}
    8000245c:	70a2                	ld	ra,40(sp)
    8000245e:	7402                	ld	s0,32(sp)
    80002460:	64e2                	ld	s1,24(sp)
    80002462:	6942                	ld	s2,16(sp)
    80002464:	69a2                	ld	s3,8(sp)
    80002466:	6a02                	ld	s4,0(sp)
    80002468:	6145                	addi	sp,sp,48
    8000246a:	8082                	ret

000000008000246c <scheduler>:
{
    8000246c:	711d                	addi	sp,sp,-96
    8000246e:	ec86                	sd	ra,88(sp)
    80002470:	e8a2                	sd	s0,80(sp)
    80002472:	e4a6                	sd	s1,72(sp)
    80002474:	e0ca                	sd	s2,64(sp)
    80002476:	fc4e                	sd	s3,56(sp)
    80002478:	f852                	sd	s4,48(sp)
    8000247a:	f456                	sd	s5,40(sp)
    8000247c:	f05a                	sd	s6,32(sp)
    8000247e:	ec5e                	sd	s7,24(sp)
    80002480:	e862                	sd	s8,16(sp)
    80002482:	e466                	sd	s9,8(sp)
    80002484:	1080                	addi	s0,sp,96
    80002486:	8792                	mv	a5,tp
  int id = r_tp();
    80002488:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000248a:	00779c13          	slli	s8,a5,0x7
    8000248e:	00010717          	auipc	a4,0x10
    80002492:	f4a70713          	addi	a4,a4,-182 # 800123d8 <pid_lock>
    80002496:	9762                	add	a4,a4,s8
    80002498:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    8000249c:	00010717          	auipc	a4,0x10
    800024a0:	f6470713          	addi	a4,a4,-156 # 80012400 <cpus+0x8>
    800024a4:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800024a6:	4a89                	li	s5,2
        c->proc = p;
    800024a8:	079e                	slli	a5,a5,0x7
    800024aa:	00010b17          	auipc	s6,0x10
    800024ae:	f2eb0b13          	addi	s6,s6,-210 # 800123d8 <pid_lock>
    800024b2:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800024b4:	00016a17          	auipc	s4,0x16
    800024b8:	f44a0a13          	addi	s4,s4,-188 # 800183f8 <tickslock>
    int nproc = 0;
    800024bc:	4c81                	li	s9,0
    800024be:	a8a1                	j	80002516 <scheduler+0xaa>
        p->state = RUNNING;
    800024c0:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800024c4:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    800024c8:	06848593          	addi	a1,s1,104
    800024cc:	8562                	mv	a0,s8
    800024ce:	00000097          	auipc	ra,0x0
    800024d2:	640080e7          	jalr	1600(ra) # 80002b0e <swtch>
        c->proc = 0;
    800024d6:	020b3023          	sd	zero,32(s6)
      release(&p->lock);
    800024da:	8526                	mv	a0,s1
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	a7a080e7          	jalr	-1414(ra) # 80000f56 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800024e4:	17048493          	addi	s1,s1,368
    800024e8:	01448d63          	beq	s1,s4,80002502 <scheduler+0x96>
      acquire(&p->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	998080e7          	jalr	-1640(ra) # 80000e86 <acquire>
      if(p->state != UNUSED) {
    800024f6:	509c                	lw	a5,32(s1)
    800024f8:	d3ed                	beqz	a5,800024da <scheduler+0x6e>
        nproc++;
    800024fa:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800024fc:	fd579fe3          	bne	a5,s5,800024da <scheduler+0x6e>
    80002500:	b7c1                	j	800024c0 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002502:	013aca63          	blt	s5,s3,80002516 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002506:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000250a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000250e:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002512:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002516:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000251a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000251e:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002522:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002524:	00010497          	auipc	s1,0x10
    80002528:	2d448493          	addi	s1,s1,724 # 800127f8 <proc>
        p->state = RUNNING;
    8000252c:	4b8d                	li	s7,3
    8000252e:	bf7d                	j	800024ec <scheduler+0x80>

0000000080002530 <sched>:
{
    80002530:	7179                	addi	sp,sp,-48
    80002532:	f406                	sd	ra,40(sp)
    80002534:	f022                	sd	s0,32(sp)
    80002536:	ec26                	sd	s1,24(sp)
    80002538:	e84a                	sd	s2,16(sp)
    8000253a:	e44e                	sd	s3,8(sp)
    8000253c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000253e:	00000097          	auipc	ra,0x0
    80002542:	9f8080e7          	jalr	-1544(ra) # 80001f36 <myproc>
    80002546:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	8c4080e7          	jalr	-1852(ra) # 80000e0c <holding>
    80002550:	cd25                	beqz	a0,800025c8 <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002552:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002554:	2781                	sext.w	a5,a5
    80002556:	079e                	slli	a5,a5,0x7
    80002558:	00010717          	auipc	a4,0x10
    8000255c:	e8070713          	addi	a4,a4,-384 # 800123d8 <pid_lock>
    80002560:	97ba                	add	a5,a5,a4
    80002562:	0987a703          	lw	a4,152(a5)
    80002566:	4785                	li	a5,1
    80002568:	06f71863          	bne	a4,a5,800025d8 <sched+0xa8>
  if(p->state == RUNNING)
    8000256c:	02092703          	lw	a4,32(s2)
    80002570:	478d                	li	a5,3
    80002572:	06f70b63          	beq	a4,a5,800025e8 <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002576:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000257a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000257c:	efb5                	bnez	a5,800025f8 <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000257e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002580:	00010497          	auipc	s1,0x10
    80002584:	e5848493          	addi	s1,s1,-424 # 800123d8 <pid_lock>
    80002588:	2781                	sext.w	a5,a5
    8000258a:	079e                	slli	a5,a5,0x7
    8000258c:	97a6                	add	a5,a5,s1
    8000258e:	09c7a983          	lw	s3,156(a5)
    80002592:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002594:	2781                	sext.w	a5,a5
    80002596:	079e                	slli	a5,a5,0x7
    80002598:	00010597          	auipc	a1,0x10
    8000259c:	e6858593          	addi	a1,a1,-408 # 80012400 <cpus+0x8>
    800025a0:	95be                	add	a1,a1,a5
    800025a2:	06890513          	addi	a0,s2,104
    800025a6:	00000097          	auipc	ra,0x0
    800025aa:	568080e7          	jalr	1384(ra) # 80002b0e <swtch>
    800025ae:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800025b0:	2781                	sext.w	a5,a5
    800025b2:	079e                	slli	a5,a5,0x7
    800025b4:	97a6                	add	a5,a5,s1
    800025b6:	0937ae23          	sw	s3,156(a5)
}
    800025ba:	70a2                	ld	ra,40(sp)
    800025bc:	7402                	ld	s0,32(sp)
    800025be:	64e2                	ld	s1,24(sp)
    800025c0:	6942                	ld	s2,16(sp)
    800025c2:	69a2                	ld	s3,8(sp)
    800025c4:	6145                	addi	sp,sp,48
    800025c6:	8082                	ret
    panic("sched p->lock");
    800025c8:	00006517          	auipc	a0,0x6
    800025cc:	cf850513          	addi	a0,a0,-776 # 800082c0 <states.1732+0x60>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	fa8080e7          	jalr	-88(ra) # 80000578 <panic>
    panic("sched locks");
    800025d8:	00006517          	auipc	a0,0x6
    800025dc:	cf850513          	addi	a0,a0,-776 # 800082d0 <states.1732+0x70>
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	f98080e7          	jalr	-104(ra) # 80000578 <panic>
    panic("sched running");
    800025e8:	00006517          	auipc	a0,0x6
    800025ec:	cf850513          	addi	a0,a0,-776 # 800082e0 <states.1732+0x80>
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	f88080e7          	jalr	-120(ra) # 80000578 <panic>
    panic("sched interruptible");
    800025f8:	00006517          	auipc	a0,0x6
    800025fc:	cf850513          	addi	a0,a0,-776 # 800082f0 <states.1732+0x90>
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	f78080e7          	jalr	-136(ra) # 80000578 <panic>

0000000080002608 <exit>:
{
    80002608:	7179                	addi	sp,sp,-48
    8000260a:	f406                	sd	ra,40(sp)
    8000260c:	f022                	sd	s0,32(sp)
    8000260e:	ec26                	sd	s1,24(sp)
    80002610:	e84a                	sd	s2,16(sp)
    80002612:	e44e                	sd	s3,8(sp)
    80002614:	e052                	sd	s4,0(sp)
    80002616:	1800                	addi	s0,sp,48
    80002618:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000261a:	00000097          	auipc	ra,0x0
    8000261e:	91c080e7          	jalr	-1764(ra) # 80001f36 <myproc>
    80002622:	89aa                	mv	s3,a0
  if(p == initproc)
    80002624:	00007797          	auipc	a5,0x7
    80002628:	9f478793          	addi	a5,a5,-1548 # 80009018 <initproc>
    8000262c:	639c                	ld	a5,0(a5)
    8000262e:	0d850493          	addi	s1,a0,216
    80002632:	15850913          	addi	s2,a0,344
    80002636:	02a79363          	bne	a5,a0,8000265c <exit+0x54>
    panic("init exiting");
    8000263a:	00006517          	auipc	a0,0x6
    8000263e:	cce50513          	addi	a0,a0,-818 # 80008308 <states.1732+0xa8>
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	f36080e7          	jalr	-202(ra) # 80000578 <panic>
      fileclose(f);
    8000264a:	00002097          	auipc	ra,0x2
    8000264e:	580080e7          	jalr	1408(ra) # 80004bca <fileclose>
      p->ofile[fd] = 0;
    80002652:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002656:	04a1                	addi	s1,s1,8
    80002658:	01248563          	beq	s1,s2,80002662 <exit+0x5a>
    if(p->ofile[fd]){
    8000265c:	6088                	ld	a0,0(s1)
    8000265e:	f575                	bnez	a0,8000264a <exit+0x42>
    80002660:	bfdd                	j	80002656 <exit+0x4e>
  begin_op();
    80002662:	00002097          	auipc	ra,0x2
    80002666:	064080e7          	jalr	100(ra) # 800046c6 <begin_op>
  iput(p->cwd);
    8000266a:	1589b503          	ld	a0,344(s3)
    8000266e:	00002097          	auipc	ra,0x2
    80002672:	838080e7          	jalr	-1992(ra) # 80003ea6 <iput>
  end_op();
    80002676:	00002097          	auipc	ra,0x2
    8000267a:	0d0080e7          	jalr	208(ra) # 80004746 <end_op>
  p->cwd = 0;
    8000267e:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002682:	00007497          	auipc	s1,0x7
    80002686:	99648493          	addi	s1,s1,-1642 # 80009018 <initproc>
    8000268a:	6088                	ld	a0,0(s1)
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	7fa080e7          	jalr	2042(ra) # 80000e86 <acquire>
  wakeup1(initproc);
    80002694:	6088                	ld	a0,0(s1)
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	760080e7          	jalr	1888(ra) # 80001df6 <wakeup1>
  release(&initproc->lock);
    8000269e:	6088                	ld	a0,0(s1)
    800026a0:	fffff097          	auipc	ra,0xfffff
    800026a4:	8b6080e7          	jalr	-1866(ra) # 80000f56 <release>
  acquire(&p->lock);
    800026a8:	854e                	mv	a0,s3
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	7dc080e7          	jalr	2012(ra) # 80000e86 <acquire>
  struct proc *original_parent = p->parent;
    800026b2:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800026b6:	854e                	mv	a0,s3
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	89e080e7          	jalr	-1890(ra) # 80000f56 <release>
  acquire(&original_parent->lock);
    800026c0:	8526                	mv	a0,s1
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	7c4080e7          	jalr	1988(ra) # 80000e86 <acquire>
  acquire(&p->lock);
    800026ca:	854e                	mv	a0,s3
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	7ba080e7          	jalr	1978(ra) # 80000e86 <acquire>
  reparent(p);
    800026d4:	854e                	mv	a0,s3
    800026d6:	00000097          	auipc	ra,0x0
    800026da:	d30080e7          	jalr	-720(ra) # 80002406 <reparent>
  wakeup1(original_parent);
    800026de:	8526                	mv	a0,s1
    800026e0:	fffff097          	auipc	ra,0xfffff
    800026e4:	716080e7          	jalr	1814(ra) # 80001df6 <wakeup1>
  p->xstate = status;
    800026e8:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800026ec:	4791                	li	a5,4
    800026ee:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	fffff097          	auipc	ra,0xfffff
    800026f8:	862080e7          	jalr	-1950(ra) # 80000f56 <release>
  sched();
    800026fc:	00000097          	auipc	ra,0x0
    80002700:	e34080e7          	jalr	-460(ra) # 80002530 <sched>
  panic("zombie exit");
    80002704:	00006517          	auipc	a0,0x6
    80002708:	c1450513          	addi	a0,a0,-1004 # 80008318 <states.1732+0xb8>
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	e6c080e7          	jalr	-404(ra) # 80000578 <panic>

0000000080002714 <yield>:
{
    80002714:	1101                	addi	sp,sp,-32
    80002716:	ec06                	sd	ra,24(sp)
    80002718:	e822                	sd	s0,16(sp)
    8000271a:	e426                	sd	s1,8(sp)
    8000271c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000271e:	00000097          	auipc	ra,0x0
    80002722:	818080e7          	jalr	-2024(ra) # 80001f36 <myproc>
    80002726:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	75e080e7          	jalr	1886(ra) # 80000e86 <acquire>
  p->state = RUNNABLE;
    80002730:	4789                	li	a5,2
    80002732:	d09c                	sw	a5,32(s1)
  sched();
    80002734:	00000097          	auipc	ra,0x0
    80002738:	dfc080e7          	jalr	-516(ra) # 80002530 <sched>
  release(&p->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	fffff097          	auipc	ra,0xfffff
    80002742:	818080e7          	jalr	-2024(ra) # 80000f56 <release>
}
    80002746:	60e2                	ld	ra,24(sp)
    80002748:	6442                	ld	s0,16(sp)
    8000274a:	64a2                	ld	s1,8(sp)
    8000274c:	6105                	addi	sp,sp,32
    8000274e:	8082                	ret

0000000080002750 <sleep>:
{
    80002750:	7179                	addi	sp,sp,-48
    80002752:	f406                	sd	ra,40(sp)
    80002754:	f022                	sd	s0,32(sp)
    80002756:	ec26                	sd	s1,24(sp)
    80002758:	e84a                	sd	s2,16(sp)
    8000275a:	e44e                	sd	s3,8(sp)
    8000275c:	1800                	addi	s0,sp,48
    8000275e:	89aa                	mv	s3,a0
    80002760:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002762:	fffff097          	auipc	ra,0xfffff
    80002766:	7d4080e7          	jalr	2004(ra) # 80001f36 <myproc>
    8000276a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000276c:	05250663          	beq	a0,s2,800027b8 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	716080e7          	jalr	1814(ra) # 80000e86 <acquire>
    release(lk);
    80002778:	854a                	mv	a0,s2
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	7dc080e7          	jalr	2012(ra) # 80000f56 <release>
  p->chan = chan;
    80002782:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002786:	4785                	li	a5,1
    80002788:	d09c                	sw	a5,32(s1)
  sched();
    8000278a:	00000097          	auipc	ra,0x0
    8000278e:	da6080e7          	jalr	-602(ra) # 80002530 <sched>
  p->chan = 0;
    80002792:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002796:	8526                	mv	a0,s1
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	7be080e7          	jalr	1982(ra) # 80000f56 <release>
    acquire(lk);
    800027a0:	854a                	mv	a0,s2
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	6e4080e7          	jalr	1764(ra) # 80000e86 <acquire>
}
    800027aa:	70a2                	ld	ra,40(sp)
    800027ac:	7402                	ld	s0,32(sp)
    800027ae:	64e2                	ld	s1,24(sp)
    800027b0:	6942                	ld	s2,16(sp)
    800027b2:	69a2                	ld	s3,8(sp)
    800027b4:	6145                	addi	sp,sp,48
    800027b6:	8082                	ret
  p->chan = chan;
    800027b8:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800027bc:	4785                	li	a5,1
    800027be:	d11c                	sw	a5,32(a0)
  sched();
    800027c0:	00000097          	auipc	ra,0x0
    800027c4:	d70080e7          	jalr	-656(ra) # 80002530 <sched>
  p->chan = 0;
    800027c8:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800027cc:	bff9                	j	800027aa <sleep+0x5a>

00000000800027ce <wait>:
{
    800027ce:	715d                	addi	sp,sp,-80
    800027d0:	e486                	sd	ra,72(sp)
    800027d2:	e0a2                	sd	s0,64(sp)
    800027d4:	fc26                	sd	s1,56(sp)
    800027d6:	f84a                	sd	s2,48(sp)
    800027d8:	f44e                	sd	s3,40(sp)
    800027da:	f052                	sd	s4,32(sp)
    800027dc:	ec56                	sd	s5,24(sp)
    800027de:	e85a                	sd	s6,16(sp)
    800027e0:	e45e                	sd	s7,8(sp)
    800027e2:	e062                	sd	s8,0(sp)
    800027e4:	0880                	addi	s0,sp,80
    800027e6:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    800027e8:	fffff097          	auipc	ra,0xfffff
    800027ec:	74e080e7          	jalr	1870(ra) # 80001f36 <myproc>
    800027f0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800027f2:	8c2a                	mv	s8,a0
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	692080e7          	jalr	1682(ra) # 80000e86 <acquire>
    havekids = 0;
    800027fc:	4b01                	li	s6,0
        if(np->state == ZOMBIE){
    800027fe:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002800:	00016997          	auipc	s3,0x16
    80002804:	bf898993          	addi	s3,s3,-1032 # 800183f8 <tickslock>
        havekids = 1;
    80002808:	4a85                	li	s5,1
    havekids = 0;
    8000280a:	875a                	mv	a4,s6
    for(np = proc; np < &proc[NPROC]; np++){
    8000280c:	00010497          	auipc	s1,0x10
    80002810:	fec48493          	addi	s1,s1,-20 # 800127f8 <proc>
    80002814:	a08d                	j	80002876 <wait+0xa8>
          pid = np->pid;
    80002816:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000281a:	000b8e63          	beqz	s7,80002836 <wait+0x68>
    8000281e:	4691                	li	a3,4
    80002820:	03c48613          	addi	a2,s1,60
    80002824:	85de                	mv	a1,s7
    80002826:	05893503          	ld	a0,88(s2)
    8000282a:	fffff097          	auipc	ra,0xfffff
    8000282e:	3e8080e7          	jalr	1000(ra) # 80001c12 <copyout>
    80002832:	02054263          	bltz	a0,80002856 <wait+0x88>
          freeproc(np);
    80002836:	8526                	mv	a0,s1
    80002838:	00000097          	auipc	ra,0x0
    8000283c:	8b2080e7          	jalr	-1870(ra) # 800020ea <freeproc>
          release(&np->lock);
    80002840:	8526                	mv	a0,s1
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	714080e7          	jalr	1812(ra) # 80000f56 <release>
          release(&p->lock);
    8000284a:	854a                	mv	a0,s2
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	70a080e7          	jalr	1802(ra) # 80000f56 <release>
          return pid;
    80002854:	a8a9                	j	800028ae <wait+0xe0>
            release(&np->lock);
    80002856:	8526                	mv	a0,s1
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	6fe080e7          	jalr	1790(ra) # 80000f56 <release>
            release(&p->lock);
    80002860:	854a                	mv	a0,s2
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	6f4080e7          	jalr	1780(ra) # 80000f56 <release>
            return -1;
    8000286a:	59fd                	li	s3,-1
    8000286c:	a089                	j	800028ae <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000286e:	17048493          	addi	s1,s1,368
    80002872:	03348463          	beq	s1,s3,8000289a <wait+0xcc>
      if(np->parent == p){
    80002876:	749c                	ld	a5,40(s1)
    80002878:	ff279be3          	bne	a5,s2,8000286e <wait+0xa0>
        acquire(&np->lock);
    8000287c:	8526                	mv	a0,s1
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	608080e7          	jalr	1544(ra) # 80000e86 <acquire>
        if(np->state == ZOMBIE){
    80002886:	509c                	lw	a5,32(s1)
    80002888:	f94787e3          	beq	a5,s4,80002816 <wait+0x48>
        release(&np->lock);
    8000288c:	8526                	mv	a0,s1
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	6c8080e7          	jalr	1736(ra) # 80000f56 <release>
        havekids = 1;
    80002896:	8756                	mv	a4,s5
    80002898:	bfd9                	j	8000286e <wait+0xa0>
    if(!havekids || p->killed){
    8000289a:	c701                	beqz	a4,800028a2 <wait+0xd4>
    8000289c:	03892783          	lw	a5,56(s2)
    800028a0:	c785                	beqz	a5,800028c8 <wait+0xfa>
      release(&p->lock);
    800028a2:	854a                	mv	a0,s2
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	6b2080e7          	jalr	1714(ra) # 80000f56 <release>
      return -1;
    800028ac:	59fd                	li	s3,-1
}
    800028ae:	854e                	mv	a0,s3
    800028b0:	60a6                	ld	ra,72(sp)
    800028b2:	6406                	ld	s0,64(sp)
    800028b4:	74e2                	ld	s1,56(sp)
    800028b6:	7942                	ld	s2,48(sp)
    800028b8:	79a2                	ld	s3,40(sp)
    800028ba:	7a02                	ld	s4,32(sp)
    800028bc:	6ae2                	ld	s5,24(sp)
    800028be:	6b42                	ld	s6,16(sp)
    800028c0:	6ba2                	ld	s7,8(sp)
    800028c2:	6c02                	ld	s8,0(sp)
    800028c4:	6161                	addi	sp,sp,80
    800028c6:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800028c8:	85e2                	mv	a1,s8
    800028ca:	854a                	mv	a0,s2
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	e84080e7          	jalr	-380(ra) # 80002750 <sleep>
    havekids = 0;
    800028d4:	bf1d                	j	8000280a <wait+0x3c>

00000000800028d6 <wakeup>:
{
    800028d6:	7139                	addi	sp,sp,-64
    800028d8:	fc06                	sd	ra,56(sp)
    800028da:	f822                	sd	s0,48(sp)
    800028dc:	f426                	sd	s1,40(sp)
    800028de:	f04a                	sd	s2,32(sp)
    800028e0:	ec4e                	sd	s3,24(sp)
    800028e2:	e852                	sd	s4,16(sp)
    800028e4:	e456                	sd	s5,8(sp)
    800028e6:	0080                	addi	s0,sp,64
    800028e8:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800028ea:	00010497          	auipc	s1,0x10
    800028ee:	f0e48493          	addi	s1,s1,-242 # 800127f8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800028f2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800028f4:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800028f6:	00016917          	auipc	s2,0x16
    800028fa:	b0290913          	addi	s2,s2,-1278 # 800183f8 <tickslock>
    800028fe:	a821                	j	80002916 <wakeup+0x40>
      p->state = RUNNABLE;
    80002900:	0354a023          	sw	s5,32(s1)
    release(&p->lock);
    80002904:	8526                	mv	a0,s1
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	650080e7          	jalr	1616(ra) # 80000f56 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000290e:	17048493          	addi	s1,s1,368
    80002912:	01248e63          	beq	s1,s2,8000292e <wakeup+0x58>
    acquire(&p->lock);
    80002916:	8526                	mv	a0,s1
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	56e080e7          	jalr	1390(ra) # 80000e86 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002920:	509c                	lw	a5,32(s1)
    80002922:	ff3791e3          	bne	a5,s3,80002904 <wakeup+0x2e>
    80002926:	789c                	ld	a5,48(s1)
    80002928:	fd479ee3          	bne	a5,s4,80002904 <wakeup+0x2e>
    8000292c:	bfd1                	j	80002900 <wakeup+0x2a>
}
    8000292e:	70e2                	ld	ra,56(sp)
    80002930:	7442                	ld	s0,48(sp)
    80002932:	74a2                	ld	s1,40(sp)
    80002934:	7902                	ld	s2,32(sp)
    80002936:	69e2                	ld	s3,24(sp)
    80002938:	6a42                	ld	s4,16(sp)
    8000293a:	6aa2                	ld	s5,8(sp)
    8000293c:	6121                	addi	sp,sp,64
    8000293e:	8082                	ret

0000000080002940 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002940:	7179                	addi	sp,sp,-48
    80002942:	f406                	sd	ra,40(sp)
    80002944:	f022                	sd	s0,32(sp)
    80002946:	ec26                	sd	s1,24(sp)
    80002948:	e84a                	sd	s2,16(sp)
    8000294a:	e44e                	sd	s3,8(sp)
    8000294c:	1800                	addi	s0,sp,48
    8000294e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002950:	00010497          	auipc	s1,0x10
    80002954:	ea848493          	addi	s1,s1,-344 # 800127f8 <proc>
    80002958:	00016997          	auipc	s3,0x16
    8000295c:	aa098993          	addi	s3,s3,-1376 # 800183f8 <tickslock>
    acquire(&p->lock);
    80002960:	8526                	mv	a0,s1
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	524080e7          	jalr	1316(ra) # 80000e86 <acquire>
    if(p->pid == pid){
    8000296a:	40bc                	lw	a5,64(s1)
    8000296c:	01278d63          	beq	a5,s2,80002986 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002970:	8526                	mv	a0,s1
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	5e4080e7          	jalr	1508(ra) # 80000f56 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000297a:	17048493          	addi	s1,s1,368
    8000297e:	ff3491e3          	bne	s1,s3,80002960 <kill+0x20>
  }
  return -1;
    80002982:	557d                	li	a0,-1
    80002984:	a829                	j	8000299e <kill+0x5e>
      p->killed = 1;
    80002986:	4785                	li	a5,1
    80002988:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    8000298a:	5098                	lw	a4,32(s1)
    8000298c:	4785                	li	a5,1
    8000298e:	00f70f63          	beq	a4,a5,800029ac <kill+0x6c>
      release(&p->lock);
    80002992:	8526                	mv	a0,s1
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	5c2080e7          	jalr	1474(ra) # 80000f56 <release>
      return 0;
    8000299c:	4501                	li	a0,0
}
    8000299e:	70a2                	ld	ra,40(sp)
    800029a0:	7402                	ld	s0,32(sp)
    800029a2:	64e2                	ld	s1,24(sp)
    800029a4:	6942                	ld	s2,16(sp)
    800029a6:	69a2                	ld	s3,8(sp)
    800029a8:	6145                	addi	sp,sp,48
    800029aa:	8082                	ret
        p->state = RUNNABLE;
    800029ac:	4789                	li	a5,2
    800029ae:	d09c                	sw	a5,32(s1)
    800029b0:	b7cd                	j	80002992 <kill+0x52>

00000000800029b2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029b2:	7179                	addi	sp,sp,-48
    800029b4:	f406                	sd	ra,40(sp)
    800029b6:	f022                	sd	s0,32(sp)
    800029b8:	ec26                	sd	s1,24(sp)
    800029ba:	e84a                	sd	s2,16(sp)
    800029bc:	e44e                	sd	s3,8(sp)
    800029be:	e052                	sd	s4,0(sp)
    800029c0:	1800                	addi	s0,sp,48
    800029c2:	84aa                	mv	s1,a0
    800029c4:	892e                	mv	s2,a1
    800029c6:	89b2                	mv	s3,a2
    800029c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029ca:	fffff097          	auipc	ra,0xfffff
    800029ce:	56c080e7          	jalr	1388(ra) # 80001f36 <myproc>
  if(user_dst){
    800029d2:	c08d                	beqz	s1,800029f4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029d4:	86d2                	mv	a3,s4
    800029d6:	864e                	mv	a2,s3
    800029d8:	85ca                	mv	a1,s2
    800029da:	6d28                	ld	a0,88(a0)
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	236080e7          	jalr	566(ra) # 80001c12 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029e4:	70a2                	ld	ra,40(sp)
    800029e6:	7402                	ld	s0,32(sp)
    800029e8:	64e2                	ld	s1,24(sp)
    800029ea:	6942                	ld	s2,16(sp)
    800029ec:	69a2                	ld	s3,8(sp)
    800029ee:	6a02                	ld	s4,0(sp)
    800029f0:	6145                	addi	sp,sp,48
    800029f2:	8082                	ret
    memmove((char *)dst, src, len);
    800029f4:	000a061b          	sext.w	a2,s4
    800029f8:	85ce                	mv	a1,s3
    800029fa:	854a                	mv	a0,s2
    800029fc:	fffff097          	auipc	ra,0xfffff
    80002a00:	902080e7          	jalr	-1790(ra) # 800012fe <memmove>
    return 0;
    80002a04:	8526                	mv	a0,s1
    80002a06:	bff9                	j	800029e4 <either_copyout+0x32>

0000000080002a08 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a08:	7179                	addi	sp,sp,-48
    80002a0a:	f406                	sd	ra,40(sp)
    80002a0c:	f022                	sd	s0,32(sp)
    80002a0e:	ec26                	sd	s1,24(sp)
    80002a10:	e84a                	sd	s2,16(sp)
    80002a12:	e44e                	sd	s3,8(sp)
    80002a14:	e052                	sd	s4,0(sp)
    80002a16:	1800                	addi	s0,sp,48
    80002a18:	892a                	mv	s2,a0
    80002a1a:	84ae                	mv	s1,a1
    80002a1c:	89b2                	mv	s3,a2
    80002a1e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a20:	fffff097          	auipc	ra,0xfffff
    80002a24:	516080e7          	jalr	1302(ra) # 80001f36 <myproc>
  if(user_src){
    80002a28:	c08d                	beqz	s1,80002a4a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a2a:	86d2                	mv	a3,s4
    80002a2c:	864e                	mv	a2,s3
    80002a2e:	85ca                	mv	a1,s2
    80002a30:	6d28                	ld	a0,88(a0)
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	26c080e7          	jalr	620(ra) # 80001c9e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a3a:	70a2                	ld	ra,40(sp)
    80002a3c:	7402                	ld	s0,32(sp)
    80002a3e:	64e2                	ld	s1,24(sp)
    80002a40:	6942                	ld	s2,16(sp)
    80002a42:	69a2                	ld	s3,8(sp)
    80002a44:	6a02                	ld	s4,0(sp)
    80002a46:	6145                	addi	sp,sp,48
    80002a48:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a4a:	000a061b          	sext.w	a2,s4
    80002a4e:	85ce                	mv	a1,s3
    80002a50:	854a                	mv	a0,s2
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	8ac080e7          	jalr	-1876(ra) # 800012fe <memmove>
    return 0;
    80002a5a:	8526                	mv	a0,s1
    80002a5c:	bff9                	j	80002a3a <either_copyin+0x32>

0000000080002a5e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a5e:	715d                	addi	sp,sp,-80
    80002a60:	e486                	sd	ra,72(sp)
    80002a62:	e0a2                	sd	s0,64(sp)
    80002a64:	fc26                	sd	s1,56(sp)
    80002a66:	f84a                	sd	s2,48(sp)
    80002a68:	f44e                	sd	s3,40(sp)
    80002a6a:	f052                	sd	s4,32(sp)
    80002a6c:	ec56                	sd	s5,24(sp)
    80002a6e:	e85a                	sd	s6,16(sp)
    80002a70:	e45e                	sd	s7,8(sp)
    80002a72:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a74:	00005517          	auipc	a0,0x5
    80002a78:	6f450513          	addi	a0,a0,1780 # 80008168 <digits+0x150>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	b46080e7          	jalr	-1210(ra) # 800005c2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a84:	00010497          	auipc	s1,0x10
    80002a88:	ed448493          	addi	s1,s1,-300 # 80012958 <proc+0x160>
    80002a8c:	00016917          	auipc	s2,0x16
    80002a90:	acc90913          	addi	s2,s2,-1332 # 80018558 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a94:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002a96:	00006997          	auipc	s3,0x6
    80002a9a:	89298993          	addi	s3,s3,-1902 # 80008328 <states.1732+0xc8>
    printf("%d %s %s", p->pid, state, p->name);
    80002a9e:	00006a97          	auipc	s5,0x6
    80002aa2:	892a8a93          	addi	s5,s5,-1902 # 80008330 <states.1732+0xd0>
    printf("\n");
    80002aa6:	00005a17          	auipc	s4,0x5
    80002aaa:	6c2a0a13          	addi	s4,s4,1730 # 80008168 <digits+0x150>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aae:	00005b97          	auipc	s7,0x5
    80002ab2:	7b2b8b93          	addi	s7,s7,1970 # 80008260 <states.1732>
    80002ab6:	a015                	j	80002ada <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    80002ab8:	86ba                	mv	a3,a4
    80002aba:	ee072583          	lw	a1,-288(a4)
    80002abe:	8556                	mv	a0,s5
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	b02080e7          	jalr	-1278(ra) # 800005c2 <printf>
    printf("\n");
    80002ac8:	8552                	mv	a0,s4
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	af8080e7          	jalr	-1288(ra) # 800005c2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ad2:	17048493          	addi	s1,s1,368
    80002ad6:	03248163          	beq	s1,s2,80002af8 <procdump+0x9a>
    if(p->state == UNUSED)
    80002ada:	8726                	mv	a4,s1
    80002adc:	ec04a783          	lw	a5,-320(s1)
    80002ae0:	dbed                	beqz	a5,80002ad2 <procdump+0x74>
      state = "???";
    80002ae2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae4:	fcfb6ae3          	bltu	s6,a5,80002ab8 <procdump+0x5a>
    80002ae8:	1782                	slli	a5,a5,0x20
    80002aea:	9381                	srli	a5,a5,0x20
    80002aec:	078e                	slli	a5,a5,0x3
    80002aee:	97de                	add	a5,a5,s7
    80002af0:	6390                	ld	a2,0(a5)
    80002af2:	f279                	bnez	a2,80002ab8 <procdump+0x5a>
      state = "???";
    80002af4:	864e                	mv	a2,s3
    80002af6:	b7c9                	j	80002ab8 <procdump+0x5a>
  }
}
    80002af8:	60a6                	ld	ra,72(sp)
    80002afa:	6406                	ld	s0,64(sp)
    80002afc:	74e2                	ld	s1,56(sp)
    80002afe:	7942                	ld	s2,48(sp)
    80002b00:	79a2                	ld	s3,40(sp)
    80002b02:	7a02                	ld	s4,32(sp)
    80002b04:	6ae2                	ld	s5,24(sp)
    80002b06:	6b42                	ld	s6,16(sp)
    80002b08:	6ba2                	ld	s7,8(sp)
    80002b0a:	6161                	addi	sp,sp,80
    80002b0c:	8082                	ret

0000000080002b0e <swtch>:
    80002b0e:	00153023          	sd	ra,0(a0)
    80002b12:	00253423          	sd	sp,8(a0)
    80002b16:	e900                	sd	s0,16(a0)
    80002b18:	ed04                	sd	s1,24(a0)
    80002b1a:	03253023          	sd	s2,32(a0)
    80002b1e:	03353423          	sd	s3,40(a0)
    80002b22:	03453823          	sd	s4,48(a0)
    80002b26:	03553c23          	sd	s5,56(a0)
    80002b2a:	05653023          	sd	s6,64(a0)
    80002b2e:	05753423          	sd	s7,72(a0)
    80002b32:	05853823          	sd	s8,80(a0)
    80002b36:	05953c23          	sd	s9,88(a0)
    80002b3a:	07a53023          	sd	s10,96(a0)
    80002b3e:	07b53423          	sd	s11,104(a0)
    80002b42:	0005b083          	ld	ra,0(a1)
    80002b46:	0085b103          	ld	sp,8(a1)
    80002b4a:	6980                	ld	s0,16(a1)
    80002b4c:	6d84                	ld	s1,24(a1)
    80002b4e:	0205b903          	ld	s2,32(a1)
    80002b52:	0285b983          	ld	s3,40(a1)
    80002b56:	0305ba03          	ld	s4,48(a1)
    80002b5a:	0385ba83          	ld	s5,56(a1)
    80002b5e:	0405bb03          	ld	s6,64(a1)
    80002b62:	0485bb83          	ld	s7,72(a1)
    80002b66:	0505bc03          	ld	s8,80(a1)
    80002b6a:	0585bc83          	ld	s9,88(a1)
    80002b6e:	0605bd03          	ld	s10,96(a1)
    80002b72:	0685bd83          	ld	s11,104(a1)
    80002b76:	8082                	ret

0000000080002b78 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b78:	1141                	addi	sp,sp,-16
    80002b7a:	e406                	sd	ra,8(sp)
    80002b7c:	e022                	sd	s0,0(sp)
    80002b7e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b80:	00005597          	auipc	a1,0x5
    80002b84:	7e858593          	addi	a1,a1,2024 # 80008368 <states.1732+0x108>
    80002b88:	00016517          	auipc	a0,0x16
    80002b8c:	87050513          	addi	a0,a0,-1936 # 800183f8 <tickslock>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	482080e7          	jalr	1154(ra) # 80001012 <initlock>
}
    80002b98:	60a2                	ld	ra,8(sp)
    80002b9a:	6402                	ld	s0,0(sp)
    80002b9c:	0141                	addi	sp,sp,16
    80002b9e:	8082                	ret

0000000080002ba0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ba0:	1141                	addi	sp,sp,-16
    80002ba2:	e422                	sd	s0,8(sp)
    80002ba4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ba6:	00003797          	auipc	a5,0x3
    80002baa:	6ea78793          	addi	a5,a5,1770 # 80006290 <kernelvec>
    80002bae:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bb2:	6422                	ld	s0,8(sp)
    80002bb4:	0141                	addi	sp,sp,16
    80002bb6:	8082                	ret

0000000080002bb8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bb8:	1141                	addi	sp,sp,-16
    80002bba:	e406                	sd	ra,8(sp)
    80002bbc:	e022                	sd	s0,0(sp)
    80002bbe:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	376080e7          	jalr	886(ra) # 80001f36 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bcc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bce:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002bd2:	00004617          	auipc	a2,0x4
    80002bd6:	42e60613          	addi	a2,a2,1070 # 80007000 <_trampoline>
    80002bda:	00004697          	auipc	a3,0x4
    80002bde:	42668693          	addi	a3,a3,1062 # 80007000 <_trampoline>
    80002be2:	8e91                	sub	a3,a3,a2
    80002be4:	040007b7          	lui	a5,0x4000
    80002be8:	17fd                	addi	a5,a5,-1
    80002bea:	07b2                	slli	a5,a5,0xc
    80002bec:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bee:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bf2:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bf4:	180026f3          	csrr	a3,satp
    80002bf8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bfa:	7138                	ld	a4,96(a0)
    80002bfc:	6534                	ld	a3,72(a0)
    80002bfe:	6585                	lui	a1,0x1
    80002c00:	96ae                	add	a3,a3,a1
    80002c02:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c04:	7138                	ld	a4,96(a0)
    80002c06:	00000697          	auipc	a3,0x0
    80002c0a:	13868693          	addi	a3,a3,312 # 80002d3e <usertrap>
    80002c0e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c10:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c12:	8692                	mv	a3,tp
    80002c14:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c16:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c1a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c1e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c22:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c26:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c28:	6f18                	ld	a4,24(a4)
    80002c2a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c2e:	6d2c                	ld	a1,88(a0)
    80002c30:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c32:	00004717          	auipc	a4,0x4
    80002c36:	45e70713          	addi	a4,a4,1118 # 80007090 <userret>
    80002c3a:	8f11                	sub	a4,a4,a2
    80002c3c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c3e:	577d                	li	a4,-1
    80002c40:	177e                	slli	a4,a4,0x3f
    80002c42:	8dd9                	or	a1,a1,a4
    80002c44:	02000537          	lui	a0,0x2000
    80002c48:	157d                	addi	a0,a0,-1
    80002c4a:	0536                	slli	a0,a0,0xd
    80002c4c:	9782                	jalr	a5
}
    80002c4e:	60a2                	ld	ra,8(sp)
    80002c50:	6402                	ld	s0,0(sp)
    80002c52:	0141                	addi	sp,sp,16
    80002c54:	8082                	ret

0000000080002c56 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c60:	00015497          	auipc	s1,0x15
    80002c64:	79848493          	addi	s1,s1,1944 # 800183f8 <tickslock>
    80002c68:	8526                	mv	a0,s1
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	21c080e7          	jalr	540(ra) # 80000e86 <acquire>
  ticks++;
    80002c72:	00006517          	auipc	a0,0x6
    80002c76:	3ae50513          	addi	a0,a0,942 # 80009020 <ticks>
    80002c7a:	411c                	lw	a5,0(a0)
    80002c7c:	2785                	addiw	a5,a5,1
    80002c7e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	c56080e7          	jalr	-938(ra) # 800028d6 <wakeup>
  release(&tickslock);
    80002c88:	8526                	mv	a0,s1
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	2cc080e7          	jalr	716(ra) # 80000f56 <release>
}
    80002c92:	60e2                	ld	ra,24(sp)
    80002c94:	6442                	ld	s0,16(sp)
    80002c96:	64a2                	ld	s1,8(sp)
    80002c98:	6105                	addi	sp,sp,32
    80002c9a:	8082                	ret

0000000080002c9c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c9c:	1101                	addi	sp,sp,-32
    80002c9e:	ec06                	sd	ra,24(sp)
    80002ca0:	e822                	sd	s0,16(sp)
    80002ca2:	e426                	sd	s1,8(sp)
    80002ca4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002caa:	00074d63          	bltz	a4,80002cc4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cae:	57fd                	li	a5,-1
    80002cb0:	17fe                	slli	a5,a5,0x3f
    80002cb2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cb4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cb6:	06f70363          	beq	a4,a5,80002d1c <devintr+0x80>
  }
}
    80002cba:	60e2                	ld	ra,24(sp)
    80002cbc:	6442                	ld	s0,16(sp)
    80002cbe:	64a2                	ld	s1,8(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret
     (scause & 0xff) == 9){
    80002cc4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cc8:	46a5                	li	a3,9
    80002cca:	fed792e3          	bne	a5,a3,80002cae <devintr+0x12>
    int irq = plic_claim();
    80002cce:	00003097          	auipc	ra,0x3
    80002cd2:	6ca080e7          	jalr	1738(ra) # 80006398 <plic_claim>
    80002cd6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cd8:	47a9                	li	a5,10
    80002cda:	02f50763          	beq	a0,a5,80002d08 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cde:	4785                	li	a5,1
    80002ce0:	02f50963          	beq	a0,a5,80002d12 <devintr+0x76>
    return 1;
    80002ce4:	4505                	li	a0,1
    } else if(irq){
    80002ce6:	d8f1                	beqz	s1,80002cba <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ce8:	85a6                	mv	a1,s1
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	68650513          	addi	a0,a0,1670 # 80008370 <states.1732+0x110>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	8d0080e7          	jalr	-1840(ra) # 800005c2 <printf>
      plic_complete(irq);
    80002cfa:	8526                	mv	a0,s1
    80002cfc:	00003097          	auipc	ra,0x3
    80002d00:	6c0080e7          	jalr	1728(ra) # 800063bc <plic_complete>
    return 1;
    80002d04:	4505                	li	a0,1
    80002d06:	bf55                	j	80002cba <devintr+0x1e>
      uartintr();
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	d1e080e7          	jalr	-738(ra) # 80000a26 <uartintr>
    80002d10:	b7ed                	j	80002cfa <devintr+0x5e>
      virtio_disk_intr();
    80002d12:	00004097          	auipc	ra,0x4
    80002d16:	ba8080e7          	jalr	-1112(ra) # 800068ba <virtio_disk_intr>
    80002d1a:	b7c5                	j	80002cfa <devintr+0x5e>
    if(cpuid() == 0){
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	1ee080e7          	jalr	494(ra) # 80001f0a <cpuid>
    80002d24:	c901                	beqz	a0,80002d34 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d26:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d2a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d2c:	14479073          	csrw	sip,a5
    return 2;
    80002d30:	4509                	li	a0,2
    80002d32:	b761                	j	80002cba <devintr+0x1e>
      clockintr();
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	f22080e7          	jalr	-222(ra) # 80002c56 <clockintr>
    80002d3c:	b7ed                	j	80002d26 <devintr+0x8a>

0000000080002d3e <usertrap>:
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	e04a                	sd	s2,0(sp)
    80002d48:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d4a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d4e:	1007f793          	andi	a5,a5,256
    80002d52:	e3ad                	bnez	a5,80002db4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d54:	00003797          	auipc	a5,0x3
    80002d58:	53c78793          	addi	a5,a5,1340 # 80006290 <kernelvec>
    80002d5c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	1d6080e7          	jalr	470(ra) # 80001f36 <myproc>
    80002d68:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d6a:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d6c:	14102773          	csrr	a4,sepc
    80002d70:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d72:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d76:	47a1                	li	a5,8
    80002d78:	04f71c63          	bne	a4,a5,80002dd0 <usertrap+0x92>
    if(p->killed)
    80002d7c:	5d1c                	lw	a5,56(a0)
    80002d7e:	e3b9                	bnez	a5,80002dc4 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d80:	70b8                	ld	a4,96(s1)
    80002d82:	6f1c                	ld	a5,24(a4)
    80002d84:	0791                	addi	a5,a5,4
    80002d86:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d8c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d90:	10079073          	csrw	sstatus,a5
    syscall();
    80002d94:	00000097          	auipc	ra,0x0
    80002d98:	2e6080e7          	jalr	742(ra) # 8000307a <syscall>
  if(p->killed)
    80002d9c:	5c9c                	lw	a5,56(s1)
    80002d9e:	ebc1                	bnez	a5,80002e2e <usertrap+0xf0>
  usertrapret();
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	e18080e7          	jalr	-488(ra) # 80002bb8 <usertrapret>
}
    80002da8:	60e2                	ld	ra,24(sp)
    80002daa:	6442                	ld	s0,16(sp)
    80002dac:	64a2                	ld	s1,8(sp)
    80002dae:	6902                	ld	s2,0(sp)
    80002db0:	6105                	addi	sp,sp,32
    80002db2:	8082                	ret
    panic("usertrap: not from user mode");
    80002db4:	00005517          	auipc	a0,0x5
    80002db8:	5dc50513          	addi	a0,a0,1500 # 80008390 <states.1732+0x130>
    80002dbc:	ffffd097          	auipc	ra,0xffffd
    80002dc0:	7bc080e7          	jalr	1980(ra) # 80000578 <panic>
      exit(-1);
    80002dc4:	557d                	li	a0,-1
    80002dc6:	00000097          	auipc	ra,0x0
    80002dca:	842080e7          	jalr	-1982(ra) # 80002608 <exit>
    80002dce:	bf4d                	j	80002d80 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002dd0:	00000097          	auipc	ra,0x0
    80002dd4:	ecc080e7          	jalr	-308(ra) # 80002c9c <devintr>
    80002dd8:	892a                	mv	s2,a0
    80002dda:	c501                	beqz	a0,80002de2 <usertrap+0xa4>
  if(p->killed)
    80002ddc:	5c9c                	lw	a5,56(s1)
    80002dde:	c3a1                	beqz	a5,80002e1e <usertrap+0xe0>
    80002de0:	a815                	j	80002e14 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002de2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002de6:	40b0                	lw	a2,64(s1)
    80002de8:	00005517          	auipc	a0,0x5
    80002dec:	5c850513          	addi	a0,a0,1480 # 800083b0 <states.1732+0x150>
    80002df0:	ffffd097          	auipc	ra,0xffffd
    80002df4:	7d2080e7          	jalr	2002(ra) # 800005c2 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002df8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dfc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e00:	00005517          	auipc	a0,0x5
    80002e04:	5e050513          	addi	a0,a0,1504 # 800083e0 <states.1732+0x180>
    80002e08:	ffffd097          	auipc	ra,0xffffd
    80002e0c:	7ba080e7          	jalr	1978(ra) # 800005c2 <printf>
    p->killed = 1;
    80002e10:	4785                	li	a5,1
    80002e12:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002e14:	557d                	li	a0,-1
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	7f2080e7          	jalr	2034(ra) # 80002608 <exit>
  if(which_dev == 2)
    80002e1e:	4789                	li	a5,2
    80002e20:	f8f910e3          	bne	s2,a5,80002da0 <usertrap+0x62>
    yield();
    80002e24:	00000097          	auipc	ra,0x0
    80002e28:	8f0080e7          	jalr	-1808(ra) # 80002714 <yield>
    80002e2c:	bf95                	j	80002da0 <usertrap+0x62>
  int which_dev = 0;
    80002e2e:	4901                	li	s2,0
    80002e30:	b7d5                	j	80002e14 <usertrap+0xd6>

0000000080002e32 <kerneltrap>:
{
    80002e32:	7179                	addi	sp,sp,-48
    80002e34:	f406                	sd	ra,40(sp)
    80002e36:	f022                	sd	s0,32(sp)
    80002e38:	ec26                	sd	s1,24(sp)
    80002e3a:	e84a                	sd	s2,16(sp)
    80002e3c:	e44e                	sd	s3,8(sp)
    80002e3e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e40:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e44:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e48:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e4c:	1004f793          	andi	a5,s1,256
    80002e50:	cb85                	beqz	a5,80002e80 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e52:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e56:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e58:	ef85                	bnez	a5,80002e90 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	e42080e7          	jalr	-446(ra) # 80002c9c <devintr>
    80002e62:	cd1d                	beqz	a0,80002ea0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e64:	4789                	li	a5,2
    80002e66:	06f50a63          	beq	a0,a5,80002eda <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e6a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e6e:	10049073          	csrw	sstatus,s1
}
    80002e72:	70a2                	ld	ra,40(sp)
    80002e74:	7402                	ld	s0,32(sp)
    80002e76:	64e2                	ld	s1,24(sp)
    80002e78:	6942                	ld	s2,16(sp)
    80002e7a:	69a2                	ld	s3,8(sp)
    80002e7c:	6145                	addi	sp,sp,48
    80002e7e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e80:	00005517          	auipc	a0,0x5
    80002e84:	58050513          	addi	a0,a0,1408 # 80008400 <states.1732+0x1a0>
    80002e88:	ffffd097          	auipc	ra,0xffffd
    80002e8c:	6f0080e7          	jalr	1776(ra) # 80000578 <panic>
    panic("kerneltrap: interrupts enabled");
    80002e90:	00005517          	auipc	a0,0x5
    80002e94:	59850513          	addi	a0,a0,1432 # 80008428 <states.1732+0x1c8>
    80002e98:	ffffd097          	auipc	ra,0xffffd
    80002e9c:	6e0080e7          	jalr	1760(ra) # 80000578 <panic>
    printf("scause %p\n", scause);
    80002ea0:	85ce                	mv	a1,s3
    80002ea2:	00005517          	auipc	a0,0x5
    80002ea6:	5a650513          	addi	a0,a0,1446 # 80008448 <states.1732+0x1e8>
    80002eaa:	ffffd097          	auipc	ra,0xffffd
    80002eae:	718080e7          	jalr	1816(ra) # 800005c2 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eb2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eb6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002eba:	00005517          	auipc	a0,0x5
    80002ebe:	59e50513          	addi	a0,a0,1438 # 80008458 <states.1732+0x1f8>
    80002ec2:	ffffd097          	auipc	ra,0xffffd
    80002ec6:	700080e7          	jalr	1792(ra) # 800005c2 <printf>
    panic("kerneltrap");
    80002eca:	00005517          	auipc	a0,0x5
    80002ece:	5a650513          	addi	a0,a0,1446 # 80008470 <states.1732+0x210>
    80002ed2:	ffffd097          	auipc	ra,0xffffd
    80002ed6:	6a6080e7          	jalr	1702(ra) # 80000578 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	05c080e7          	jalr	92(ra) # 80001f36 <myproc>
    80002ee2:	d541                	beqz	a0,80002e6a <kerneltrap+0x38>
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	052080e7          	jalr	82(ra) # 80001f36 <myproc>
    80002eec:	5118                	lw	a4,32(a0)
    80002eee:	478d                	li	a5,3
    80002ef0:	f6f71de3          	bne	a4,a5,80002e6a <kerneltrap+0x38>
    yield();
    80002ef4:	00000097          	auipc	ra,0x0
    80002ef8:	820080e7          	jalr	-2016(ra) # 80002714 <yield>
    80002efc:	b7bd                	j	80002e6a <kerneltrap+0x38>

0000000080002efe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002efe:	1101                	addi	sp,sp,-32
    80002f00:	ec06                	sd	ra,24(sp)
    80002f02:	e822                	sd	s0,16(sp)
    80002f04:	e426                	sd	s1,8(sp)
    80002f06:	1000                	addi	s0,sp,32
    80002f08:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	02c080e7          	jalr	44(ra) # 80001f36 <myproc>
  switch (n) {
    80002f12:	4795                	li	a5,5
    80002f14:	0497e363          	bltu	a5,s1,80002f5a <argraw+0x5c>
    80002f18:	1482                	slli	s1,s1,0x20
    80002f1a:	9081                	srli	s1,s1,0x20
    80002f1c:	048a                	slli	s1,s1,0x2
    80002f1e:	00005717          	auipc	a4,0x5
    80002f22:	56270713          	addi	a4,a4,1378 # 80008480 <states.1732+0x220>
    80002f26:	94ba                	add	s1,s1,a4
    80002f28:	409c                	lw	a5,0(s1)
    80002f2a:	97ba                	add	a5,a5,a4
    80002f2c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f2e:	713c                	ld	a5,96(a0)
    80002f30:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	64a2                	ld	s1,8(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret
    return p->trapframe->a1;
    80002f3c:	713c                	ld	a5,96(a0)
    80002f3e:	7fa8                	ld	a0,120(a5)
    80002f40:	bfcd                	j	80002f32 <argraw+0x34>
    return p->trapframe->a2;
    80002f42:	713c                	ld	a5,96(a0)
    80002f44:	63c8                	ld	a0,128(a5)
    80002f46:	b7f5                	j	80002f32 <argraw+0x34>
    return p->trapframe->a3;
    80002f48:	713c                	ld	a5,96(a0)
    80002f4a:	67c8                	ld	a0,136(a5)
    80002f4c:	b7dd                	j	80002f32 <argraw+0x34>
    return p->trapframe->a4;
    80002f4e:	713c                	ld	a5,96(a0)
    80002f50:	6bc8                	ld	a0,144(a5)
    80002f52:	b7c5                	j	80002f32 <argraw+0x34>
    return p->trapframe->a5;
    80002f54:	713c                	ld	a5,96(a0)
    80002f56:	6fc8                	ld	a0,152(a5)
    80002f58:	bfe9                	j	80002f32 <argraw+0x34>
  panic("argraw");
    80002f5a:	00005517          	auipc	a0,0x5
    80002f5e:	5ee50513          	addi	a0,a0,1518 # 80008548 <syscalls+0xb0>
    80002f62:	ffffd097          	auipc	ra,0xffffd
    80002f66:	616080e7          	jalr	1558(ra) # 80000578 <panic>

0000000080002f6a <fetchaddr>:
{
    80002f6a:	1101                	addi	sp,sp,-32
    80002f6c:	ec06                	sd	ra,24(sp)
    80002f6e:	e822                	sd	s0,16(sp)
    80002f70:	e426                	sd	s1,8(sp)
    80002f72:	e04a                	sd	s2,0(sp)
    80002f74:	1000                	addi	s0,sp,32
    80002f76:	84aa                	mv	s1,a0
    80002f78:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	fbc080e7          	jalr	-68(ra) # 80001f36 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f82:	693c                	ld	a5,80(a0)
    80002f84:	02f4f963          	bleu	a5,s1,80002fb6 <fetchaddr+0x4c>
    80002f88:	00848713          	addi	a4,s1,8
    80002f8c:	02e7e763          	bltu	a5,a4,80002fba <fetchaddr+0x50>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f90:	46a1                	li	a3,8
    80002f92:	8626                	mv	a2,s1
    80002f94:	85ca                	mv	a1,s2
    80002f96:	6d28                	ld	a0,88(a0)
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	d06080e7          	jalr	-762(ra) # 80001c9e <copyin>
    80002fa0:	00a03533          	snez	a0,a0
    80002fa4:	40a0053b          	negw	a0,a0
    80002fa8:	2501                	sext.w	a0,a0
}
    80002faa:	60e2                	ld	ra,24(sp)
    80002fac:	6442                	ld	s0,16(sp)
    80002fae:	64a2                	ld	s1,8(sp)
    80002fb0:	6902                	ld	s2,0(sp)
    80002fb2:	6105                	addi	sp,sp,32
    80002fb4:	8082                	ret
    return -1;
    80002fb6:	557d                	li	a0,-1
    80002fb8:	bfcd                	j	80002faa <fetchaddr+0x40>
    80002fba:	557d                	li	a0,-1
    80002fbc:	b7fd                	j	80002faa <fetchaddr+0x40>

0000000080002fbe <fetchstr>:
{
    80002fbe:	7179                	addi	sp,sp,-48
    80002fc0:	f406                	sd	ra,40(sp)
    80002fc2:	f022                	sd	s0,32(sp)
    80002fc4:	ec26                	sd	s1,24(sp)
    80002fc6:	e84a                	sd	s2,16(sp)
    80002fc8:	e44e                	sd	s3,8(sp)
    80002fca:	1800                	addi	s0,sp,48
    80002fcc:	892a                	mv	s2,a0
    80002fce:	84ae                	mv	s1,a1
    80002fd0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fd2:	fffff097          	auipc	ra,0xfffff
    80002fd6:	f64080e7          	jalr	-156(ra) # 80001f36 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002fda:	86ce                	mv	a3,s3
    80002fdc:	864a                	mv	a2,s2
    80002fde:	85a6                	mv	a1,s1
    80002fe0:	6d28                	ld	a0,88(a0)
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	d4a080e7          	jalr	-694(ra) # 80001d2c <copyinstr>
  if(err < 0)
    80002fea:	00054763          	bltz	a0,80002ff8 <fetchstr+0x3a>
  return strlen(buf);
    80002fee:	8526                	mv	a0,s1
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	44c080e7          	jalr	1100(ra) # 8000143c <strlen>
}
    80002ff8:	70a2                	ld	ra,40(sp)
    80002ffa:	7402                	ld	s0,32(sp)
    80002ffc:	64e2                	ld	s1,24(sp)
    80002ffe:	6942                	ld	s2,16(sp)
    80003000:	69a2                	ld	s3,8(sp)
    80003002:	6145                	addi	sp,sp,48
    80003004:	8082                	ret

0000000080003006 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003006:	1101                	addi	sp,sp,-32
    80003008:	ec06                	sd	ra,24(sp)
    8000300a:	e822                	sd	s0,16(sp)
    8000300c:	e426                	sd	s1,8(sp)
    8000300e:	1000                	addi	s0,sp,32
    80003010:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003012:	00000097          	auipc	ra,0x0
    80003016:	eec080e7          	jalr	-276(ra) # 80002efe <argraw>
    8000301a:	c088                	sw	a0,0(s1)
  return 0;
}
    8000301c:	4501                	li	a0,0
    8000301e:	60e2                	ld	ra,24(sp)
    80003020:	6442                	ld	s0,16(sp)
    80003022:	64a2                	ld	s1,8(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	1000                	addi	s0,sp,32
    80003032:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003034:	00000097          	auipc	ra,0x0
    80003038:	eca080e7          	jalr	-310(ra) # 80002efe <argraw>
    8000303c:	e088                	sd	a0,0(s1)
  return 0;
}
    8000303e:	4501                	li	a0,0
    80003040:	60e2                	ld	ra,24(sp)
    80003042:	6442                	ld	s0,16(sp)
    80003044:	64a2                	ld	s1,8(sp)
    80003046:	6105                	addi	sp,sp,32
    80003048:	8082                	ret

000000008000304a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000304a:	1101                	addi	sp,sp,-32
    8000304c:	ec06                	sd	ra,24(sp)
    8000304e:	e822                	sd	s0,16(sp)
    80003050:	e426                	sd	s1,8(sp)
    80003052:	e04a                	sd	s2,0(sp)
    80003054:	1000                	addi	s0,sp,32
    80003056:	84ae                	mv	s1,a1
    80003058:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	ea4080e7          	jalr	-348(ra) # 80002efe <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003062:	864a                	mv	a2,s2
    80003064:	85a6                	mv	a1,s1
    80003066:	00000097          	auipc	ra,0x0
    8000306a:	f58080e7          	jalr	-168(ra) # 80002fbe <fetchstr>
}
    8000306e:	60e2                	ld	ra,24(sp)
    80003070:	6442                	ld	s0,16(sp)
    80003072:	64a2                	ld	s1,8(sp)
    80003074:	6902                	ld	s2,0(sp)
    80003076:	6105                	addi	sp,sp,32
    80003078:	8082                	ret

000000008000307a <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	e426                	sd	s1,8(sp)
    80003082:	e04a                	sd	s2,0(sp)
    80003084:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	eb0080e7          	jalr	-336(ra) # 80001f36 <myproc>
    8000308e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003090:	06053903          	ld	s2,96(a0)
    80003094:	0a893783          	ld	a5,168(s2)
    80003098:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000309c:	37fd                	addiw	a5,a5,-1
    8000309e:	4751                	li	a4,20
    800030a0:	00f76f63          	bltu	a4,a5,800030be <syscall+0x44>
    800030a4:	00369713          	slli	a4,a3,0x3
    800030a8:	00005797          	auipc	a5,0x5
    800030ac:	3f078793          	addi	a5,a5,1008 # 80008498 <syscalls>
    800030b0:	97ba                	add	a5,a5,a4
    800030b2:	639c                	ld	a5,0(a5)
    800030b4:	c789                	beqz	a5,800030be <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030b6:	9782                	jalr	a5
    800030b8:	06a93823          	sd	a0,112(s2)
    800030bc:	a839                	j	800030da <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030be:	16048613          	addi	a2,s1,352
    800030c2:	40ac                	lw	a1,64(s1)
    800030c4:	00005517          	auipc	a0,0x5
    800030c8:	48c50513          	addi	a0,a0,1164 # 80008550 <syscalls+0xb8>
    800030cc:	ffffd097          	auipc	ra,0xffffd
    800030d0:	4f6080e7          	jalr	1270(ra) # 800005c2 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030d4:	70bc                	ld	a5,96(s1)
    800030d6:	577d                	li	a4,-1
    800030d8:	fbb8                	sd	a4,112(a5)
  }
}
    800030da:	60e2                	ld	ra,24(sp)
    800030dc:	6442                	ld	s0,16(sp)
    800030de:	64a2                	ld	s1,8(sp)
    800030e0:	6902                	ld	s2,0(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret

00000000800030e6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030e6:	1101                	addi	sp,sp,-32
    800030e8:	ec06                	sd	ra,24(sp)
    800030ea:	e822                	sd	s0,16(sp)
    800030ec:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800030ee:	fec40593          	addi	a1,s0,-20
    800030f2:	4501                	li	a0,0
    800030f4:	00000097          	auipc	ra,0x0
    800030f8:	f12080e7          	jalr	-238(ra) # 80003006 <argint>
    return -1;
    800030fc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030fe:	00054963          	bltz	a0,80003110 <sys_exit+0x2a>
  exit(n);
    80003102:	fec42503          	lw	a0,-20(s0)
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	502080e7          	jalr	1282(ra) # 80002608 <exit>
  return 0;  // not reached
    8000310e:	4781                	li	a5,0
}
    80003110:	853e                	mv	a0,a5
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000311a:	1141                	addi	sp,sp,-16
    8000311c:	e406                	sd	ra,8(sp)
    8000311e:	e022                	sd	s0,0(sp)
    80003120:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	e14080e7          	jalr	-492(ra) # 80001f36 <myproc>
}
    8000312a:	4128                	lw	a0,64(a0)
    8000312c:	60a2                	ld	ra,8(sp)
    8000312e:	6402                	ld	s0,0(sp)
    80003130:	0141                	addi	sp,sp,16
    80003132:	8082                	ret

0000000080003134 <sys_fork>:

uint64
sys_fork(void)
{
    80003134:	1141                	addi	sp,sp,-16
    80003136:	e406                	sd	ra,8(sp)
    80003138:	e022                	sd	s0,0(sp)
    8000313a:	0800                	addi	s0,sp,16
  return fork();
    8000313c:	fffff097          	auipc	ra,0xfffff
    80003140:	1c0080e7          	jalr	448(ra) # 800022fc <fork>
}
    80003144:	60a2                	ld	ra,8(sp)
    80003146:	6402                	ld	s0,0(sp)
    80003148:	0141                	addi	sp,sp,16
    8000314a:	8082                	ret

000000008000314c <sys_wait>:

uint64
sys_wait(void)
{
    8000314c:	1101                	addi	sp,sp,-32
    8000314e:	ec06                	sd	ra,24(sp)
    80003150:	e822                	sd	s0,16(sp)
    80003152:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003154:	fe840593          	addi	a1,s0,-24
    80003158:	4501                	li	a0,0
    8000315a:	00000097          	auipc	ra,0x0
    8000315e:	ece080e7          	jalr	-306(ra) # 80003028 <argaddr>
    return -1;
    80003162:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80003164:	00054963          	bltz	a0,80003176 <sys_wait+0x2a>
  return wait(p);
    80003168:	fe843503          	ld	a0,-24(s0)
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	662080e7          	jalr	1634(ra) # 800027ce <wait>
    80003174:	87aa                	mv	a5,a0
}
    80003176:	853e                	mv	a0,a5
    80003178:	60e2                	ld	ra,24(sp)
    8000317a:	6442                	ld	s0,16(sp)
    8000317c:	6105                	addi	sp,sp,32
    8000317e:	8082                	ret

0000000080003180 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003180:	7179                	addi	sp,sp,-48
    80003182:	f406                	sd	ra,40(sp)
    80003184:	f022                	sd	s0,32(sp)
    80003186:	ec26                	sd	s1,24(sp)
    80003188:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000318a:	fdc40593          	addi	a1,s0,-36
    8000318e:	4501                	li	a0,0
    80003190:	00000097          	auipc	ra,0x0
    80003194:	e76080e7          	jalr	-394(ra) # 80003006 <argint>
    return -1;
    80003198:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    8000319a:	00054f63          	bltz	a0,800031b8 <sys_sbrk+0x38>
  addr = myproc()->sz;
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	d98080e7          	jalr	-616(ra) # 80001f36 <myproc>
    800031a6:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    800031a8:	fdc42503          	lw	a0,-36(s0)
    800031ac:	fffff097          	auipc	ra,0xfffff
    800031b0:	0d8080e7          	jalr	216(ra) # 80002284 <growproc>
    800031b4:	00054863          	bltz	a0,800031c4 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800031b8:	8526                	mv	a0,s1
    800031ba:	70a2                	ld	ra,40(sp)
    800031bc:	7402                	ld	s0,32(sp)
    800031be:	64e2                	ld	s1,24(sp)
    800031c0:	6145                	addi	sp,sp,48
    800031c2:	8082                	ret
    return -1;
    800031c4:	54fd                	li	s1,-1
    800031c6:	bfcd                	j	800031b8 <sys_sbrk+0x38>

00000000800031c8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031c8:	7139                	addi	sp,sp,-64
    800031ca:	fc06                	sd	ra,56(sp)
    800031cc:	f822                	sd	s0,48(sp)
    800031ce:	f426                	sd	s1,40(sp)
    800031d0:	f04a                	sd	s2,32(sp)
    800031d2:	ec4e                	sd	s3,24(sp)
    800031d4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031d6:	fcc40593          	addi	a1,s0,-52
    800031da:	4501                	li	a0,0
    800031dc:	00000097          	auipc	ra,0x0
    800031e0:	e2a080e7          	jalr	-470(ra) # 80003006 <argint>
    return -1;
    800031e4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031e6:	06054763          	bltz	a0,80003254 <sys_sleep+0x8c>
  acquire(&tickslock);
    800031ea:	00015517          	auipc	a0,0x15
    800031ee:	20e50513          	addi	a0,a0,526 # 800183f8 <tickslock>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	c94080e7          	jalr	-876(ra) # 80000e86 <acquire>
  ticks0 = ticks;
    800031fa:	00006797          	auipc	a5,0x6
    800031fe:	e2678793          	addi	a5,a5,-474 # 80009020 <ticks>
    80003202:	0007a903          	lw	s2,0(a5)
  while(ticks - ticks0 < n){
    80003206:	fcc42783          	lw	a5,-52(s0)
    8000320a:	cf85                	beqz	a5,80003242 <sys_sleep+0x7a>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000320c:	00015997          	auipc	s3,0x15
    80003210:	1ec98993          	addi	s3,s3,492 # 800183f8 <tickslock>
    80003214:	00006497          	auipc	s1,0x6
    80003218:	e0c48493          	addi	s1,s1,-500 # 80009020 <ticks>
    if(myproc()->killed){
    8000321c:	fffff097          	auipc	ra,0xfffff
    80003220:	d1a080e7          	jalr	-742(ra) # 80001f36 <myproc>
    80003224:	5d1c                	lw	a5,56(a0)
    80003226:	ef9d                	bnez	a5,80003264 <sys_sleep+0x9c>
    sleep(&ticks, &tickslock);
    80003228:	85ce                	mv	a1,s3
    8000322a:	8526                	mv	a0,s1
    8000322c:	fffff097          	auipc	ra,0xfffff
    80003230:	524080e7          	jalr	1316(ra) # 80002750 <sleep>
  while(ticks - ticks0 < n){
    80003234:	409c                	lw	a5,0(s1)
    80003236:	412787bb          	subw	a5,a5,s2
    8000323a:	fcc42703          	lw	a4,-52(s0)
    8000323e:	fce7efe3          	bltu	a5,a4,8000321c <sys_sleep+0x54>
  }
  release(&tickslock);
    80003242:	00015517          	auipc	a0,0x15
    80003246:	1b650513          	addi	a0,a0,438 # 800183f8 <tickslock>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	d0c080e7          	jalr	-756(ra) # 80000f56 <release>
  return 0;
    80003252:	4781                	li	a5,0
}
    80003254:	853e                	mv	a0,a5
    80003256:	70e2                	ld	ra,56(sp)
    80003258:	7442                	ld	s0,48(sp)
    8000325a:	74a2                	ld	s1,40(sp)
    8000325c:	7902                	ld	s2,32(sp)
    8000325e:	69e2                	ld	s3,24(sp)
    80003260:	6121                	addi	sp,sp,64
    80003262:	8082                	ret
      release(&tickslock);
    80003264:	00015517          	auipc	a0,0x15
    80003268:	19450513          	addi	a0,a0,404 # 800183f8 <tickslock>
    8000326c:	ffffe097          	auipc	ra,0xffffe
    80003270:	cea080e7          	jalr	-790(ra) # 80000f56 <release>
      return -1;
    80003274:	57fd                	li	a5,-1
    80003276:	bff9                	j	80003254 <sys_sleep+0x8c>

0000000080003278 <sys_kill>:

uint64
sys_kill(void)
{
    80003278:	1101                	addi	sp,sp,-32
    8000327a:	ec06                	sd	ra,24(sp)
    8000327c:	e822                	sd	s0,16(sp)
    8000327e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003280:	fec40593          	addi	a1,s0,-20
    80003284:	4501                	li	a0,0
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	d80080e7          	jalr	-640(ra) # 80003006 <argint>
    return -1;
    8000328e:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80003290:	00054963          	bltz	a0,800032a2 <sys_kill+0x2a>
  return kill(pid);
    80003294:	fec42503          	lw	a0,-20(s0)
    80003298:	fffff097          	auipc	ra,0xfffff
    8000329c:	6a8080e7          	jalr	1704(ra) # 80002940 <kill>
    800032a0:	87aa                	mv	a5,a0
}
    800032a2:	853e                	mv	a0,a5
    800032a4:	60e2                	ld	ra,24(sp)
    800032a6:	6442                	ld	s0,16(sp)
    800032a8:	6105                	addi	sp,sp,32
    800032aa:	8082                	ret

00000000800032ac <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032ac:	1101                	addi	sp,sp,-32
    800032ae:	ec06                	sd	ra,24(sp)
    800032b0:	e822                	sd	s0,16(sp)
    800032b2:	e426                	sd	s1,8(sp)
    800032b4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032b6:	00015517          	auipc	a0,0x15
    800032ba:	14250513          	addi	a0,a0,322 # 800183f8 <tickslock>
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	bc8080e7          	jalr	-1080(ra) # 80000e86 <acquire>
  xticks = ticks;
    800032c6:	00006797          	auipc	a5,0x6
    800032ca:	d5a78793          	addi	a5,a5,-678 # 80009020 <ticks>
    800032ce:	4384                	lw	s1,0(a5)
  release(&tickslock);
    800032d0:	00015517          	auipc	a0,0x15
    800032d4:	12850513          	addi	a0,a0,296 # 800183f8 <tickslock>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	c7e080e7          	jalr	-898(ra) # 80000f56 <release>
  return xticks;
}
    800032e0:	02049513          	slli	a0,s1,0x20
    800032e4:	9101                	srli	a0,a0,0x20
    800032e6:	60e2                	ld	ra,24(sp)
    800032e8:	6442                	ld	s0,16(sp)
    800032ea:	64a2                	ld	s1,8(sp)
    800032ec:	6105                	addi	sp,sp,32
    800032ee:	8082                	ret

00000000800032f0 <hash>:
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf buf[NSIZE];
} bcache[NBUCKETS];

int hash(uint dev, uint blockno) {
    800032f0:	1141                	addi	sp,sp,-16
    800032f2:	e422                	sd	s0,8(sp)
    800032f4:	0800                	addi	s0,sp,16
  return blockno % NBUCKETS;
}
    800032f6:	06b00513          	li	a0,107
    800032fa:	02a5f53b          	remuw	a0,a1,a0
    800032fe:	6422                	ld	s0,8(sp)
    80003300:	0141                	addi	sp,sp,16
    80003302:	8082                	ret

0000000080003304 <binit>:

void
binit(void)
{
    80003304:	715d                	addi	sp,sp,-80
    80003306:	e486                	sd	ra,72(sp)
    80003308:	e0a2                	sd	s0,64(sp)
    8000330a:	fc26                	sd	s1,56(sp)
    8000330c:	f84a                	sd	s2,48(sp)
    8000330e:	f44e                	sd	s3,40(sp)
    80003310:	f052                	sd	s4,32(sp)
    80003312:	ec56                	sd	s5,24(sp)
    80003314:	e85a                	sd	s6,16(sp)
    80003316:	e45e                	sd	s7,8(sp)
    80003318:	e062                	sd	s8,0(sp)
    8000331a:	0880                	addi	s0,sp,80
  struct buf *b;

  for (int i = 0; i < NBUCKETS; i++) {
    8000331c:	00015497          	auipc	s1,0x15
    80003320:	5a448493          	addi	s1,s1,1444 # 800188c0 <bcache+0x4a8>
    80003324:	4901                	li	s2,0
    // 为每个桶设置锁并初始化
    snprintf(bcache[i].name, 10, "bcache%d", i);
    80003326:	00005c17          	auipc	s8,0x5
    8000332a:	24ac0c13          	addi	s8,s8,586 # 80008570 <syscalls+0xd8>
    initlock(&bcache[i].lock, bcache[i].name);
    for (int j = 0; j < NSIZE; j++) {
      b = &bcache[i].buf[j];
      b->refcnt = 0;
      initsleeplock(&b->lock, "buffer");
    8000332e:	00005a97          	auipc	s5,0x5
    80003332:	252a8a93          	addi	s5,s5,594 # 80008580 <syscalls+0xe8>
      b->timestamp = ticks;
    80003336:	00006a17          	auipc	s4,0x6
    8000333a:	ceaa0a13          	addi	s4,s4,-790 # 80009020 <ticks>
    8000333e:	6b05                	lui	s6,0x1
    80003340:	900b0b13          	addi	s6,s6,-1792 # 900 <_entry-0x7ffff700>
  for (int i = 0; i < NBUCKETS; i++) {
    80003344:	06b00b93          	li	s7,107
    snprintf(bcache[i].name, 10, "bcache%d", i);
    80003348:	b7848993          	addi	s3,s1,-1160
    8000334c:	86ca                	mv	a3,s2
    8000334e:	8662                	mv	a2,s8
    80003350:	45a9                	li	a1,10
    80003352:	854e                	mv	a0,s3
    80003354:	00003097          	auipc	ra,0x3
    80003358:	7f0080e7          	jalr	2032(ra) # 80006b44 <snprintf>
    initlock(&bcache[i].lock, bcache[i].name);
    8000335c:	85ce                	mv	a1,s3
    8000335e:	b5848513          	addi	a0,s1,-1192
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	cb0080e7          	jalr	-848(ra) # 80001012 <initlock>
      b->refcnt = 0;
    8000336a:	bc04a823          	sw	zero,-1072(s1)
      initsleeplock(&b->lock, "buffer");
    8000336e:	85d6                	mv	a1,s5
    80003370:	b9848513          	addi	a0,s1,-1128
    80003374:	00001097          	auipc	ra,0x1
    80003378:	634080e7          	jalr	1588(ra) # 800049a8 <initsleeplock>
      b->timestamp = ticks;
    8000337c:	000a2783          	lw	a5,0(s4)
    80003380:	fef4a423          	sw	a5,-24(s1)
      b->refcnt = 0;
    80003384:	0204ac23          	sw	zero,56(s1)
      initsleeplock(&b->lock, "buffer");
    80003388:	85d6                	mv	a1,s5
    8000338a:	8526                	mv	a0,s1
    8000338c:	00001097          	auipc	ra,0x1
    80003390:	61c080e7          	jalr	1564(ra) # 800049a8 <initsleeplock>
      b->timestamp = ticks;
    80003394:	000a2783          	lw	a5,0(s4)
    80003398:	44f4a823          	sw	a5,1104(s1)
  for (int i = 0; i < NBUCKETS; i++) {
    8000339c:	2905                	addiw	s2,s2,1
    8000339e:	94da                	add	s1,s1,s6
    800033a0:	fb7914e3          	bne	s2,s7,80003348 <binit+0x44>
    }
  }
}
    800033a4:	60a6                	ld	ra,72(sp)
    800033a6:	6406                	ld	s0,64(sp)
    800033a8:	74e2                	ld	s1,56(sp)
    800033aa:	7942                	ld	s2,48(sp)
    800033ac:	79a2                	ld	s3,40(sp)
    800033ae:	7a02                	ld	s4,32(sp)
    800033b0:	6ae2                	ld	s5,24(sp)
    800033b2:	6b42                	ld	s6,16(sp)
    800033b4:	6ba2                	ld	s7,8(sp)
    800033b6:	6c02                	ld	s8,0(sp)
    800033b8:	6161                	addi	sp,sp,80
    800033ba:	8082                	ret

00000000800033bc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033bc:	7139                	addi	sp,sp,-64
    800033be:	fc06                	sd	ra,56(sp)
    800033c0:	f822                	sd	s0,48(sp)
    800033c2:	f426                	sd	s1,40(sp)
    800033c4:	f04a                	sd	s2,32(sp)
    800033c6:	ec4e                	sd	s3,24(sp)
    800033c8:	e852                	sd	s4,16(sp)
    800033ca:	e456                	sd	s5,8(sp)
    800033cc:	e05a                	sd	s6,0(sp)
    800033ce:	0080                	addi	s0,sp,64
    800033d0:	8aaa                	mv	s5,a0
    800033d2:	8b2e                	mv	s6,a1
  return blockno % NBUCKETS;
    800033d4:	06b00493          	li	s1,107
    800033d8:	0295f4bb          	remuw	s1,a1,s1
  acquire(&bcache[id].lock);
    800033dc:	00349993          	slli	s3,s1,0x3
    800033e0:	99a6                	add	s3,s3,s1
    800033e2:	09a2                	slli	s3,s3,0x8
    800033e4:	00015a17          	auipc	s4,0x15
    800033e8:	034a0a13          	addi	s4,s4,52 # 80018418 <bcache>
    800033ec:	9a4e                	add	s4,s4,s3
    800033ee:	8552                	mv	a0,s4
    800033f0:	ffffe097          	auipc	ra,0xffffe
    800033f4:	a96080e7          	jalr	-1386(ra) # 80000e86 <acquire>
    if(b->dev == dev && b->blockno == blockno){
    800033f8:	038a2783          	lw	a5,56(s4)
    800033fc:	07578463          	beq	a5,s5,80003464 <bread+0xa8>
    80003400:	00349793          	slli	a5,s1,0x3
    80003404:	97a6                	add	a5,a5,s1
    80003406:	07a2                	slli	a5,a5,0x8
    80003408:	00015717          	auipc	a4,0x15
    8000340c:	01070713          	addi	a4,a4,16 # 80018418 <bcache>
    80003410:	97ba                	add	a5,a5,a4
    80003412:	4a07a783          	lw	a5,1184(a5)
    80003416:	0b578063          	beq	a5,s5,800034b6 <bread+0xfa>
    if (b->refcnt == 0 && b->timestamp < min) {
    8000341a:	00349793          	slli	a5,s1,0x3
    8000341e:	97a6                	add	a5,a5,s1
    80003420:	07a2                	slli	a5,a5,0x8
    80003422:	00015717          	auipc	a4,0x15
    80003426:	ff670713          	addi	a4,a4,-10 # 80018418 <bcache>
    8000342a:	97ba                	add	a5,a5,a4
    8000342c:	5fbc                	lw	a5,120(a5)
    8000342e:	e3e9                	bnez	a5,800034f0 <bread+0x134>
    80003430:	00349793          	slli	a5,s1,0x3
    80003434:	97a6                	add	a5,a5,s1
    80003436:	07a2                	slli	a5,a5,0x8
    80003438:	97ba                	add	a5,a5,a4
    8000343a:	4907a783          	lw	a5,1168(a5)
    8000343e:	577d                	li	a4,-1
    80003440:	0ae78863          	beq	a5,a4,800034f0 <bread+0x134>
    b = &bcache[id].buf[i];
    80003444:	03098913          	addi	s2,s3,48
    80003448:	00015697          	auipc	a3,0x15
    8000344c:	fd068693          	addi	a3,a3,-48 # 80018418 <bcache>
    80003450:	9936                	add	s2,s2,a3
    if (b->refcnt == 0 && b->timestamp < min) {
    80003452:	00349713          	slli	a4,s1,0x3
    80003456:	9726                	add	a4,a4,s1
    80003458:	0722                	slli	a4,a4,0x8
    8000345a:	9736                	add	a4,a4,a3
    8000345c:	4e072703          	lw	a4,1248(a4)
    80003460:	ef71                	bnez	a4,8000353c <bread+0x180>
    80003462:	a06d                	j	8000350c <bread+0x150>
    if(b->dev == dev && b->blockno == blockno){
    80003464:	03ca2783          	lw	a5,60(s4)
    80003468:	f9679ce3          	bne	a5,s6,80003400 <bread+0x44>
  for(int i = 0; i < NSIZE; i++){
    8000346c:	4a81                	li	s5,0
    8000346e:	46800793          	li	a5,1128
    80003472:	02fa8ab3          	mul	s5,s5,a5
    b = &bcache[id].buf[i];
    80003476:	03098913          	addi	s2,s3,48
    8000347a:	9956                	add	s2,s2,s5
    8000347c:	00015b17          	auipc	s6,0x15
    80003480:	f9cb0b13          	addi	s6,s6,-100 # 80018418 <bcache>
    80003484:	995a                	add	s2,s2,s6
      b->refcnt++;
    80003486:	00349793          	slli	a5,s1,0x3
    8000348a:	00978733          	add	a4,a5,s1
    8000348e:	0722                	slli	a4,a4,0x8
    80003490:	9756                	add	a4,a4,s5
    80003492:	975a                	add	a4,a4,s6
    80003494:	5f3c                	lw	a5,120(a4)
    80003496:	2785                	addiw	a5,a5,1
    80003498:	df3c                	sw	a5,120(a4)
      release(&bcache[id].lock);
    8000349a:	8552                	mv	a0,s4
    8000349c:	ffffe097          	auipc	ra,0xffffe
    800034a0:	aba080e7          	jalr	-1350(ra) # 80000f56 <release>
      acquiresleep(&b->lock);
    800034a4:	04098513          	addi	a0,s3,64
    800034a8:	9556                	add	a0,a0,s5
    800034aa:	955a                	add	a0,a0,s6
    800034ac:	00001097          	auipc	ra,0x1
    800034b0:	536080e7          	jalr	1334(ra) # 800049e2 <acquiresleep>
      return b;
    800034b4:	a845                	j	80003564 <bread+0x1a8>
    if(b->dev == dev && b->blockno == blockno){
    800034b6:	00349793          	slli	a5,s1,0x3
    800034ba:	97a6                	add	a5,a5,s1
    800034bc:	07a2                	slli	a5,a5,0x8
    800034be:	97ba                	add	a5,a5,a4
    800034c0:	4a47a783          	lw	a5,1188(a5)
    800034c4:	f5679be3          	bne	a5,s6,8000341a <bread+0x5e>
  for(int i = 0; i < NSIZE; i++){
    800034c8:	4a85                	li	s5,1
    800034ca:	b755                	j	8000346e <bread+0xb2>
  panic("bget: no buffers");
    800034cc:	00005517          	auipc	a0,0x5
    800034d0:	0bc50513          	addi	a0,a0,188 # 80008588 <syscalls+0xf0>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	0a4080e7          	jalr	164(ra) # 80000578 <panic>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    800034dc:	4581                	li	a1,0
    800034de:	854a                	mv	a0,s2
    800034e0:	00003097          	auipc	ra,0x3
    800034e4:	0e6080e7          	jalr	230(ra) # 800065c6 <virtio_disk_rw>
    b->valid = 1;
    800034e8:	4785                	li	a5,1
    800034ea:	00f92023          	sw	a5,0(s2)
  }
  return b;
    800034ee:	a8b5                	j	8000356a <bread+0x1ae>
    if (b->refcnt == 0 && b->timestamp < min) {
    800034f0:	00349793          	slli	a5,s1,0x3
    800034f4:	97a6                	add	a5,a5,s1
    800034f6:	07a2                	slli	a5,a5,0x8
    800034f8:	00015717          	auipc	a4,0x15
    800034fc:	f2070713          	addi	a4,a4,-224 # 80018418 <bcache>
    80003500:	97ba                	add	a5,a5,a4
    80003502:	4e07a703          	lw	a4,1248(a5)
    80003506:	4901                	li	s2,0
    80003508:	57fd                	li	a5,-1
    8000350a:	f369                	bnez	a4,800034cc <bread+0x110>
    8000350c:	00349713          	slli	a4,s1,0x3
    80003510:	94ba                	add	s1,s1,a4
    80003512:	04a2                	slli	s1,s1,0x8
    80003514:	00015717          	auipc	a4,0x15
    80003518:	f0470713          	addi	a4,a4,-252 # 80018418 <bcache>
    8000351c:	9726                	add	a4,a4,s1
    8000351e:	6485                	lui	s1,0x1
    80003520:	94ba                	add	s1,s1,a4
    80003522:	8f84a703          	lw	a4,-1800(s1) # 8f8 <_entry-0x7ffff708>
    80003526:	00f77863          	bleu	a5,a4,80003536 <bread+0x17a>
    b = &bcache[id].buf[i];
    8000352a:	00015917          	auipc	s2,0x15
    8000352e:	38690913          	addi	s2,s2,902 # 800188b0 <bcache+0x498>
    80003532:	994e                	add	s2,s2,s3
    if (b->refcnt == 0 && b->timestamp < min) {
    80003534:	87ba                	mv	a5,a4
  if (min != -1) {
    80003536:	577d                	li	a4,-1
    80003538:	f8e78ae3          	beq	a5,a4,800034cc <bread+0x110>
    tmp->dev = dev;
    8000353c:	01592423          	sw	s5,8(s2)
    tmp->blockno = blockno;
    80003540:	01692623          	sw	s6,12(s2)
    tmp->valid = 0;
    80003544:	00092023          	sw	zero,0(s2)
    tmp->refcnt = 1;
    80003548:	4785                	li	a5,1
    8000354a:	04f92423          	sw	a5,72(s2)
    release(&bcache[id].lock);
    8000354e:	8552                	mv	a0,s4
    80003550:	ffffe097          	auipc	ra,0xffffe
    80003554:	a06080e7          	jalr	-1530(ra) # 80000f56 <release>
    acquiresleep(&tmp->lock);
    80003558:	01090513          	addi	a0,s2,16
    8000355c:	00001097          	auipc	ra,0x1
    80003560:	486080e7          	jalr	1158(ra) # 800049e2 <acquiresleep>
  if(!b->valid) {
    80003564:	00092783          	lw	a5,0(s2)
    80003568:	dbb5                	beqz	a5,800034dc <bread+0x120>
}
    8000356a:	854a                	mv	a0,s2
    8000356c:	70e2                	ld	ra,56(sp)
    8000356e:	7442                	ld	s0,48(sp)
    80003570:	74a2                	ld	s1,40(sp)
    80003572:	7902                	ld	s2,32(sp)
    80003574:	69e2                	ld	s3,24(sp)
    80003576:	6a42                	ld	s4,16(sp)
    80003578:	6aa2                	ld	s5,8(sp)
    8000357a:	6b02                	ld	s6,0(sp)
    8000357c:	6121                	addi	sp,sp,64
    8000357e:	8082                	ret

0000000080003580 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003580:	1101                	addi	sp,sp,-32
    80003582:	ec06                	sd	ra,24(sp)
    80003584:	e822                	sd	s0,16(sp)
    80003586:	e426                	sd	s1,8(sp)
    80003588:	1000                	addi	s0,sp,32
    8000358a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000358c:	0541                	addi	a0,a0,16
    8000358e:	00001097          	auipc	ra,0x1
    80003592:	4ee080e7          	jalr	1262(ra) # 80004a7c <holdingsleep>
    80003596:	cd01                	beqz	a0,800035ae <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003598:	4585                	li	a1,1
    8000359a:	8526                	mv	a0,s1
    8000359c:	00003097          	auipc	ra,0x3
    800035a0:	02a080e7          	jalr	42(ra) # 800065c6 <virtio_disk_rw>
}
    800035a4:	60e2                	ld	ra,24(sp)
    800035a6:	6442                	ld	s0,16(sp)
    800035a8:	64a2                	ld	s1,8(sp)
    800035aa:	6105                	addi	sp,sp,32
    800035ac:	8082                	ret
    panic("bwrite");
    800035ae:	00005517          	auipc	a0,0x5
    800035b2:	ff250513          	addi	a0,a0,-14 # 800085a0 <syscalls+0x108>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	fc2080e7          	jalr	-62(ra) # 80000578 <panic>

00000000800035be <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035be:	1101                	addi	sp,sp,-32
    800035c0:	ec06                	sd	ra,24(sp)
    800035c2:	e822                	sd	s0,16(sp)
    800035c4:	e426                	sd	s1,8(sp)
    800035c6:	e04a                	sd	s2,0(sp)
    800035c8:	1000                	addi	s0,sp,32
    800035ca:	892a                	mv	s2,a0
  if(!holdingsleep(&b->lock))
    800035cc:	01050493          	addi	s1,a0,16
    800035d0:	8526                	mv	a0,s1
    800035d2:	00001097          	auipc	ra,0x1
    800035d6:	4aa080e7          	jalr	1194(ra) # 80004a7c <holdingsleep>
    800035da:	c525                	beqz	a0,80003642 <brelse+0x84>
    panic("brelse");

  releasesleep(&b->lock);
    800035dc:	8526                	mv	a0,s1
    800035de:	00001097          	auipc	ra,0x1
    800035e2:	45a080e7          	jalr	1114(ra) # 80004a38 <releasesleep>
  return blockno % NBUCKETS;
    800035e6:	00c92483          	lw	s1,12(s2)

  int id = hash(b->dev, b->blockno);
  acquire(&bcache[id].lock);
    800035ea:	06b00793          	li	a5,107
    800035ee:	02f4f7bb          	remuw	a5,s1,a5
    800035f2:	00379493          	slli	s1,a5,0x3
    800035f6:	94be                	add	s1,s1,a5
    800035f8:	04a2                	slli	s1,s1,0x8
    800035fa:	00015797          	auipc	a5,0x15
    800035fe:	e1e78793          	addi	a5,a5,-482 # 80018418 <bcache>
    80003602:	94be                	add	s1,s1,a5
    80003604:	8526                	mv	a0,s1
    80003606:	ffffe097          	auipc	ra,0xffffe
    8000360a:	880080e7          	jalr	-1920(ra) # 80000e86 <acquire>
  b->refcnt--;
    8000360e:	04892783          	lw	a5,72(s2)
    80003612:	37fd                	addiw	a5,a5,-1
    80003614:	0007871b          	sext.w	a4,a5
    80003618:	04f92423          	sw	a5,72(s2)
  if (b->refcnt == 0) {
    8000361c:	eb01                	bnez	a4,8000362c <brelse+0x6e>
    // no one is waiting for it.
    b->timestamp = ticks;
    8000361e:	00006797          	auipc	a5,0x6
    80003622:	a0278793          	addi	a5,a5,-1534 # 80009020 <ticks>
    80003626:	439c                	lw	a5,0(a5)
    80003628:	46f92023          	sw	a5,1120(s2)
  }
  
  release(&bcache[id].lock);
    8000362c:	8526                	mv	a0,s1
    8000362e:	ffffe097          	auipc	ra,0xffffe
    80003632:	928080e7          	jalr	-1752(ra) # 80000f56 <release>
}
    80003636:	60e2                	ld	ra,24(sp)
    80003638:	6442                	ld	s0,16(sp)
    8000363a:	64a2                	ld	s1,8(sp)
    8000363c:	6902                	ld	s2,0(sp)
    8000363e:	6105                	addi	sp,sp,32
    80003640:	8082                	ret
    panic("brelse");
    80003642:	00005517          	auipc	a0,0x5
    80003646:	f6650513          	addi	a0,a0,-154 # 800085a8 <syscalls+0x110>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	f2e080e7          	jalr	-210(ra) # 80000578 <panic>

0000000080003652 <bpin>:

void
bpin(struct buf *b) {
    80003652:	1101                	addi	sp,sp,-32
    80003654:	ec06                	sd	ra,24(sp)
    80003656:	e822                	sd	s0,16(sp)
    80003658:	e426                	sd	s1,8(sp)
    8000365a:	e04a                	sd	s2,0(sp)
    8000365c:	1000                	addi	s0,sp,32
    8000365e:	892a                	mv	s2,a0
  return blockno % NBUCKETS;
    80003660:	4544                	lw	s1,12(a0)
  int id = hash(b->dev, b->blockno);
  acquire(&bcache[id].lock);
    80003662:	06b00793          	li	a5,107
    80003666:	02f4f7bb          	remuw	a5,s1,a5
    8000366a:	00379493          	slli	s1,a5,0x3
    8000366e:	94be                	add	s1,s1,a5
    80003670:	04a2                	slli	s1,s1,0x8
    80003672:	00015797          	auipc	a5,0x15
    80003676:	da678793          	addi	a5,a5,-602 # 80018418 <bcache>
    8000367a:	94be                	add	s1,s1,a5
    8000367c:	8526                	mv	a0,s1
    8000367e:	ffffe097          	auipc	ra,0xffffe
    80003682:	808080e7          	jalr	-2040(ra) # 80000e86 <acquire>
  b->refcnt++;
    80003686:	04892783          	lw	a5,72(s2)
    8000368a:	2785                	addiw	a5,a5,1
    8000368c:	04f92423          	sw	a5,72(s2)
  release(&bcache[id].lock);
    80003690:	8526                	mv	a0,s1
    80003692:	ffffe097          	auipc	ra,0xffffe
    80003696:	8c4080e7          	jalr	-1852(ra) # 80000f56 <release>
}
    8000369a:	60e2                	ld	ra,24(sp)
    8000369c:	6442                	ld	s0,16(sp)
    8000369e:	64a2                	ld	s1,8(sp)
    800036a0:	6902                	ld	s2,0(sp)
    800036a2:	6105                	addi	sp,sp,32
    800036a4:	8082                	ret

00000000800036a6 <bunpin>:

void
bunpin(struct buf *b) {
    800036a6:	1101                	addi	sp,sp,-32
    800036a8:	ec06                	sd	ra,24(sp)
    800036aa:	e822                	sd	s0,16(sp)
    800036ac:	e426                	sd	s1,8(sp)
    800036ae:	e04a                	sd	s2,0(sp)
    800036b0:	1000                	addi	s0,sp,32
    800036b2:	892a                	mv	s2,a0
  return blockno % NBUCKETS;
    800036b4:	4544                	lw	s1,12(a0)
  int id = hash(b->dev, b->blockno);
  acquire(&bcache[id].lock);
    800036b6:	06b00793          	li	a5,107
    800036ba:	02f4f7bb          	remuw	a5,s1,a5
    800036be:	00379493          	slli	s1,a5,0x3
    800036c2:	94be                	add	s1,s1,a5
    800036c4:	04a2                	slli	s1,s1,0x8
    800036c6:	00015797          	auipc	a5,0x15
    800036ca:	d5278793          	addi	a5,a5,-686 # 80018418 <bcache>
    800036ce:	94be                	add	s1,s1,a5
    800036d0:	8526                	mv	a0,s1
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	7b4080e7          	jalr	1972(ra) # 80000e86 <acquire>
  b->refcnt--;
    800036da:	04892783          	lw	a5,72(s2)
    800036de:	37fd                	addiw	a5,a5,-1
    800036e0:	04f92423          	sw	a5,72(s2)
  release(&bcache[id].lock);
    800036e4:	8526                	mv	a0,s1
    800036e6:	ffffe097          	auipc	ra,0xffffe
    800036ea:	870080e7          	jalr	-1936(ra) # 80000f56 <release>
}
    800036ee:	60e2                	ld	ra,24(sp)
    800036f0:	6442                	ld	s0,16(sp)
    800036f2:	64a2                	ld	s1,8(sp)
    800036f4:	6902                	ld	s2,0(sp)
    800036f6:	6105                	addi	sp,sp,32
    800036f8:	8082                	ret

00000000800036fa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036fa:	1101                	addi	sp,sp,-32
    800036fc:	ec06                	sd	ra,24(sp)
    800036fe:	e822                	sd	s0,16(sp)
    80003700:	e426                	sd	s1,8(sp)
    80003702:	e04a                	sd	s2,0(sp)
    80003704:	1000                	addi	s0,sp,32
    80003706:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003708:	00d5d59b          	srliw	a1,a1,0xd
    8000370c:	00051797          	auipc	a5,0x51
    80003710:	00c78793          	addi	a5,a5,12 # 80054718 <sb>
    80003714:	4fdc                	lw	a5,28(a5)
    80003716:	9dbd                	addw	a1,a1,a5
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	ca4080e7          	jalr	-860(ra) # 800033bc <bread>
  bi = b % BPB;
    80003720:	2481                	sext.w	s1,s1
  m = 1 << (bi % 8);
    80003722:	0074f793          	andi	a5,s1,7
    80003726:	4705                	li	a4,1
    80003728:	00f7173b          	sllw	a4,a4,a5
  bi = b % BPB;
    8000372c:	6789                	lui	a5,0x2
    8000372e:	17fd                	addi	a5,a5,-1
    80003730:	8cfd                	and	s1,s1,a5
  if((bp->data[bi/8] & m) == 0)
    80003732:	41f4d79b          	sraiw	a5,s1,0x1f
    80003736:	01d7d79b          	srliw	a5,a5,0x1d
    8000373a:	9fa5                	addw	a5,a5,s1
    8000373c:	4037d79b          	sraiw	a5,a5,0x3
    80003740:	00f506b3          	add	a3,a0,a5
    80003744:	0606c683          	lbu	a3,96(a3)
    80003748:	00d77633          	and	a2,a4,a3
    8000374c:	c61d                	beqz	a2,8000377a <bfree+0x80>
    8000374e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003750:	97aa                	add	a5,a5,a0
    80003752:	fff74713          	not	a4,a4
    80003756:	8f75                	and	a4,a4,a3
    80003758:	06e78023          	sb	a4,96(a5) # 2060 <_entry-0x7fffdfa0>
  log_write(bp);
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	148080e7          	jalr	328(ra) # 800048a4 <log_write>
  brelse(bp);
    80003764:	854a                	mv	a0,s2
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	e58080e7          	jalr	-424(ra) # 800035be <brelse>
}
    8000376e:	60e2                	ld	ra,24(sp)
    80003770:	6442                	ld	s0,16(sp)
    80003772:	64a2                	ld	s1,8(sp)
    80003774:	6902                	ld	s2,0(sp)
    80003776:	6105                	addi	sp,sp,32
    80003778:	8082                	ret
    panic("freeing free block");
    8000377a:	00005517          	auipc	a0,0x5
    8000377e:	e3650513          	addi	a0,a0,-458 # 800085b0 <syscalls+0x118>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	df6080e7          	jalr	-522(ra) # 80000578 <panic>

000000008000378a <balloc>:
{
    8000378a:	711d                	addi	sp,sp,-96
    8000378c:	ec86                	sd	ra,88(sp)
    8000378e:	e8a2                	sd	s0,80(sp)
    80003790:	e4a6                	sd	s1,72(sp)
    80003792:	e0ca                	sd	s2,64(sp)
    80003794:	fc4e                	sd	s3,56(sp)
    80003796:	f852                	sd	s4,48(sp)
    80003798:	f456                	sd	s5,40(sp)
    8000379a:	f05a                	sd	s6,32(sp)
    8000379c:	ec5e                	sd	s7,24(sp)
    8000379e:	e862                	sd	s8,16(sp)
    800037a0:	e466                	sd	s9,8(sp)
    800037a2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037a4:	00051797          	auipc	a5,0x51
    800037a8:	f7478793          	addi	a5,a5,-140 # 80054718 <sb>
    800037ac:	43dc                	lw	a5,4(a5)
    800037ae:	10078e63          	beqz	a5,800038ca <balloc+0x140>
    800037b2:	8baa                	mv	s7,a0
    800037b4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037b6:	00051b17          	auipc	s6,0x51
    800037ba:	f62b0b13          	addi	s6,s6,-158 # 80054718 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037be:	4c05                	li	s8,1
      m = 1 << (bi % 8);
    800037c0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037c4:	6c89                	lui	s9,0x2
    800037c6:	a079                	j	80003854 <balloc+0xca>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c8:	8942                	mv	s2,a6
      m = 1 << (bi % 8);
    800037ca:	4705                	li	a4,1
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037cc:	4681                	li	a3,0
        bp->data[bi/8] |= m;  // Mark block in use.
    800037ce:	96a6                	add	a3,a3,s1
    800037d0:	8f51                	or	a4,a4,a2
    800037d2:	06e68023          	sb	a4,96(a3)
        log_write(bp);
    800037d6:	8526                	mv	a0,s1
    800037d8:	00001097          	auipc	ra,0x1
    800037dc:	0cc080e7          	jalr	204(ra) # 800048a4 <log_write>
        brelse(bp);
    800037e0:	8526                	mv	a0,s1
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	ddc080e7          	jalr	-548(ra) # 800035be <brelse>
  bp = bread(dev, bno);
    800037ea:	85ca                	mv	a1,s2
    800037ec:	855e                	mv	a0,s7
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	bce080e7          	jalr	-1074(ra) # 800033bc <bread>
    800037f6:	84aa                	mv	s1,a0
  memset(bp->data, 0, BSIZE);
    800037f8:	40000613          	li	a2,1024
    800037fc:	4581                	li	a1,0
    800037fe:	06050513          	addi	a0,a0,96
    80003802:	ffffe097          	auipc	ra,0xffffe
    80003806:	a90080e7          	jalr	-1392(ra) # 80001292 <memset>
  log_write(bp);
    8000380a:	8526                	mv	a0,s1
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	098080e7          	jalr	152(ra) # 800048a4 <log_write>
  brelse(bp);
    80003814:	8526                	mv	a0,s1
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	da8080e7          	jalr	-600(ra) # 800035be <brelse>
}
    8000381e:	854a                	mv	a0,s2
    80003820:	60e6                	ld	ra,88(sp)
    80003822:	6446                	ld	s0,80(sp)
    80003824:	64a6                	ld	s1,72(sp)
    80003826:	6906                	ld	s2,64(sp)
    80003828:	79e2                	ld	s3,56(sp)
    8000382a:	7a42                	ld	s4,48(sp)
    8000382c:	7aa2                	ld	s5,40(sp)
    8000382e:	7b02                	ld	s6,32(sp)
    80003830:	6be2                	ld	s7,24(sp)
    80003832:	6c42                	ld	s8,16(sp)
    80003834:	6ca2                	ld	s9,8(sp)
    80003836:	6125                	addi	sp,sp,96
    80003838:	8082                	ret
    brelse(bp);
    8000383a:	8526                	mv	a0,s1
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	d82080e7          	jalr	-638(ra) # 800035be <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003844:	015c87bb          	addw	a5,s9,s5
    80003848:	00078a9b          	sext.w	s5,a5
    8000384c:	004b2703          	lw	a4,4(s6)
    80003850:	06eafd63          	bleu	a4,s5,800038ca <balloc+0x140>
    bp = bread(dev, BBLOCK(b, sb));
    80003854:	41fad79b          	sraiw	a5,s5,0x1f
    80003858:	0137d79b          	srliw	a5,a5,0x13
    8000385c:	015787bb          	addw	a5,a5,s5
    80003860:	40d7d79b          	sraiw	a5,a5,0xd
    80003864:	01cb2583          	lw	a1,28(s6)
    80003868:	9dbd                	addw	a1,a1,a5
    8000386a:	855e                	mv	a0,s7
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	b50080e7          	jalr	-1200(ra) # 800033bc <bread>
    80003874:	84aa                	mv	s1,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003876:	000a881b          	sext.w	a6,s5
    8000387a:	004b2503          	lw	a0,4(s6)
    8000387e:	faa87ee3          	bleu	a0,a6,8000383a <balloc+0xb0>
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003882:	0604c603          	lbu	a2,96(s1)
    80003886:	00167793          	andi	a5,a2,1
    8000388a:	df9d                	beqz	a5,800037c8 <balloc+0x3e>
    8000388c:	4105053b          	subw	a0,a0,a6
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003890:	87e2                	mv	a5,s8
    80003892:	0107893b          	addw	s2,a5,a6
    80003896:	faa782e3          	beq	a5,a0,8000383a <balloc+0xb0>
      m = 1 << (bi % 8);
    8000389a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000389e:	01d7561b          	srliw	a2,a4,0x1d
    800038a2:	00f606bb          	addw	a3,a2,a5
    800038a6:	0076f713          	andi	a4,a3,7
    800038aa:	9f11                	subw	a4,a4,a2
    800038ac:	00e9973b          	sllw	a4,s3,a4
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038b0:	4036d69b          	sraiw	a3,a3,0x3
    800038b4:	00d48633          	add	a2,s1,a3
    800038b8:	06064603          	lbu	a2,96(a2)
    800038bc:	00c775b3          	and	a1,a4,a2
    800038c0:	d599                	beqz	a1,800037ce <balloc+0x44>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038c2:	2785                	addiw	a5,a5,1
    800038c4:	fd4797e3          	bne	a5,s4,80003892 <balloc+0x108>
    800038c8:	bf8d                	j	8000383a <balloc+0xb0>
  panic("balloc: out of blocks");
    800038ca:	00005517          	auipc	a0,0x5
    800038ce:	cfe50513          	addi	a0,a0,-770 # 800085c8 <syscalls+0x130>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	ca6080e7          	jalr	-858(ra) # 80000578 <panic>

00000000800038da <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038da:	7179                	addi	sp,sp,-48
    800038dc:	f406                	sd	ra,40(sp)
    800038de:	f022                	sd	s0,32(sp)
    800038e0:	ec26                	sd	s1,24(sp)
    800038e2:	e84a                	sd	s2,16(sp)
    800038e4:	e44e                	sd	s3,8(sp)
    800038e6:	e052                	sd	s4,0(sp)
    800038e8:	1800                	addi	s0,sp,48
    800038ea:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038ec:	47ad                	li	a5,11
    800038ee:	04b7fe63          	bleu	a1,a5,8000394a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038f2:	ff45849b          	addiw	s1,a1,-12
    800038f6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038fa:	0ff00793          	li	a5,255
    800038fe:	0ae7e363          	bltu	a5,a4,800039a4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003902:	08852583          	lw	a1,136(a0)
    80003906:	c5ad                	beqz	a1,80003970 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003908:	0009a503          	lw	a0,0(s3)
    8000390c:	00000097          	auipc	ra,0x0
    80003910:	ab0080e7          	jalr	-1360(ra) # 800033bc <bread>
    80003914:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003916:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    8000391a:	02049593          	slli	a1,s1,0x20
    8000391e:	9181                	srli	a1,a1,0x20
    80003920:	058a                	slli	a1,a1,0x2
    80003922:	00b784b3          	add	s1,a5,a1
    80003926:	0004a903          	lw	s2,0(s1)
    8000392a:	04090d63          	beqz	s2,80003984 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000392e:	8552                	mv	a0,s4
    80003930:	00000097          	auipc	ra,0x0
    80003934:	c8e080e7          	jalr	-882(ra) # 800035be <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003938:	854a                	mv	a0,s2
    8000393a:	70a2                	ld	ra,40(sp)
    8000393c:	7402                	ld	s0,32(sp)
    8000393e:	64e2                	ld	s1,24(sp)
    80003940:	6942                	ld	s2,16(sp)
    80003942:	69a2                	ld	s3,8(sp)
    80003944:	6a02                	ld	s4,0(sp)
    80003946:	6145                	addi	sp,sp,48
    80003948:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000394a:	02059493          	slli	s1,a1,0x20
    8000394e:	9081                	srli	s1,s1,0x20
    80003950:	048a                	slli	s1,s1,0x2
    80003952:	94aa                	add	s1,s1,a0
    80003954:	0584a903          	lw	s2,88(s1)
    80003958:	fe0910e3          	bnez	s2,80003938 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000395c:	4108                	lw	a0,0(a0)
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	e2c080e7          	jalr	-468(ra) # 8000378a <balloc>
    80003966:	0005091b          	sext.w	s2,a0
    8000396a:	0524ac23          	sw	s2,88(s1)
    8000396e:	b7e9                	j	80003938 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003970:	4108                	lw	a0,0(a0)
    80003972:	00000097          	auipc	ra,0x0
    80003976:	e18080e7          	jalr	-488(ra) # 8000378a <balloc>
    8000397a:	0005059b          	sext.w	a1,a0
    8000397e:	08b9a423          	sw	a1,136(s3)
    80003982:	b759                	j	80003908 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003984:	0009a503          	lw	a0,0(s3)
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	e02080e7          	jalr	-510(ra) # 8000378a <balloc>
    80003990:	0005091b          	sext.w	s2,a0
    80003994:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    80003998:	8552                	mv	a0,s4
    8000399a:	00001097          	auipc	ra,0x1
    8000399e:	f0a080e7          	jalr	-246(ra) # 800048a4 <log_write>
    800039a2:	b771                	j	8000392e <bmap+0x54>
  panic("bmap: out of range");
    800039a4:	00005517          	auipc	a0,0x5
    800039a8:	c3c50513          	addi	a0,a0,-964 # 800085e0 <syscalls+0x148>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	bcc080e7          	jalr	-1076(ra) # 80000578 <panic>

00000000800039b4 <iget>:
{
    800039b4:	7179                	addi	sp,sp,-48
    800039b6:	f406                	sd	ra,40(sp)
    800039b8:	f022                	sd	s0,32(sp)
    800039ba:	ec26                	sd	s1,24(sp)
    800039bc:	e84a                	sd	s2,16(sp)
    800039be:	e44e                	sd	s3,8(sp)
    800039c0:	e052                	sd	s4,0(sp)
    800039c2:	1800                	addi	s0,sp,48
    800039c4:	89aa                	mv	s3,a0
    800039c6:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800039c8:	00051517          	auipc	a0,0x51
    800039cc:	d7050513          	addi	a0,a0,-656 # 80054738 <icache>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	4b6080e7          	jalr	1206(ra) # 80000e86 <acquire>
  empty = 0;
    800039d8:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800039da:	00051497          	auipc	s1,0x51
    800039de:	d7e48493          	addi	s1,s1,-642 # 80054758 <icache+0x20>
    800039e2:	00053697          	auipc	a3,0x53
    800039e6:	99668693          	addi	a3,a3,-1642 # 80056378 <log>
    800039ea:	a039                	j	800039f8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039ec:	02090b63          	beqz	s2,80003a22 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800039f0:	09048493          	addi	s1,s1,144
    800039f4:	02d48a63          	beq	s1,a3,80003a28 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039f8:	449c                	lw	a5,8(s1)
    800039fa:	fef059e3          	blez	a5,800039ec <iget+0x38>
    800039fe:	4098                	lw	a4,0(s1)
    80003a00:	ff3716e3          	bne	a4,s3,800039ec <iget+0x38>
    80003a04:	40d8                	lw	a4,4(s1)
    80003a06:	ff4713e3          	bne	a4,s4,800039ec <iget+0x38>
      ip->ref++;
    80003a0a:	2785                	addiw	a5,a5,1
    80003a0c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003a0e:	00051517          	auipc	a0,0x51
    80003a12:	d2a50513          	addi	a0,a0,-726 # 80054738 <icache>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	540080e7          	jalr	1344(ra) # 80000f56 <release>
      return ip;
    80003a1e:	8926                	mv	s2,s1
    80003a20:	a03d                	j	80003a4e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a22:	f7f9                	bnez	a5,800039f0 <iget+0x3c>
    80003a24:	8926                	mv	s2,s1
    80003a26:	b7e9                	j	800039f0 <iget+0x3c>
  if(empty == 0)
    80003a28:	02090c63          	beqz	s2,80003a60 <iget+0xac>
  ip->dev = dev;
    80003a2c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a30:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a34:	4785                	li	a5,1
    80003a36:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a3a:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    80003a3e:	00051517          	auipc	a0,0x51
    80003a42:	cfa50513          	addi	a0,a0,-774 # 80054738 <icache>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	510080e7          	jalr	1296(ra) # 80000f56 <release>
}
    80003a4e:	854a                	mv	a0,s2
    80003a50:	70a2                	ld	ra,40(sp)
    80003a52:	7402                	ld	s0,32(sp)
    80003a54:	64e2                	ld	s1,24(sp)
    80003a56:	6942                	ld	s2,16(sp)
    80003a58:	69a2                	ld	s3,8(sp)
    80003a5a:	6a02                	ld	s4,0(sp)
    80003a5c:	6145                	addi	sp,sp,48
    80003a5e:	8082                	ret
    panic("iget: no inodes");
    80003a60:	00005517          	auipc	a0,0x5
    80003a64:	b9850513          	addi	a0,a0,-1128 # 800085f8 <syscalls+0x160>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	b10080e7          	jalr	-1264(ra) # 80000578 <panic>

0000000080003a70 <fsinit>:
fsinit(int dev) {
    80003a70:	7179                	addi	sp,sp,-48
    80003a72:	f406                	sd	ra,40(sp)
    80003a74:	f022                	sd	s0,32(sp)
    80003a76:	ec26                	sd	s1,24(sp)
    80003a78:	e84a                	sd	s2,16(sp)
    80003a7a:	e44e                	sd	s3,8(sp)
    80003a7c:	1800                	addi	s0,sp,48
    80003a7e:	89aa                	mv	s3,a0
  bp = bread(dev, 1);
    80003a80:	4585                	li	a1,1
    80003a82:	00000097          	auipc	ra,0x0
    80003a86:	93a080e7          	jalr	-1734(ra) # 800033bc <bread>
    80003a8a:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a8c:	00051497          	auipc	s1,0x51
    80003a90:	c8c48493          	addi	s1,s1,-884 # 80054718 <sb>
    80003a94:	02000613          	li	a2,32
    80003a98:	06050593          	addi	a1,a0,96
    80003a9c:	8526                	mv	a0,s1
    80003a9e:	ffffe097          	auipc	ra,0xffffe
    80003aa2:	860080e7          	jalr	-1952(ra) # 800012fe <memmove>
  brelse(bp);
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	b16080e7          	jalr	-1258(ra) # 800035be <brelse>
  if(sb.magic != FSMAGIC)
    80003ab0:	4098                	lw	a4,0(s1)
    80003ab2:	102037b7          	lui	a5,0x10203
    80003ab6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003aba:	02f71263          	bne	a4,a5,80003ade <fsinit+0x6e>
  initlog(dev, &sb);
    80003abe:	00051597          	auipc	a1,0x51
    80003ac2:	c5a58593          	addi	a1,a1,-934 # 80054718 <sb>
    80003ac6:	854e                	mv	a0,s3
    80003ac8:	00001097          	auipc	ra,0x1
    80003acc:	b5a080e7          	jalr	-1190(ra) # 80004622 <initlog>
}
    80003ad0:	70a2                	ld	ra,40(sp)
    80003ad2:	7402                	ld	s0,32(sp)
    80003ad4:	64e2                	ld	s1,24(sp)
    80003ad6:	6942                	ld	s2,16(sp)
    80003ad8:	69a2                	ld	s3,8(sp)
    80003ada:	6145                	addi	sp,sp,48
    80003adc:	8082                	ret
    panic("invalid file system");
    80003ade:	00005517          	auipc	a0,0x5
    80003ae2:	b2a50513          	addi	a0,a0,-1238 # 80008608 <syscalls+0x170>
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	a92080e7          	jalr	-1390(ra) # 80000578 <panic>

0000000080003aee <iinit>:
{
    80003aee:	7179                	addi	sp,sp,-48
    80003af0:	f406                	sd	ra,40(sp)
    80003af2:	f022                	sd	s0,32(sp)
    80003af4:	ec26                	sd	s1,24(sp)
    80003af6:	e84a                	sd	s2,16(sp)
    80003af8:	e44e                	sd	s3,8(sp)
    80003afa:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003afc:	00005597          	auipc	a1,0x5
    80003b00:	b2458593          	addi	a1,a1,-1244 # 80008620 <syscalls+0x188>
    80003b04:	00051517          	auipc	a0,0x51
    80003b08:	c3450513          	addi	a0,a0,-972 # 80054738 <icache>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	506080e7          	jalr	1286(ra) # 80001012 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b14:	00051497          	auipc	s1,0x51
    80003b18:	c5448493          	addi	s1,s1,-940 # 80054768 <icache+0x30>
    80003b1c:	00053997          	auipc	s3,0x53
    80003b20:	86c98993          	addi	s3,s3,-1940 # 80056388 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003b24:	00005917          	auipc	s2,0x5
    80003b28:	b0490913          	addi	s2,s2,-1276 # 80008628 <syscalls+0x190>
    80003b2c:	85ca                	mv	a1,s2
    80003b2e:	8526                	mv	a0,s1
    80003b30:	00001097          	auipc	ra,0x1
    80003b34:	e78080e7          	jalr	-392(ra) # 800049a8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b38:	09048493          	addi	s1,s1,144
    80003b3c:	ff3498e3          	bne	s1,s3,80003b2c <iinit+0x3e>
}
    80003b40:	70a2                	ld	ra,40(sp)
    80003b42:	7402                	ld	s0,32(sp)
    80003b44:	64e2                	ld	s1,24(sp)
    80003b46:	6942                	ld	s2,16(sp)
    80003b48:	69a2                	ld	s3,8(sp)
    80003b4a:	6145                	addi	sp,sp,48
    80003b4c:	8082                	ret

0000000080003b4e <ialloc>:
{
    80003b4e:	715d                	addi	sp,sp,-80
    80003b50:	e486                	sd	ra,72(sp)
    80003b52:	e0a2                	sd	s0,64(sp)
    80003b54:	fc26                	sd	s1,56(sp)
    80003b56:	f84a                	sd	s2,48(sp)
    80003b58:	f44e                	sd	s3,40(sp)
    80003b5a:	f052                	sd	s4,32(sp)
    80003b5c:	ec56                	sd	s5,24(sp)
    80003b5e:	e85a                	sd	s6,16(sp)
    80003b60:	e45e                	sd	s7,8(sp)
    80003b62:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b64:	00051797          	auipc	a5,0x51
    80003b68:	bb478793          	addi	a5,a5,-1100 # 80054718 <sb>
    80003b6c:	47d8                	lw	a4,12(a5)
    80003b6e:	4785                	li	a5,1
    80003b70:	04e7fa63          	bleu	a4,a5,80003bc4 <ialloc+0x76>
    80003b74:	8a2a                	mv	s4,a0
    80003b76:	8b2e                	mv	s6,a1
    80003b78:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b7a:	00051997          	auipc	s3,0x51
    80003b7e:	b9e98993          	addi	s3,s3,-1122 # 80054718 <sb>
    80003b82:	00048a9b          	sext.w	s5,s1
    80003b86:	0044d593          	srli	a1,s1,0x4
    80003b8a:	0189a783          	lw	a5,24(s3)
    80003b8e:	9dbd                	addw	a1,a1,a5
    80003b90:	8552                	mv	a0,s4
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	82a080e7          	jalr	-2006(ra) # 800033bc <bread>
    80003b9a:	8baa                	mv	s7,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b9c:	06050913          	addi	s2,a0,96
    80003ba0:	00f4f793          	andi	a5,s1,15
    80003ba4:	079a                	slli	a5,a5,0x6
    80003ba6:	993e                	add	s2,s2,a5
    if(dip->type == 0){  // a free inode
    80003ba8:	00091783          	lh	a5,0(s2)
    80003bac:	c785                	beqz	a5,80003bd4 <ialloc+0x86>
    brelse(bp);
    80003bae:	00000097          	auipc	ra,0x0
    80003bb2:	a10080e7          	jalr	-1520(ra) # 800035be <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bb6:	0485                	addi	s1,s1,1
    80003bb8:	00c9a703          	lw	a4,12(s3)
    80003bbc:	0004879b          	sext.w	a5,s1
    80003bc0:	fce7e1e3          	bltu	a5,a4,80003b82 <ialloc+0x34>
  panic("ialloc: no inodes");
    80003bc4:	00005517          	auipc	a0,0x5
    80003bc8:	a6c50513          	addi	a0,a0,-1428 # 80008630 <syscalls+0x198>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	9ac080e7          	jalr	-1620(ra) # 80000578 <panic>
      memset(dip, 0, sizeof(*dip));
    80003bd4:	04000613          	li	a2,64
    80003bd8:	4581                	li	a1,0
    80003bda:	854a                	mv	a0,s2
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	6b6080e7          	jalr	1718(ra) # 80001292 <memset>
      dip->type = type;
    80003be4:	01691023          	sh	s6,0(s2)
      log_write(bp);   // mark it allocated on the disk
    80003be8:	855e                	mv	a0,s7
    80003bea:	00001097          	auipc	ra,0x1
    80003bee:	cba080e7          	jalr	-838(ra) # 800048a4 <log_write>
      brelse(bp);
    80003bf2:	855e                	mv	a0,s7
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	9ca080e7          	jalr	-1590(ra) # 800035be <brelse>
      return iget(dev, inum);
    80003bfc:	85d6                	mv	a1,s5
    80003bfe:	8552                	mv	a0,s4
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	db4080e7          	jalr	-588(ra) # 800039b4 <iget>
}
    80003c08:	60a6                	ld	ra,72(sp)
    80003c0a:	6406                	ld	s0,64(sp)
    80003c0c:	74e2                	ld	s1,56(sp)
    80003c0e:	7942                	ld	s2,48(sp)
    80003c10:	79a2                	ld	s3,40(sp)
    80003c12:	7a02                	ld	s4,32(sp)
    80003c14:	6ae2                	ld	s5,24(sp)
    80003c16:	6b42                	ld	s6,16(sp)
    80003c18:	6ba2                	ld	s7,8(sp)
    80003c1a:	6161                	addi	sp,sp,80
    80003c1c:	8082                	ret

0000000080003c1e <iupdate>:
{
    80003c1e:	1101                	addi	sp,sp,-32
    80003c20:	ec06                	sd	ra,24(sp)
    80003c22:	e822                	sd	s0,16(sp)
    80003c24:	e426                	sd	s1,8(sp)
    80003c26:	e04a                	sd	s2,0(sp)
    80003c28:	1000                	addi	s0,sp,32
    80003c2a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c2c:	415c                	lw	a5,4(a0)
    80003c2e:	0047d79b          	srliw	a5,a5,0x4
    80003c32:	00051717          	auipc	a4,0x51
    80003c36:	ae670713          	addi	a4,a4,-1306 # 80054718 <sb>
    80003c3a:	4f0c                	lw	a1,24(a4)
    80003c3c:	9dbd                	addw	a1,a1,a5
    80003c3e:	4108                	lw	a0,0(a0)
    80003c40:	fffff097          	auipc	ra,0xfffff
    80003c44:	77c080e7          	jalr	1916(ra) # 800033bc <bread>
    80003c48:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c4a:	06050513          	addi	a0,a0,96
    80003c4e:	40dc                	lw	a5,4(s1)
    80003c50:	8bbd                	andi	a5,a5,15
    80003c52:	079a                	slli	a5,a5,0x6
    80003c54:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c56:	04c49783          	lh	a5,76(s1)
    80003c5a:	00f51023          	sh	a5,0(a0)
  dip->major = ip->major;
    80003c5e:	04e49783          	lh	a5,78(s1)
    80003c62:	00f51123          	sh	a5,2(a0)
  dip->minor = ip->minor;
    80003c66:	05049783          	lh	a5,80(s1)
    80003c6a:	00f51223          	sh	a5,4(a0)
  dip->nlink = ip->nlink;
    80003c6e:	05249783          	lh	a5,82(s1)
    80003c72:	00f51323          	sh	a5,6(a0)
  dip->size = ip->size;
    80003c76:	48fc                	lw	a5,84(s1)
    80003c78:	c51c                	sw	a5,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c7a:	03400613          	li	a2,52
    80003c7e:	05848593          	addi	a1,s1,88
    80003c82:	0531                	addi	a0,a0,12
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	67a080e7          	jalr	1658(ra) # 800012fe <memmove>
  log_write(bp);
    80003c8c:	854a                	mv	a0,s2
    80003c8e:	00001097          	auipc	ra,0x1
    80003c92:	c16080e7          	jalr	-1002(ra) # 800048a4 <log_write>
  brelse(bp);
    80003c96:	854a                	mv	a0,s2
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	926080e7          	jalr	-1754(ra) # 800035be <brelse>
}
    80003ca0:	60e2                	ld	ra,24(sp)
    80003ca2:	6442                	ld	s0,16(sp)
    80003ca4:	64a2                	ld	s1,8(sp)
    80003ca6:	6902                	ld	s2,0(sp)
    80003ca8:	6105                	addi	sp,sp,32
    80003caa:	8082                	ret

0000000080003cac <idup>:
{
    80003cac:	1101                	addi	sp,sp,-32
    80003cae:	ec06                	sd	ra,24(sp)
    80003cb0:	e822                	sd	s0,16(sp)
    80003cb2:	e426                	sd	s1,8(sp)
    80003cb4:	1000                	addi	s0,sp,32
    80003cb6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003cb8:	00051517          	auipc	a0,0x51
    80003cbc:	a8050513          	addi	a0,a0,-1408 # 80054738 <icache>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	1c6080e7          	jalr	454(ra) # 80000e86 <acquire>
  ip->ref++;
    80003cc8:	449c                	lw	a5,8(s1)
    80003cca:	2785                	addiw	a5,a5,1
    80003ccc:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003cce:	00051517          	auipc	a0,0x51
    80003cd2:	a6a50513          	addi	a0,a0,-1430 # 80054738 <icache>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	280080e7          	jalr	640(ra) # 80000f56 <release>
}
    80003cde:	8526                	mv	a0,s1
    80003ce0:	60e2                	ld	ra,24(sp)
    80003ce2:	6442                	ld	s0,16(sp)
    80003ce4:	64a2                	ld	s1,8(sp)
    80003ce6:	6105                	addi	sp,sp,32
    80003ce8:	8082                	ret

0000000080003cea <ilock>:
{
    80003cea:	1101                	addi	sp,sp,-32
    80003cec:	ec06                	sd	ra,24(sp)
    80003cee:	e822                	sd	s0,16(sp)
    80003cf0:	e426                	sd	s1,8(sp)
    80003cf2:	e04a                	sd	s2,0(sp)
    80003cf4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cf6:	c115                	beqz	a0,80003d1a <ilock+0x30>
    80003cf8:	84aa                	mv	s1,a0
    80003cfa:	451c                	lw	a5,8(a0)
    80003cfc:	00f05f63          	blez	a5,80003d1a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d00:	0541                	addi	a0,a0,16
    80003d02:	00001097          	auipc	ra,0x1
    80003d06:	ce0080e7          	jalr	-800(ra) # 800049e2 <acquiresleep>
  if(ip->valid == 0){
    80003d0a:	44bc                	lw	a5,72(s1)
    80003d0c:	cf99                	beqz	a5,80003d2a <ilock+0x40>
}
    80003d0e:	60e2                	ld	ra,24(sp)
    80003d10:	6442                	ld	s0,16(sp)
    80003d12:	64a2                	ld	s1,8(sp)
    80003d14:	6902                	ld	s2,0(sp)
    80003d16:	6105                	addi	sp,sp,32
    80003d18:	8082                	ret
    panic("ilock");
    80003d1a:	00005517          	auipc	a0,0x5
    80003d1e:	92e50513          	addi	a0,a0,-1746 # 80008648 <syscalls+0x1b0>
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	856080e7          	jalr	-1962(ra) # 80000578 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d2a:	40dc                	lw	a5,4(s1)
    80003d2c:	0047d79b          	srliw	a5,a5,0x4
    80003d30:	00051717          	auipc	a4,0x51
    80003d34:	9e870713          	addi	a4,a4,-1560 # 80054718 <sb>
    80003d38:	4f0c                	lw	a1,24(a4)
    80003d3a:	9dbd                	addw	a1,a1,a5
    80003d3c:	4088                	lw	a0,0(s1)
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	67e080e7          	jalr	1662(ra) # 800033bc <bread>
    80003d46:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d48:	06050593          	addi	a1,a0,96
    80003d4c:	40dc                	lw	a5,4(s1)
    80003d4e:	8bbd                	andi	a5,a5,15
    80003d50:	079a                	slli	a5,a5,0x6
    80003d52:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d54:	00059783          	lh	a5,0(a1)
    80003d58:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003d5c:	00259783          	lh	a5,2(a1)
    80003d60:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003d64:	00459783          	lh	a5,4(a1)
    80003d68:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003d6c:	00659783          	lh	a5,6(a1)
    80003d70:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003d74:	459c                	lw	a5,8(a1)
    80003d76:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d78:	03400613          	li	a2,52
    80003d7c:	05b1                	addi	a1,a1,12
    80003d7e:	05848513          	addi	a0,s1,88
    80003d82:	ffffd097          	auipc	ra,0xffffd
    80003d86:	57c080e7          	jalr	1404(ra) # 800012fe <memmove>
    brelse(bp);
    80003d8a:	854a                	mv	a0,s2
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	832080e7          	jalr	-1998(ra) # 800035be <brelse>
    ip->valid = 1;
    80003d94:	4785                	li	a5,1
    80003d96:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003d98:	04c49783          	lh	a5,76(s1)
    80003d9c:	fbad                	bnez	a5,80003d0e <ilock+0x24>
      panic("ilock: no type");
    80003d9e:	00005517          	auipc	a0,0x5
    80003da2:	8b250513          	addi	a0,a0,-1870 # 80008650 <syscalls+0x1b8>
    80003da6:	ffffc097          	auipc	ra,0xffffc
    80003daa:	7d2080e7          	jalr	2002(ra) # 80000578 <panic>

0000000080003dae <iunlock>:
{
    80003dae:	1101                	addi	sp,sp,-32
    80003db0:	ec06                	sd	ra,24(sp)
    80003db2:	e822                	sd	s0,16(sp)
    80003db4:	e426                	sd	s1,8(sp)
    80003db6:	e04a                	sd	s2,0(sp)
    80003db8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dba:	c905                	beqz	a0,80003dea <iunlock+0x3c>
    80003dbc:	84aa                	mv	s1,a0
    80003dbe:	01050913          	addi	s2,a0,16
    80003dc2:	854a                	mv	a0,s2
    80003dc4:	00001097          	auipc	ra,0x1
    80003dc8:	cb8080e7          	jalr	-840(ra) # 80004a7c <holdingsleep>
    80003dcc:	cd19                	beqz	a0,80003dea <iunlock+0x3c>
    80003dce:	449c                	lw	a5,8(s1)
    80003dd0:	00f05d63          	blez	a5,80003dea <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003dd4:	854a                	mv	a0,s2
    80003dd6:	00001097          	auipc	ra,0x1
    80003dda:	c62080e7          	jalr	-926(ra) # 80004a38 <releasesleep>
}
    80003dde:	60e2                	ld	ra,24(sp)
    80003de0:	6442                	ld	s0,16(sp)
    80003de2:	64a2                	ld	s1,8(sp)
    80003de4:	6902                	ld	s2,0(sp)
    80003de6:	6105                	addi	sp,sp,32
    80003de8:	8082                	ret
    panic("iunlock");
    80003dea:	00005517          	auipc	a0,0x5
    80003dee:	87650513          	addi	a0,a0,-1930 # 80008660 <syscalls+0x1c8>
    80003df2:	ffffc097          	auipc	ra,0xffffc
    80003df6:	786080e7          	jalr	1926(ra) # 80000578 <panic>

0000000080003dfa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003dfa:	7179                	addi	sp,sp,-48
    80003dfc:	f406                	sd	ra,40(sp)
    80003dfe:	f022                	sd	s0,32(sp)
    80003e00:	ec26                	sd	s1,24(sp)
    80003e02:	e84a                	sd	s2,16(sp)
    80003e04:	e44e                	sd	s3,8(sp)
    80003e06:	e052                	sd	s4,0(sp)
    80003e08:	1800                	addi	s0,sp,48
    80003e0a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e0c:	05850493          	addi	s1,a0,88
    80003e10:	08850913          	addi	s2,a0,136
    80003e14:	a821                	j	80003e2c <itrunc+0x32>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    80003e16:	0009a503          	lw	a0,0(s3)
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	8e0080e7          	jalr	-1824(ra) # 800036fa <bfree>
      ip->addrs[i] = 0;
    80003e22:	0004a023          	sw	zero,0(s1)
  for(i = 0; i < NDIRECT; i++){
    80003e26:	0491                	addi	s1,s1,4
    80003e28:	01248563          	beq	s1,s2,80003e32 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e2c:	408c                	lw	a1,0(s1)
    80003e2e:	dde5                	beqz	a1,80003e26 <itrunc+0x2c>
    80003e30:	b7dd                	j	80003e16 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e32:	0889a583          	lw	a1,136(s3)
    80003e36:	e185                	bnez	a1,80003e56 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e38:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003e3c:	854e                	mv	a0,s3
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	de0080e7          	jalr	-544(ra) # 80003c1e <iupdate>
}
    80003e46:	70a2                	ld	ra,40(sp)
    80003e48:	7402                	ld	s0,32(sp)
    80003e4a:	64e2                	ld	s1,24(sp)
    80003e4c:	6942                	ld	s2,16(sp)
    80003e4e:	69a2                	ld	s3,8(sp)
    80003e50:	6a02                	ld	s4,0(sp)
    80003e52:	6145                	addi	sp,sp,48
    80003e54:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e56:	0009a503          	lw	a0,0(s3)
    80003e5a:	fffff097          	auipc	ra,0xfffff
    80003e5e:	562080e7          	jalr	1378(ra) # 800033bc <bread>
    80003e62:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e64:	06050493          	addi	s1,a0,96
    80003e68:	46050913          	addi	s2,a0,1120
    80003e6c:	a811                	j	80003e80 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e6e:	0009a503          	lw	a0,0(s3)
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	888080e7          	jalr	-1912(ra) # 800036fa <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e7a:	0491                	addi	s1,s1,4
    80003e7c:	01248563          	beq	s1,s2,80003e86 <itrunc+0x8c>
      if(a[j])
    80003e80:	408c                	lw	a1,0(s1)
    80003e82:	dde5                	beqz	a1,80003e7a <itrunc+0x80>
    80003e84:	b7ed                	j	80003e6e <itrunc+0x74>
    brelse(bp);
    80003e86:	8552                	mv	a0,s4
    80003e88:	fffff097          	auipc	ra,0xfffff
    80003e8c:	736080e7          	jalr	1846(ra) # 800035be <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e90:	0889a583          	lw	a1,136(s3)
    80003e94:	0009a503          	lw	a0,0(s3)
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	862080e7          	jalr	-1950(ra) # 800036fa <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ea0:	0809a423          	sw	zero,136(s3)
    80003ea4:	bf51                	j	80003e38 <itrunc+0x3e>

0000000080003ea6 <iput>:
{
    80003ea6:	1101                	addi	sp,sp,-32
    80003ea8:	ec06                	sd	ra,24(sp)
    80003eaa:	e822                	sd	s0,16(sp)
    80003eac:	e426                	sd	s1,8(sp)
    80003eae:	e04a                	sd	s2,0(sp)
    80003eb0:	1000                	addi	s0,sp,32
    80003eb2:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003eb4:	00051517          	auipc	a0,0x51
    80003eb8:	88450513          	addi	a0,a0,-1916 # 80054738 <icache>
    80003ebc:	ffffd097          	auipc	ra,0xffffd
    80003ec0:	fca080e7          	jalr	-54(ra) # 80000e86 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ec4:	4498                	lw	a4,8(s1)
    80003ec6:	4785                	li	a5,1
    80003ec8:	02f70363          	beq	a4,a5,80003eee <iput+0x48>
  ip->ref--;
    80003ecc:	449c                	lw	a5,8(s1)
    80003ece:	37fd                	addiw	a5,a5,-1
    80003ed0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003ed2:	00051517          	auipc	a0,0x51
    80003ed6:	86650513          	addi	a0,a0,-1946 # 80054738 <icache>
    80003eda:	ffffd097          	auipc	ra,0xffffd
    80003ede:	07c080e7          	jalr	124(ra) # 80000f56 <release>
}
    80003ee2:	60e2                	ld	ra,24(sp)
    80003ee4:	6442                	ld	s0,16(sp)
    80003ee6:	64a2                	ld	s1,8(sp)
    80003ee8:	6902                	ld	s2,0(sp)
    80003eea:	6105                	addi	sp,sp,32
    80003eec:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eee:	44bc                	lw	a5,72(s1)
    80003ef0:	dff1                	beqz	a5,80003ecc <iput+0x26>
    80003ef2:	05249783          	lh	a5,82(s1)
    80003ef6:	fbf9                	bnez	a5,80003ecc <iput+0x26>
    acquiresleep(&ip->lock);
    80003ef8:	01048913          	addi	s2,s1,16
    80003efc:	854a                	mv	a0,s2
    80003efe:	00001097          	auipc	ra,0x1
    80003f02:	ae4080e7          	jalr	-1308(ra) # 800049e2 <acquiresleep>
    release(&icache.lock);
    80003f06:	00051517          	auipc	a0,0x51
    80003f0a:	83250513          	addi	a0,a0,-1998 # 80054738 <icache>
    80003f0e:	ffffd097          	auipc	ra,0xffffd
    80003f12:	048080e7          	jalr	72(ra) # 80000f56 <release>
    itrunc(ip);
    80003f16:	8526                	mv	a0,s1
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	ee2080e7          	jalr	-286(ra) # 80003dfa <itrunc>
    ip->type = 0;
    80003f20:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003f24:	8526                	mv	a0,s1
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	cf8080e7          	jalr	-776(ra) # 80003c1e <iupdate>
    ip->valid = 0;
    80003f2e:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003f32:	854a                	mv	a0,s2
    80003f34:	00001097          	auipc	ra,0x1
    80003f38:	b04080e7          	jalr	-1276(ra) # 80004a38 <releasesleep>
    acquire(&icache.lock);
    80003f3c:	00050517          	auipc	a0,0x50
    80003f40:	7fc50513          	addi	a0,a0,2044 # 80054738 <icache>
    80003f44:	ffffd097          	auipc	ra,0xffffd
    80003f48:	f42080e7          	jalr	-190(ra) # 80000e86 <acquire>
    80003f4c:	b741                	j	80003ecc <iput+0x26>

0000000080003f4e <iunlockput>:
{
    80003f4e:	1101                	addi	sp,sp,-32
    80003f50:	ec06                	sd	ra,24(sp)
    80003f52:	e822                	sd	s0,16(sp)
    80003f54:	e426                	sd	s1,8(sp)
    80003f56:	1000                	addi	s0,sp,32
    80003f58:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	e54080e7          	jalr	-428(ra) # 80003dae <iunlock>
  iput(ip);
    80003f62:	8526                	mv	a0,s1
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	f42080e7          	jalr	-190(ra) # 80003ea6 <iput>
}
    80003f6c:	60e2                	ld	ra,24(sp)
    80003f6e:	6442                	ld	s0,16(sp)
    80003f70:	64a2                	ld	s1,8(sp)
    80003f72:	6105                	addi	sp,sp,32
    80003f74:	8082                	ret

0000000080003f76 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f76:	1141                	addi	sp,sp,-16
    80003f78:	e422                	sd	s0,8(sp)
    80003f7a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f7c:	411c                	lw	a5,0(a0)
    80003f7e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f80:	415c                	lw	a5,4(a0)
    80003f82:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f84:	04c51783          	lh	a5,76(a0)
    80003f88:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f8c:	05251783          	lh	a5,82(a0)
    80003f90:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f94:	05456783          	lwu	a5,84(a0)
    80003f98:	e99c                	sd	a5,16(a1)
}
    80003f9a:	6422                	ld	s0,8(sp)
    80003f9c:	0141                	addi	sp,sp,16
    80003f9e:	8082                	ret

0000000080003fa0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fa0:	497c                	lw	a5,84(a0)
    80003fa2:	0ed7e963          	bltu	a5,a3,80004094 <readi+0xf4>
{
    80003fa6:	7159                	addi	sp,sp,-112
    80003fa8:	f486                	sd	ra,104(sp)
    80003faa:	f0a2                	sd	s0,96(sp)
    80003fac:	eca6                	sd	s1,88(sp)
    80003fae:	e8ca                	sd	s2,80(sp)
    80003fb0:	e4ce                	sd	s3,72(sp)
    80003fb2:	e0d2                	sd	s4,64(sp)
    80003fb4:	fc56                	sd	s5,56(sp)
    80003fb6:	f85a                	sd	s6,48(sp)
    80003fb8:	f45e                	sd	s7,40(sp)
    80003fba:	f062                	sd	s8,32(sp)
    80003fbc:	ec66                	sd	s9,24(sp)
    80003fbe:	e86a                	sd	s10,16(sp)
    80003fc0:	e46e                	sd	s11,8(sp)
    80003fc2:	1880                	addi	s0,sp,112
    80003fc4:	8baa                	mv	s7,a0
    80003fc6:	8c2e                	mv	s8,a1
    80003fc8:	8a32                	mv	s4,a2
    80003fca:	84b6                	mv	s1,a3
    80003fcc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fce:	9f35                	addw	a4,a4,a3
    return 0;
    80003fd0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fd2:	0ad76063          	bltu	a4,a3,80004072 <readi+0xd2>
  if(off + n > ip->size)
    80003fd6:	00e7f463          	bleu	a4,a5,80003fde <readi+0x3e>
    n = ip->size - off;
    80003fda:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fde:	0a0b0963          	beqz	s6,80004090 <readi+0xf0>
    80003fe2:	4901                	li	s2,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fe8:	5cfd                	li	s9,-1
    80003fea:	a82d                	j	80004024 <readi+0x84>
    80003fec:	02099d93          	slli	s11,s3,0x20
    80003ff0:	020ddd93          	srli	s11,s11,0x20
    80003ff4:	060a8613          	addi	a2,s5,96
    80003ff8:	86ee                	mv	a3,s11
    80003ffa:	963a                	add	a2,a2,a4
    80003ffc:	85d2                	mv	a1,s4
    80003ffe:	8562                	mv	a0,s8
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	9b2080e7          	jalr	-1614(ra) # 800029b2 <either_copyout>
    80004008:	05950d63          	beq	a0,s9,80004062 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000400c:	8556                	mv	a0,s5
    8000400e:	fffff097          	auipc	ra,0xfffff
    80004012:	5b0080e7          	jalr	1456(ra) # 800035be <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004016:	0129893b          	addw	s2,s3,s2
    8000401a:	009984bb          	addw	s1,s3,s1
    8000401e:	9a6e                	add	s4,s4,s11
    80004020:	05697763          	bleu	s6,s2,8000406e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004024:	000ba983          	lw	s3,0(s7)
    80004028:	00a4d59b          	srliw	a1,s1,0xa
    8000402c:	855e                	mv	a0,s7
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	8ac080e7          	jalr	-1876(ra) # 800038da <bmap>
    80004036:	0005059b          	sext.w	a1,a0
    8000403a:	854e                	mv	a0,s3
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	380080e7          	jalr	896(ra) # 800033bc <bread>
    80004044:	8aaa                	mv	s5,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004046:	3ff4f713          	andi	a4,s1,1023
    8000404a:	40ed07bb          	subw	a5,s10,a4
    8000404e:	412b06bb          	subw	a3,s6,s2
    80004052:	89be                	mv	s3,a5
    80004054:	2781                	sext.w	a5,a5
    80004056:	0006861b          	sext.w	a2,a3
    8000405a:	f8f679e3          	bleu	a5,a2,80003fec <readi+0x4c>
    8000405e:	89b6                	mv	s3,a3
    80004060:	b771                	j	80003fec <readi+0x4c>
      brelse(bp);
    80004062:	8556                	mv	a0,s5
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	55a080e7          	jalr	1370(ra) # 800035be <brelse>
      tot = -1;
    8000406c:	597d                	li	s2,-1
  }
  return tot;
    8000406e:	0009051b          	sext.w	a0,s2
}
    80004072:	70a6                	ld	ra,104(sp)
    80004074:	7406                	ld	s0,96(sp)
    80004076:	64e6                	ld	s1,88(sp)
    80004078:	6946                	ld	s2,80(sp)
    8000407a:	69a6                	ld	s3,72(sp)
    8000407c:	6a06                	ld	s4,64(sp)
    8000407e:	7ae2                	ld	s5,56(sp)
    80004080:	7b42                	ld	s6,48(sp)
    80004082:	7ba2                	ld	s7,40(sp)
    80004084:	7c02                	ld	s8,32(sp)
    80004086:	6ce2                	ld	s9,24(sp)
    80004088:	6d42                	ld	s10,16(sp)
    8000408a:	6da2                	ld	s11,8(sp)
    8000408c:	6165                	addi	sp,sp,112
    8000408e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004090:	895a                	mv	s2,s6
    80004092:	bff1                	j	8000406e <readi+0xce>
    return 0;
    80004094:	4501                	li	a0,0
}
    80004096:	8082                	ret

0000000080004098 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004098:	497c                	lw	a5,84(a0)
    8000409a:	10d7e763          	bltu	a5,a3,800041a8 <writei+0x110>
{
    8000409e:	7159                	addi	sp,sp,-112
    800040a0:	f486                	sd	ra,104(sp)
    800040a2:	f0a2                	sd	s0,96(sp)
    800040a4:	eca6                	sd	s1,88(sp)
    800040a6:	e8ca                	sd	s2,80(sp)
    800040a8:	e4ce                	sd	s3,72(sp)
    800040aa:	e0d2                	sd	s4,64(sp)
    800040ac:	fc56                	sd	s5,56(sp)
    800040ae:	f85a                	sd	s6,48(sp)
    800040b0:	f45e                	sd	s7,40(sp)
    800040b2:	f062                	sd	s8,32(sp)
    800040b4:	ec66                	sd	s9,24(sp)
    800040b6:	e86a                	sd	s10,16(sp)
    800040b8:	e46e                	sd	s11,8(sp)
    800040ba:	1880                	addi	s0,sp,112
    800040bc:	8baa                	mv	s7,a0
    800040be:	8c2e                	mv	s8,a1
    800040c0:	8ab2                	mv	s5,a2
    800040c2:	84b6                	mv	s1,a3
    800040c4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040c6:	00e687bb          	addw	a5,a3,a4
    800040ca:	0ed7e163          	bltu	a5,a3,800041ac <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040ce:	00043737          	lui	a4,0x43
    800040d2:	0cf76f63          	bltu	a4,a5,800041b0 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d6:	0a0b0863          	beqz	s6,80004186 <writei+0xee>
    800040da:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040dc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040e0:	5cfd                	li	s9,-1
    800040e2:	a091                	j	80004126 <writei+0x8e>
    800040e4:	02091d93          	slli	s11,s2,0x20
    800040e8:	020ddd93          	srli	s11,s11,0x20
    800040ec:	06098513          	addi	a0,s3,96
    800040f0:	86ee                	mv	a3,s11
    800040f2:	8656                	mv	a2,s5
    800040f4:	85e2                	mv	a1,s8
    800040f6:	953a                	add	a0,a0,a4
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	910080e7          	jalr	-1776(ra) # 80002a08 <either_copyin>
    80004100:	07950263          	beq	a0,s9,80004164 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80004104:	854e                	mv	a0,s3
    80004106:	00000097          	auipc	ra,0x0
    8000410a:	79e080e7          	jalr	1950(ra) # 800048a4 <log_write>
    brelse(bp);
    8000410e:	854e                	mv	a0,s3
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	4ae080e7          	jalr	1198(ra) # 800035be <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004118:	01490a3b          	addw	s4,s2,s4
    8000411c:	009904bb          	addw	s1,s2,s1
    80004120:	9aee                	add	s5,s5,s11
    80004122:	056a7763          	bleu	s6,s4,80004170 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004126:	000ba903          	lw	s2,0(s7)
    8000412a:	00a4d59b          	srliw	a1,s1,0xa
    8000412e:	855e                	mv	a0,s7
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	7aa080e7          	jalr	1962(ra) # 800038da <bmap>
    80004138:	0005059b          	sext.w	a1,a0
    8000413c:	854a                	mv	a0,s2
    8000413e:	fffff097          	auipc	ra,0xfffff
    80004142:	27e080e7          	jalr	638(ra) # 800033bc <bread>
    80004146:	89aa                	mv	s3,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004148:	3ff4f713          	andi	a4,s1,1023
    8000414c:	40ed07bb          	subw	a5,s10,a4
    80004150:	414b06bb          	subw	a3,s6,s4
    80004154:	893e                	mv	s2,a5
    80004156:	2781                	sext.w	a5,a5
    80004158:	0006861b          	sext.w	a2,a3
    8000415c:	f8f674e3          	bleu	a5,a2,800040e4 <writei+0x4c>
    80004160:	8936                	mv	s2,a3
    80004162:	b749                	j	800040e4 <writei+0x4c>
      brelse(bp);
    80004164:	854e                	mv	a0,s3
    80004166:	fffff097          	auipc	ra,0xfffff
    8000416a:	458080e7          	jalr	1112(ra) # 800035be <brelse>
      n = -1;
    8000416e:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80004170:	054ba783          	lw	a5,84(s7)
    80004174:	0097f463          	bleu	s1,a5,8000417c <writei+0xe4>
      ip->size = off;
    80004178:	049baa23          	sw	s1,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    8000417c:	855e                	mv	a0,s7
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	aa0080e7          	jalr	-1376(ra) # 80003c1e <iupdate>
  }

  return n;
    80004186:	000b051b          	sext.w	a0,s6
}
    8000418a:	70a6                	ld	ra,104(sp)
    8000418c:	7406                	ld	s0,96(sp)
    8000418e:	64e6                	ld	s1,88(sp)
    80004190:	6946                	ld	s2,80(sp)
    80004192:	69a6                	ld	s3,72(sp)
    80004194:	6a06                	ld	s4,64(sp)
    80004196:	7ae2                	ld	s5,56(sp)
    80004198:	7b42                	ld	s6,48(sp)
    8000419a:	7ba2                	ld	s7,40(sp)
    8000419c:	7c02                	ld	s8,32(sp)
    8000419e:	6ce2                	ld	s9,24(sp)
    800041a0:	6d42                	ld	s10,16(sp)
    800041a2:	6da2                	ld	s11,8(sp)
    800041a4:	6165                	addi	sp,sp,112
    800041a6:	8082                	ret
    return -1;
    800041a8:	557d                	li	a0,-1
}
    800041aa:	8082                	ret
    return -1;
    800041ac:	557d                	li	a0,-1
    800041ae:	bff1                	j	8000418a <writei+0xf2>
    return -1;
    800041b0:	557d                	li	a0,-1
    800041b2:	bfe1                	j	8000418a <writei+0xf2>

00000000800041b4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041b4:	1141                	addi	sp,sp,-16
    800041b6:	e406                	sd	ra,8(sp)
    800041b8:	e022                	sd	s0,0(sp)
    800041ba:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041bc:	4639                	li	a2,14
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	1bc080e7          	jalr	444(ra) # 8000137a <strncmp>
}
    800041c6:	60a2                	ld	ra,8(sp)
    800041c8:	6402                	ld	s0,0(sp)
    800041ca:	0141                	addi	sp,sp,16
    800041cc:	8082                	ret

00000000800041ce <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041ce:	7139                	addi	sp,sp,-64
    800041d0:	fc06                	sd	ra,56(sp)
    800041d2:	f822                	sd	s0,48(sp)
    800041d4:	f426                	sd	s1,40(sp)
    800041d6:	f04a                	sd	s2,32(sp)
    800041d8:	ec4e                	sd	s3,24(sp)
    800041da:	e852                	sd	s4,16(sp)
    800041dc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041de:	04c51703          	lh	a4,76(a0)
    800041e2:	4785                	li	a5,1
    800041e4:	00f71a63          	bne	a4,a5,800041f8 <dirlookup+0x2a>
    800041e8:	892a                	mv	s2,a0
    800041ea:	89ae                	mv	s3,a1
    800041ec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ee:	497c                	lw	a5,84(a0)
    800041f0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041f2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f4:	e79d                	bnez	a5,80004222 <dirlookup+0x54>
    800041f6:	a8a5                	j	8000426e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041f8:	00004517          	auipc	a0,0x4
    800041fc:	47050513          	addi	a0,a0,1136 # 80008668 <syscalls+0x1d0>
    80004200:	ffffc097          	auipc	ra,0xffffc
    80004204:	378080e7          	jalr	888(ra) # 80000578 <panic>
      panic("dirlookup read");
    80004208:	00004517          	auipc	a0,0x4
    8000420c:	47850513          	addi	a0,a0,1144 # 80008680 <syscalls+0x1e8>
    80004210:	ffffc097          	auipc	ra,0xffffc
    80004214:	368080e7          	jalr	872(ra) # 80000578 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004218:	24c1                	addiw	s1,s1,16
    8000421a:	05492783          	lw	a5,84(s2)
    8000421e:	04f4f763          	bleu	a5,s1,8000426c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004222:	4741                	li	a4,16
    80004224:	86a6                	mv	a3,s1
    80004226:	fc040613          	addi	a2,s0,-64
    8000422a:	4581                	li	a1,0
    8000422c:	854a                	mv	a0,s2
    8000422e:	00000097          	auipc	ra,0x0
    80004232:	d72080e7          	jalr	-654(ra) # 80003fa0 <readi>
    80004236:	47c1                	li	a5,16
    80004238:	fcf518e3          	bne	a0,a5,80004208 <dirlookup+0x3a>
    if(de.inum == 0)
    8000423c:	fc045783          	lhu	a5,-64(s0)
    80004240:	dfe1                	beqz	a5,80004218 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004242:	fc240593          	addi	a1,s0,-62
    80004246:	854e                	mv	a0,s3
    80004248:	00000097          	auipc	ra,0x0
    8000424c:	f6c080e7          	jalr	-148(ra) # 800041b4 <namecmp>
    80004250:	f561                	bnez	a0,80004218 <dirlookup+0x4a>
      if(poff)
    80004252:	000a0463          	beqz	s4,8000425a <dirlookup+0x8c>
        *poff = off;
    80004256:	009a2023          	sw	s1,0(s4) # 2000 <_entry-0x7fffe000>
      return iget(dp->dev, inum);
    8000425a:	fc045583          	lhu	a1,-64(s0)
    8000425e:	00092503          	lw	a0,0(s2)
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	752080e7          	jalr	1874(ra) # 800039b4 <iget>
    8000426a:	a011                	j	8000426e <dirlookup+0xa0>
  return 0;
    8000426c:	4501                	li	a0,0
}
    8000426e:	70e2                	ld	ra,56(sp)
    80004270:	7442                	ld	s0,48(sp)
    80004272:	74a2                	ld	s1,40(sp)
    80004274:	7902                	ld	s2,32(sp)
    80004276:	69e2                	ld	s3,24(sp)
    80004278:	6a42                	ld	s4,16(sp)
    8000427a:	6121                	addi	sp,sp,64
    8000427c:	8082                	ret

000000008000427e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000427e:	711d                	addi	sp,sp,-96
    80004280:	ec86                	sd	ra,88(sp)
    80004282:	e8a2                	sd	s0,80(sp)
    80004284:	e4a6                	sd	s1,72(sp)
    80004286:	e0ca                	sd	s2,64(sp)
    80004288:	fc4e                	sd	s3,56(sp)
    8000428a:	f852                	sd	s4,48(sp)
    8000428c:	f456                	sd	s5,40(sp)
    8000428e:	f05a                	sd	s6,32(sp)
    80004290:	ec5e                	sd	s7,24(sp)
    80004292:	e862                	sd	s8,16(sp)
    80004294:	e466                	sd	s9,8(sp)
    80004296:	1080                	addi	s0,sp,96
    80004298:	84aa                	mv	s1,a0
    8000429a:	8bae                	mv	s7,a1
    8000429c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000429e:	00054703          	lbu	a4,0(a0)
    800042a2:	02f00793          	li	a5,47
    800042a6:	02f70363          	beq	a4,a5,800042cc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042aa:	ffffe097          	auipc	ra,0xffffe
    800042ae:	c8c080e7          	jalr	-884(ra) # 80001f36 <myproc>
    800042b2:	15853503          	ld	a0,344(a0)
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	9f6080e7          	jalr	-1546(ra) # 80003cac <idup>
    800042be:	89aa                	mv	s3,a0
  while(*path == '/')
    800042c0:	02f00913          	li	s2,47
  len = path - s;
    800042c4:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800042c6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042c8:	4c05                	li	s8,1
    800042ca:	a865                	j	80004382 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042cc:	4585                	li	a1,1
    800042ce:	4505                	li	a0,1
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	6e4080e7          	jalr	1764(ra) # 800039b4 <iget>
    800042d8:	89aa                	mv	s3,a0
    800042da:	b7dd                	j	800042c0 <namex+0x42>
      iunlockput(ip);
    800042dc:	854e                	mv	a0,s3
    800042de:	00000097          	auipc	ra,0x0
    800042e2:	c70080e7          	jalr	-912(ra) # 80003f4e <iunlockput>
      return 0;
    800042e6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042e8:	854e                	mv	a0,s3
    800042ea:	60e6                	ld	ra,88(sp)
    800042ec:	6446                	ld	s0,80(sp)
    800042ee:	64a6                	ld	s1,72(sp)
    800042f0:	6906                	ld	s2,64(sp)
    800042f2:	79e2                	ld	s3,56(sp)
    800042f4:	7a42                	ld	s4,48(sp)
    800042f6:	7aa2                	ld	s5,40(sp)
    800042f8:	7b02                	ld	s6,32(sp)
    800042fa:	6be2                	ld	s7,24(sp)
    800042fc:	6c42                	ld	s8,16(sp)
    800042fe:	6ca2                	ld	s9,8(sp)
    80004300:	6125                	addi	sp,sp,96
    80004302:	8082                	ret
      iunlock(ip);
    80004304:	854e                	mv	a0,s3
    80004306:	00000097          	auipc	ra,0x0
    8000430a:	aa8080e7          	jalr	-1368(ra) # 80003dae <iunlock>
      return ip;
    8000430e:	bfe9                	j	800042e8 <namex+0x6a>
      iunlockput(ip);
    80004310:	854e                	mv	a0,s3
    80004312:	00000097          	auipc	ra,0x0
    80004316:	c3c080e7          	jalr	-964(ra) # 80003f4e <iunlockput>
      return 0;
    8000431a:	89d2                	mv	s3,s4
    8000431c:	b7f1                	j	800042e8 <namex+0x6a>
  len = path - s;
    8000431e:	40b48633          	sub	a2,s1,a1
    80004322:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004326:	094cd663          	ble	s4,s9,800043b2 <namex+0x134>
    memmove(name, s, DIRSIZ);
    8000432a:	4639                	li	a2,14
    8000432c:	8556                	mv	a0,s5
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	fd0080e7          	jalr	-48(ra) # 800012fe <memmove>
  while(*path == '/')
    80004336:	0004c783          	lbu	a5,0(s1)
    8000433a:	01279763          	bne	a5,s2,80004348 <namex+0xca>
    path++;
    8000433e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004340:	0004c783          	lbu	a5,0(s1)
    80004344:	ff278de3          	beq	a5,s2,8000433e <namex+0xc0>
    ilock(ip);
    80004348:	854e                	mv	a0,s3
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	9a0080e7          	jalr	-1632(ra) # 80003cea <ilock>
    if(ip->type != T_DIR){
    80004352:	04c99783          	lh	a5,76(s3)
    80004356:	f98793e3          	bne	a5,s8,800042dc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000435a:	000b8563          	beqz	s7,80004364 <namex+0xe6>
    8000435e:	0004c783          	lbu	a5,0(s1)
    80004362:	d3cd                	beqz	a5,80004304 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004364:	865a                	mv	a2,s6
    80004366:	85d6                	mv	a1,s5
    80004368:	854e                	mv	a0,s3
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	e64080e7          	jalr	-412(ra) # 800041ce <dirlookup>
    80004372:	8a2a                	mv	s4,a0
    80004374:	dd51                	beqz	a0,80004310 <namex+0x92>
    iunlockput(ip);
    80004376:	854e                	mv	a0,s3
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	bd6080e7          	jalr	-1066(ra) # 80003f4e <iunlockput>
    ip = next;
    80004380:	89d2                	mv	s3,s4
  while(*path == '/')
    80004382:	0004c783          	lbu	a5,0(s1)
    80004386:	05279d63          	bne	a5,s2,800043e0 <namex+0x162>
    path++;
    8000438a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000438c:	0004c783          	lbu	a5,0(s1)
    80004390:	ff278de3          	beq	a5,s2,8000438a <namex+0x10c>
  if(*path == 0)
    80004394:	cf8d                	beqz	a5,800043ce <namex+0x150>
  while(*path != '/' && *path != 0)
    80004396:	01278b63          	beq	a5,s2,800043ac <namex+0x12e>
    8000439a:	c795                	beqz	a5,800043c6 <namex+0x148>
    path++;
    8000439c:	85a6                	mv	a1,s1
    path++;
    8000439e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043a0:	0004c783          	lbu	a5,0(s1)
    800043a4:	f7278de3          	beq	a5,s2,8000431e <namex+0xa0>
    800043a8:	fbfd                	bnez	a5,8000439e <namex+0x120>
    800043aa:	bf95                	j	8000431e <namex+0xa0>
    800043ac:	85a6                	mv	a1,s1
  len = path - s;
    800043ae:	8a5a                	mv	s4,s6
    800043b0:	865a                	mv	a2,s6
    memmove(name, s, len);
    800043b2:	2601                	sext.w	a2,a2
    800043b4:	8556                	mv	a0,s5
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	f48080e7          	jalr	-184(ra) # 800012fe <memmove>
    name[len] = 0;
    800043be:	9a56                	add	s4,s4,s5
    800043c0:	000a0023          	sb	zero,0(s4)
    800043c4:	bf8d                	j	80004336 <namex+0xb8>
  while(*path != '/' && *path != 0)
    800043c6:	85a6                	mv	a1,s1
  len = path - s;
    800043c8:	8a5a                	mv	s4,s6
    800043ca:	865a                	mv	a2,s6
    800043cc:	b7dd                	j	800043b2 <namex+0x134>
  if(nameiparent){
    800043ce:	f00b8de3          	beqz	s7,800042e8 <namex+0x6a>
    iput(ip);
    800043d2:	854e                	mv	a0,s3
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	ad2080e7          	jalr	-1326(ra) # 80003ea6 <iput>
    return 0;
    800043dc:	4981                	li	s3,0
    800043de:	b729                	j	800042e8 <namex+0x6a>
  if(*path == 0)
    800043e0:	d7fd                	beqz	a5,800043ce <namex+0x150>
    800043e2:	85a6                	mv	a1,s1
    800043e4:	bf6d                	j	8000439e <namex+0x120>

00000000800043e6 <dirlink>:
{
    800043e6:	7139                	addi	sp,sp,-64
    800043e8:	fc06                	sd	ra,56(sp)
    800043ea:	f822                	sd	s0,48(sp)
    800043ec:	f426                	sd	s1,40(sp)
    800043ee:	f04a                	sd	s2,32(sp)
    800043f0:	ec4e                	sd	s3,24(sp)
    800043f2:	e852                	sd	s4,16(sp)
    800043f4:	0080                	addi	s0,sp,64
    800043f6:	892a                	mv	s2,a0
    800043f8:	8a2e                	mv	s4,a1
    800043fa:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043fc:	4601                	li	a2,0
    800043fe:	00000097          	auipc	ra,0x0
    80004402:	dd0080e7          	jalr	-560(ra) # 800041ce <dirlookup>
    80004406:	e93d                	bnez	a0,8000447c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004408:	05492483          	lw	s1,84(s2)
    8000440c:	c49d                	beqz	s1,8000443a <dirlink+0x54>
    8000440e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004410:	4741                	li	a4,16
    80004412:	86a6                	mv	a3,s1
    80004414:	fc040613          	addi	a2,s0,-64
    80004418:	4581                	li	a1,0
    8000441a:	854a                	mv	a0,s2
    8000441c:	00000097          	auipc	ra,0x0
    80004420:	b84080e7          	jalr	-1148(ra) # 80003fa0 <readi>
    80004424:	47c1                	li	a5,16
    80004426:	06f51163          	bne	a0,a5,80004488 <dirlink+0xa2>
    if(de.inum == 0)
    8000442a:	fc045783          	lhu	a5,-64(s0)
    8000442e:	c791                	beqz	a5,8000443a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004430:	24c1                	addiw	s1,s1,16
    80004432:	05492783          	lw	a5,84(s2)
    80004436:	fcf4ede3          	bltu	s1,a5,80004410 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000443a:	4639                	li	a2,14
    8000443c:	85d2                	mv	a1,s4
    8000443e:	fc240513          	addi	a0,s0,-62
    80004442:	ffffd097          	auipc	ra,0xffffd
    80004446:	f88080e7          	jalr	-120(ra) # 800013ca <strncpy>
  de.inum = inum;
    8000444a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000444e:	4741                	li	a4,16
    80004450:	86a6                	mv	a3,s1
    80004452:	fc040613          	addi	a2,s0,-64
    80004456:	4581                	li	a1,0
    80004458:	854a                	mv	a0,s2
    8000445a:	00000097          	auipc	ra,0x0
    8000445e:	c3e080e7          	jalr	-962(ra) # 80004098 <writei>
    80004462:	4741                	li	a4,16
  return 0;
    80004464:	4781                	li	a5,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004466:	02e51963          	bne	a0,a4,80004498 <dirlink+0xb2>
}
    8000446a:	853e                	mv	a0,a5
    8000446c:	70e2                	ld	ra,56(sp)
    8000446e:	7442                	ld	s0,48(sp)
    80004470:	74a2                	ld	s1,40(sp)
    80004472:	7902                	ld	s2,32(sp)
    80004474:	69e2                	ld	s3,24(sp)
    80004476:	6a42                	ld	s4,16(sp)
    80004478:	6121                	addi	sp,sp,64
    8000447a:	8082                	ret
    iput(ip);
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	a2a080e7          	jalr	-1494(ra) # 80003ea6 <iput>
    return -1;
    80004484:	57fd                	li	a5,-1
    80004486:	b7d5                	j	8000446a <dirlink+0x84>
      panic("dirlink read");
    80004488:	00004517          	auipc	a0,0x4
    8000448c:	20850513          	addi	a0,a0,520 # 80008690 <syscalls+0x1f8>
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	0e8080e7          	jalr	232(ra) # 80000578 <panic>
    panic("dirlink");
    80004498:	00004517          	auipc	a0,0x4
    8000449c:	31850513          	addi	a0,a0,792 # 800087b0 <syscalls+0x318>
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	0d8080e7          	jalr	216(ra) # 80000578 <panic>

00000000800044a8 <namei>:

struct inode*
namei(char *path)
{
    800044a8:	1101                	addi	sp,sp,-32
    800044aa:	ec06                	sd	ra,24(sp)
    800044ac:	e822                	sd	s0,16(sp)
    800044ae:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044b0:	fe040613          	addi	a2,s0,-32
    800044b4:	4581                	li	a1,0
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	dc8080e7          	jalr	-568(ra) # 8000427e <namex>
}
    800044be:	60e2                	ld	ra,24(sp)
    800044c0:	6442                	ld	s0,16(sp)
    800044c2:	6105                	addi	sp,sp,32
    800044c4:	8082                	ret

00000000800044c6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044c6:	1141                	addi	sp,sp,-16
    800044c8:	e406                	sd	ra,8(sp)
    800044ca:	e022                	sd	s0,0(sp)
    800044cc:	0800                	addi	s0,sp,16
  return namex(path, 1, name);
    800044ce:	862e                	mv	a2,a1
    800044d0:	4585                	li	a1,1
    800044d2:	00000097          	auipc	ra,0x0
    800044d6:	dac080e7          	jalr	-596(ra) # 8000427e <namex>
}
    800044da:	60a2                	ld	ra,8(sp)
    800044dc:	6402                	ld	s0,0(sp)
    800044de:	0141                	addi	sp,sp,16
    800044e0:	8082                	ret

00000000800044e2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044e2:	1101                	addi	sp,sp,-32
    800044e4:	ec06                	sd	ra,24(sp)
    800044e6:	e822                	sd	s0,16(sp)
    800044e8:	e426                	sd	s1,8(sp)
    800044ea:	e04a                	sd	s2,0(sp)
    800044ec:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044ee:	00052917          	auipc	s2,0x52
    800044f2:	e8a90913          	addi	s2,s2,-374 # 80056378 <log>
    800044f6:	02092583          	lw	a1,32(s2)
    800044fa:	03092503          	lw	a0,48(s2)
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	ebe080e7          	jalr	-322(ra) # 800033bc <bread>
    80004506:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004508:	03492683          	lw	a3,52(s2)
    8000450c:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000450e:	02d05763          	blez	a3,8000453c <write_head+0x5a>
    80004512:	00052797          	auipc	a5,0x52
    80004516:	e9e78793          	addi	a5,a5,-354 # 800563b0 <log+0x38>
    8000451a:	06450713          	addi	a4,a0,100
    8000451e:	36fd                	addiw	a3,a3,-1
    80004520:	1682                	slli	a3,a3,0x20
    80004522:	9281                	srli	a3,a3,0x20
    80004524:	068a                	slli	a3,a3,0x2
    80004526:	00052617          	auipc	a2,0x52
    8000452a:	e8e60613          	addi	a2,a2,-370 # 800563b4 <log+0x3c>
    8000452e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004530:	4390                	lw	a2,0(a5)
    80004532:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004534:	0791                	addi	a5,a5,4
    80004536:	0711                	addi	a4,a4,4
    80004538:	fed79ce3          	bne	a5,a3,80004530 <write_head+0x4e>
  }
  bwrite(buf);
    8000453c:	8526                	mv	a0,s1
    8000453e:	fffff097          	auipc	ra,0xfffff
    80004542:	042080e7          	jalr	66(ra) # 80003580 <bwrite>
  brelse(buf);
    80004546:	8526                	mv	a0,s1
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	076080e7          	jalr	118(ra) # 800035be <brelse>
}
    80004550:	60e2                	ld	ra,24(sp)
    80004552:	6442                	ld	s0,16(sp)
    80004554:	64a2                	ld	s1,8(sp)
    80004556:	6902                	ld	s2,0(sp)
    80004558:	6105                	addi	sp,sp,32
    8000455a:	8082                	ret

000000008000455c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000455c:	00052797          	auipc	a5,0x52
    80004560:	e1c78793          	addi	a5,a5,-484 # 80056378 <log>
    80004564:	5bdc                	lw	a5,52(a5)
    80004566:	0af05d63          	blez	a5,80004620 <install_trans+0xc4>
{
    8000456a:	7139                	addi	sp,sp,-64
    8000456c:	fc06                	sd	ra,56(sp)
    8000456e:	f822                	sd	s0,48(sp)
    80004570:	f426                	sd	s1,40(sp)
    80004572:	f04a                	sd	s2,32(sp)
    80004574:	ec4e                	sd	s3,24(sp)
    80004576:	e852                	sd	s4,16(sp)
    80004578:	e456                	sd	s5,8(sp)
    8000457a:	e05a                	sd	s6,0(sp)
    8000457c:	0080                	addi	s0,sp,64
    8000457e:	8b2a                	mv	s6,a0
    80004580:	00052a17          	auipc	s4,0x52
    80004584:	e30a0a13          	addi	s4,s4,-464 # 800563b0 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004588:	4981                	li	s3,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000458a:	00052917          	auipc	s2,0x52
    8000458e:	dee90913          	addi	s2,s2,-530 # 80056378 <log>
    80004592:	a035                	j	800045be <install_trans+0x62>
      bunpin(dbuf);
    80004594:	8526                	mv	a0,s1
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	110080e7          	jalr	272(ra) # 800036a6 <bunpin>
    brelse(lbuf);
    8000459e:	8556                	mv	a0,s5
    800045a0:	fffff097          	auipc	ra,0xfffff
    800045a4:	01e080e7          	jalr	30(ra) # 800035be <brelse>
    brelse(dbuf);
    800045a8:	8526                	mv	a0,s1
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	014080e7          	jalr	20(ra) # 800035be <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045b2:	2985                	addiw	s3,s3,1
    800045b4:	0a11                	addi	s4,s4,4
    800045b6:	03492783          	lw	a5,52(s2)
    800045ba:	04f9d963          	ble	a5,s3,8000460c <install_trans+0xb0>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045be:	02092583          	lw	a1,32(s2)
    800045c2:	013585bb          	addw	a1,a1,s3
    800045c6:	2585                	addiw	a1,a1,1
    800045c8:	03092503          	lw	a0,48(s2)
    800045cc:	fffff097          	auipc	ra,0xfffff
    800045d0:	df0080e7          	jalr	-528(ra) # 800033bc <bread>
    800045d4:	8aaa                	mv	s5,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045d6:	000a2583          	lw	a1,0(s4)
    800045da:	03092503          	lw	a0,48(s2)
    800045de:	fffff097          	auipc	ra,0xfffff
    800045e2:	dde080e7          	jalr	-546(ra) # 800033bc <bread>
    800045e6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045e8:	40000613          	li	a2,1024
    800045ec:	060a8593          	addi	a1,s5,96
    800045f0:	06050513          	addi	a0,a0,96
    800045f4:	ffffd097          	auipc	ra,0xffffd
    800045f8:	d0a080e7          	jalr	-758(ra) # 800012fe <memmove>
    bwrite(dbuf);  // write dst to disk
    800045fc:	8526                	mv	a0,s1
    800045fe:	fffff097          	auipc	ra,0xfffff
    80004602:	f82080e7          	jalr	-126(ra) # 80003580 <bwrite>
    if(recovering == 0)
    80004606:	f80b1ce3          	bnez	s6,8000459e <install_trans+0x42>
    8000460a:	b769                	j	80004594 <install_trans+0x38>
}
    8000460c:	70e2                	ld	ra,56(sp)
    8000460e:	7442                	ld	s0,48(sp)
    80004610:	74a2                	ld	s1,40(sp)
    80004612:	7902                	ld	s2,32(sp)
    80004614:	69e2                	ld	s3,24(sp)
    80004616:	6a42                	ld	s4,16(sp)
    80004618:	6aa2                	ld	s5,8(sp)
    8000461a:	6b02                	ld	s6,0(sp)
    8000461c:	6121                	addi	sp,sp,64
    8000461e:	8082                	ret
    80004620:	8082                	ret

0000000080004622 <initlog>:
{
    80004622:	7179                	addi	sp,sp,-48
    80004624:	f406                	sd	ra,40(sp)
    80004626:	f022                	sd	s0,32(sp)
    80004628:	ec26                	sd	s1,24(sp)
    8000462a:	e84a                	sd	s2,16(sp)
    8000462c:	e44e                	sd	s3,8(sp)
    8000462e:	1800                	addi	s0,sp,48
    80004630:	892a                	mv	s2,a0
    80004632:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004634:	00052497          	auipc	s1,0x52
    80004638:	d4448493          	addi	s1,s1,-700 # 80056378 <log>
    8000463c:	00004597          	auipc	a1,0x4
    80004640:	06458593          	addi	a1,a1,100 # 800086a0 <syscalls+0x208>
    80004644:	8526                	mv	a0,s1
    80004646:	ffffd097          	auipc	ra,0xffffd
    8000464a:	9cc080e7          	jalr	-1588(ra) # 80001012 <initlock>
  log.start = sb->logstart;
    8000464e:	0149a583          	lw	a1,20(s3)
    80004652:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    80004654:	0109a783          	lw	a5,16(s3)
    80004658:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    8000465a:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000465e:	854a                	mv	a0,s2
    80004660:	fffff097          	auipc	ra,0xfffff
    80004664:	d5c080e7          	jalr	-676(ra) # 800033bc <bread>
  log.lh.n = lh->n;
    80004668:	513c                	lw	a5,96(a0)
    8000466a:	d8dc                	sw	a5,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000466c:	02f05563          	blez	a5,80004696 <initlog+0x74>
    80004670:	06450713          	addi	a4,a0,100
    80004674:	00052697          	auipc	a3,0x52
    80004678:	d3c68693          	addi	a3,a3,-708 # 800563b0 <log+0x38>
    8000467c:	37fd                	addiw	a5,a5,-1
    8000467e:	1782                	slli	a5,a5,0x20
    80004680:	9381                	srli	a5,a5,0x20
    80004682:	078a                	slli	a5,a5,0x2
    80004684:	06850613          	addi	a2,a0,104
    80004688:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000468a:	4310                	lw	a2,0(a4)
    8000468c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000468e:	0711                	addi	a4,a4,4
    80004690:	0691                	addi	a3,a3,4
    80004692:	fef71ce3          	bne	a4,a5,8000468a <initlog+0x68>
  brelse(buf);
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	f28080e7          	jalr	-216(ra) # 800035be <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000469e:	4505                	li	a0,1
    800046a0:	00000097          	auipc	ra,0x0
    800046a4:	ebc080e7          	jalr	-324(ra) # 8000455c <install_trans>
  log.lh.n = 0;
    800046a8:	00052797          	auipc	a5,0x52
    800046ac:	d007a223          	sw	zero,-764(a5) # 800563ac <log+0x34>
  write_head(); // clear the log
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	e32080e7          	jalr	-462(ra) # 800044e2 <write_head>
}
    800046b8:	70a2                	ld	ra,40(sp)
    800046ba:	7402                	ld	s0,32(sp)
    800046bc:	64e2                	ld	s1,24(sp)
    800046be:	6942                	ld	s2,16(sp)
    800046c0:	69a2                	ld	s3,8(sp)
    800046c2:	6145                	addi	sp,sp,48
    800046c4:	8082                	ret

00000000800046c6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046c6:	1101                	addi	sp,sp,-32
    800046c8:	ec06                	sd	ra,24(sp)
    800046ca:	e822                	sd	s0,16(sp)
    800046cc:	e426                	sd	s1,8(sp)
    800046ce:	e04a                	sd	s2,0(sp)
    800046d0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046d2:	00052517          	auipc	a0,0x52
    800046d6:	ca650513          	addi	a0,a0,-858 # 80056378 <log>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	7ac080e7          	jalr	1964(ra) # 80000e86 <acquire>
  while(1){
    if(log.committing){
    800046e2:	00052497          	auipc	s1,0x52
    800046e6:	c9648493          	addi	s1,s1,-874 # 80056378 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046ea:	4979                	li	s2,30
    800046ec:	a039                	j	800046fa <begin_op+0x34>
      sleep(&log, &log.lock);
    800046ee:	85a6                	mv	a1,s1
    800046f0:	8526                	mv	a0,s1
    800046f2:	ffffe097          	auipc	ra,0xffffe
    800046f6:	05e080e7          	jalr	94(ra) # 80002750 <sleep>
    if(log.committing){
    800046fa:	54dc                	lw	a5,44(s1)
    800046fc:	fbed                	bnez	a5,800046ee <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046fe:	549c                	lw	a5,40(s1)
    80004700:	0017871b          	addiw	a4,a5,1
    80004704:	0007069b          	sext.w	a3,a4
    80004708:	0027179b          	slliw	a5,a4,0x2
    8000470c:	9fb9                	addw	a5,a5,a4
    8000470e:	0017979b          	slliw	a5,a5,0x1
    80004712:	58d8                	lw	a4,52(s1)
    80004714:	9fb9                	addw	a5,a5,a4
    80004716:	00f95963          	ble	a5,s2,80004728 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000471a:	85a6                	mv	a1,s1
    8000471c:	8526                	mv	a0,s1
    8000471e:	ffffe097          	auipc	ra,0xffffe
    80004722:	032080e7          	jalr	50(ra) # 80002750 <sleep>
    80004726:	bfd1                	j	800046fa <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004728:	00052517          	auipc	a0,0x52
    8000472c:	c5050513          	addi	a0,a0,-944 # 80056378 <log>
    80004730:	d514                	sw	a3,40(a0)
      release(&log.lock);
    80004732:	ffffd097          	auipc	ra,0xffffd
    80004736:	824080e7          	jalr	-2012(ra) # 80000f56 <release>
      break;
    }
  }
}
    8000473a:	60e2                	ld	ra,24(sp)
    8000473c:	6442                	ld	s0,16(sp)
    8000473e:	64a2                	ld	s1,8(sp)
    80004740:	6902                	ld	s2,0(sp)
    80004742:	6105                	addi	sp,sp,32
    80004744:	8082                	ret

0000000080004746 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004746:	7139                	addi	sp,sp,-64
    80004748:	fc06                	sd	ra,56(sp)
    8000474a:	f822                	sd	s0,48(sp)
    8000474c:	f426                	sd	s1,40(sp)
    8000474e:	f04a                	sd	s2,32(sp)
    80004750:	ec4e                	sd	s3,24(sp)
    80004752:	e852                	sd	s4,16(sp)
    80004754:	e456                	sd	s5,8(sp)
    80004756:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004758:	00052917          	auipc	s2,0x52
    8000475c:	c2090913          	addi	s2,s2,-992 # 80056378 <log>
    80004760:	854a                	mv	a0,s2
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	724080e7          	jalr	1828(ra) # 80000e86 <acquire>
  log.outstanding -= 1;
    8000476a:	02892783          	lw	a5,40(s2)
    8000476e:	37fd                	addiw	a5,a5,-1
    80004770:	0007849b          	sext.w	s1,a5
    80004774:	02f92423          	sw	a5,40(s2)
  if(log.committing)
    80004778:	02c92783          	lw	a5,44(s2)
    8000477c:	eba1                	bnez	a5,800047cc <end_op+0x86>
    panic("log.committing");
  if(log.outstanding == 0){
    8000477e:	ecb9                	bnez	s1,800047dc <end_op+0x96>
    do_commit = 1;
    log.committing = 1;
    80004780:	00052917          	auipc	s2,0x52
    80004784:	bf890913          	addi	s2,s2,-1032 # 80056378 <log>
    80004788:	4785                	li	a5,1
    8000478a:	02f92623          	sw	a5,44(s2)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000478e:	854a                	mv	a0,s2
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	7c6080e7          	jalr	1990(ra) # 80000f56 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004798:	03492783          	lw	a5,52(s2)
    8000479c:	06f04763          	bgtz	a5,8000480a <end_op+0xc4>
    acquire(&log.lock);
    800047a0:	00052497          	auipc	s1,0x52
    800047a4:	bd848493          	addi	s1,s1,-1064 # 80056378 <log>
    800047a8:	8526                	mv	a0,s1
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	6dc080e7          	jalr	1756(ra) # 80000e86 <acquire>
    log.committing = 0;
    800047b2:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffe097          	auipc	ra,0xffffe
    800047bc:	11e080e7          	jalr	286(ra) # 800028d6 <wakeup>
    release(&log.lock);
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	794080e7          	jalr	1940(ra) # 80000f56 <release>
}
    800047ca:	a03d                	j	800047f8 <end_op+0xb2>
    panic("log.committing");
    800047cc:	00004517          	auipc	a0,0x4
    800047d0:	edc50513          	addi	a0,a0,-292 # 800086a8 <syscalls+0x210>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	da4080e7          	jalr	-604(ra) # 80000578 <panic>
    wakeup(&log);
    800047dc:	00052497          	auipc	s1,0x52
    800047e0:	b9c48493          	addi	s1,s1,-1124 # 80056378 <log>
    800047e4:	8526                	mv	a0,s1
    800047e6:	ffffe097          	auipc	ra,0xffffe
    800047ea:	0f0080e7          	jalr	240(ra) # 800028d6 <wakeup>
  release(&log.lock);
    800047ee:	8526                	mv	a0,s1
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	766080e7          	jalr	1894(ra) # 80000f56 <release>
}
    800047f8:	70e2                	ld	ra,56(sp)
    800047fa:	7442                	ld	s0,48(sp)
    800047fc:	74a2                	ld	s1,40(sp)
    800047fe:	7902                	ld	s2,32(sp)
    80004800:	69e2                	ld	s3,24(sp)
    80004802:	6a42                	ld	s4,16(sp)
    80004804:	6aa2                	ld	s5,8(sp)
    80004806:	6121                	addi	sp,sp,64
    80004808:	8082                	ret
    8000480a:	00052a17          	auipc	s4,0x52
    8000480e:	ba6a0a13          	addi	s4,s4,-1114 # 800563b0 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004812:	00052917          	auipc	s2,0x52
    80004816:	b6690913          	addi	s2,s2,-1178 # 80056378 <log>
    8000481a:	02092583          	lw	a1,32(s2)
    8000481e:	9da5                	addw	a1,a1,s1
    80004820:	2585                	addiw	a1,a1,1
    80004822:	03092503          	lw	a0,48(s2)
    80004826:	fffff097          	auipc	ra,0xfffff
    8000482a:	b96080e7          	jalr	-1130(ra) # 800033bc <bread>
    8000482e:	89aa                	mv	s3,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004830:	000a2583          	lw	a1,0(s4)
    80004834:	03092503          	lw	a0,48(s2)
    80004838:	fffff097          	auipc	ra,0xfffff
    8000483c:	b84080e7          	jalr	-1148(ra) # 800033bc <bread>
    80004840:	8aaa                	mv	s5,a0
    memmove(to->data, from->data, BSIZE);
    80004842:	40000613          	li	a2,1024
    80004846:	06050593          	addi	a1,a0,96
    8000484a:	06098513          	addi	a0,s3,96
    8000484e:	ffffd097          	auipc	ra,0xffffd
    80004852:	ab0080e7          	jalr	-1360(ra) # 800012fe <memmove>
    bwrite(to);  // write the log
    80004856:	854e                	mv	a0,s3
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	d28080e7          	jalr	-728(ra) # 80003580 <bwrite>
    brelse(from);
    80004860:	8556                	mv	a0,s5
    80004862:	fffff097          	auipc	ra,0xfffff
    80004866:	d5c080e7          	jalr	-676(ra) # 800035be <brelse>
    brelse(to);
    8000486a:	854e                	mv	a0,s3
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	d52080e7          	jalr	-686(ra) # 800035be <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004874:	2485                	addiw	s1,s1,1
    80004876:	0a11                	addi	s4,s4,4
    80004878:	03492783          	lw	a5,52(s2)
    8000487c:	f8f4cfe3          	blt	s1,a5,8000481a <end_op+0xd4>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004880:	00000097          	auipc	ra,0x0
    80004884:	c62080e7          	jalr	-926(ra) # 800044e2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004888:	4501                	li	a0,0
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	cd2080e7          	jalr	-814(ra) # 8000455c <install_trans>
    log.lh.n = 0;
    80004892:	00052797          	auipc	a5,0x52
    80004896:	b007ad23          	sw	zero,-1254(a5) # 800563ac <log+0x34>
    write_head();    // Erase the transaction from the log
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	c48080e7          	jalr	-952(ra) # 800044e2 <write_head>
    800048a2:	bdfd                	j	800047a0 <end_op+0x5a>

00000000800048a4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048a4:	1101                	addi	sp,sp,-32
    800048a6:	ec06                	sd	ra,24(sp)
    800048a8:	e822                	sd	s0,16(sp)
    800048aa:	e426                	sd	s1,8(sp)
    800048ac:	e04a                	sd	s2,0(sp)
    800048ae:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048b0:	00052797          	auipc	a5,0x52
    800048b4:	ac878793          	addi	a5,a5,-1336 # 80056378 <log>
    800048b8:	5bd8                	lw	a4,52(a5)
    800048ba:	47f5                	li	a5,29
    800048bc:	08e7c563          	blt	a5,a4,80004946 <log_write+0xa2>
    800048c0:	892a                	mv	s2,a0
    800048c2:	00052797          	auipc	a5,0x52
    800048c6:	ab678793          	addi	a5,a5,-1354 # 80056378 <log>
    800048ca:	53dc                	lw	a5,36(a5)
    800048cc:	37fd                	addiw	a5,a5,-1
    800048ce:	06f75c63          	ble	a5,a4,80004946 <log_write+0xa2>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048d2:	00052797          	auipc	a5,0x52
    800048d6:	aa678793          	addi	a5,a5,-1370 # 80056378 <log>
    800048da:	579c                	lw	a5,40(a5)
    800048dc:	06f05d63          	blez	a5,80004956 <log_write+0xb2>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800048e0:	00052497          	auipc	s1,0x52
    800048e4:	a9848493          	addi	s1,s1,-1384 # 80056378 <log>
    800048e8:	8526                	mv	a0,s1
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	59c080e7          	jalr	1436(ra) # 80000e86 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800048f2:	58d0                	lw	a2,52(s1)
    800048f4:	0ac05063          	blez	a2,80004994 <log_write+0xf0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800048f8:	00c92583          	lw	a1,12(s2)
    800048fc:	5c9c                	lw	a5,56(s1)
    800048fe:	0ab78363          	beq	a5,a1,800049a4 <log_write+0x100>
    80004902:	00052717          	auipc	a4,0x52
    80004906:	ab270713          	addi	a4,a4,-1358 # 800563b4 <log+0x3c>
  for (i = 0; i < log.lh.n; i++) {
    8000490a:	4781                	li	a5,0
    8000490c:	2785                	addiw	a5,a5,1
    8000490e:	04c78c63          	beq	a5,a2,80004966 <log_write+0xc2>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004912:	4314                	lw	a3,0(a4)
    80004914:	0711                	addi	a4,a4,4
    80004916:	feb69be3          	bne	a3,a1,8000490c <log_write+0x68>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000491a:	07b1                	addi	a5,a5,12
    8000491c:	078a                	slli	a5,a5,0x2
    8000491e:	00052717          	auipc	a4,0x52
    80004922:	a5a70713          	addi	a4,a4,-1446 # 80056378 <log>
    80004926:	97ba                	add	a5,a5,a4
    80004928:	c78c                	sw	a1,8(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    log.lh.n++;
  }
  release(&log.lock);
    8000492a:	00052517          	auipc	a0,0x52
    8000492e:	a4e50513          	addi	a0,a0,-1458 # 80056378 <log>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	624080e7          	jalr	1572(ra) # 80000f56 <release>
}
    8000493a:	60e2                	ld	ra,24(sp)
    8000493c:	6442                	ld	s0,16(sp)
    8000493e:	64a2                	ld	s1,8(sp)
    80004940:	6902                	ld	s2,0(sp)
    80004942:	6105                	addi	sp,sp,32
    80004944:	8082                	ret
    panic("too big a transaction");
    80004946:	00004517          	auipc	a0,0x4
    8000494a:	d7250513          	addi	a0,a0,-654 # 800086b8 <syscalls+0x220>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	c2a080e7          	jalr	-982(ra) # 80000578 <panic>
    panic("log_write outside of trans");
    80004956:	00004517          	auipc	a0,0x4
    8000495a:	d7a50513          	addi	a0,a0,-646 # 800086d0 <syscalls+0x238>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	c1a080e7          	jalr	-998(ra) # 80000578 <panic>
  log.lh.block[i] = b->blockno;
    80004966:	0631                	addi	a2,a2,12
    80004968:	060a                	slli	a2,a2,0x2
    8000496a:	00052797          	auipc	a5,0x52
    8000496e:	a0e78793          	addi	a5,a5,-1522 # 80056378 <log>
    80004972:	963e                	add	a2,a2,a5
    80004974:	00c92783          	lw	a5,12(s2)
    80004978:	c61c                	sw	a5,8(a2)
    bpin(b);
    8000497a:	854a                	mv	a0,s2
    8000497c:	fffff097          	auipc	ra,0xfffff
    80004980:	cd6080e7          	jalr	-810(ra) # 80003652 <bpin>
    log.lh.n++;
    80004984:	00052717          	auipc	a4,0x52
    80004988:	9f470713          	addi	a4,a4,-1548 # 80056378 <log>
    8000498c:	5b5c                	lw	a5,52(a4)
    8000498e:	2785                	addiw	a5,a5,1
    80004990:	db5c                	sw	a5,52(a4)
    80004992:	bf61                	j	8000492a <log_write+0x86>
  log.lh.block[i] = b->blockno;
    80004994:	00c92783          	lw	a5,12(s2)
    80004998:	00052717          	auipc	a4,0x52
    8000499c:	a0f72c23          	sw	a5,-1512(a4) # 800563b0 <log+0x38>
  if (i == log.lh.n) {  // Add new block to log?
    800049a0:	f649                	bnez	a2,8000492a <log_write+0x86>
    800049a2:	bfe1                	j	8000497a <log_write+0xd6>
  for (i = 0; i < log.lh.n; i++) {
    800049a4:	4781                	li	a5,0
    800049a6:	bf95                	j	8000491a <log_write+0x76>

00000000800049a8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049a8:	1101                	addi	sp,sp,-32
    800049aa:	ec06                	sd	ra,24(sp)
    800049ac:	e822                	sd	s0,16(sp)
    800049ae:	e426                	sd	s1,8(sp)
    800049b0:	e04a                	sd	s2,0(sp)
    800049b2:	1000                	addi	s0,sp,32
    800049b4:	84aa                	mv	s1,a0
    800049b6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049b8:	00004597          	auipc	a1,0x4
    800049bc:	d3858593          	addi	a1,a1,-712 # 800086f0 <syscalls+0x258>
    800049c0:	0521                	addi	a0,a0,8
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	650080e7          	jalr	1616(ra) # 80001012 <initlock>
  lk->name = name;
    800049ca:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    800049ce:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049d2:	0204a823          	sw	zero,48(s1)
}
    800049d6:	60e2                	ld	ra,24(sp)
    800049d8:	6442                	ld	s0,16(sp)
    800049da:	64a2                	ld	s1,8(sp)
    800049dc:	6902                	ld	s2,0(sp)
    800049de:	6105                	addi	sp,sp,32
    800049e0:	8082                	ret

00000000800049e2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049e2:	1101                	addi	sp,sp,-32
    800049e4:	ec06                	sd	ra,24(sp)
    800049e6:	e822                	sd	s0,16(sp)
    800049e8:	e426                	sd	s1,8(sp)
    800049ea:	e04a                	sd	s2,0(sp)
    800049ec:	1000                	addi	s0,sp,32
    800049ee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049f0:	00850913          	addi	s2,a0,8
    800049f4:	854a                	mv	a0,s2
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	490080e7          	jalr	1168(ra) # 80000e86 <acquire>
  while (lk->locked) {
    800049fe:	409c                	lw	a5,0(s1)
    80004a00:	cb89                	beqz	a5,80004a12 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a02:	85ca                	mv	a1,s2
    80004a04:	8526                	mv	a0,s1
    80004a06:	ffffe097          	auipc	ra,0xffffe
    80004a0a:	d4a080e7          	jalr	-694(ra) # 80002750 <sleep>
  while (lk->locked) {
    80004a0e:	409c                	lw	a5,0(s1)
    80004a10:	fbed                	bnez	a5,80004a02 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a12:	4785                	li	a5,1
    80004a14:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a16:	ffffd097          	auipc	ra,0xffffd
    80004a1a:	520080e7          	jalr	1312(ra) # 80001f36 <myproc>
    80004a1e:	413c                	lw	a5,64(a0)
    80004a20:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    80004a22:	854a                	mv	a0,s2
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	532080e7          	jalr	1330(ra) # 80000f56 <release>
}
    80004a2c:	60e2                	ld	ra,24(sp)
    80004a2e:	6442                	ld	s0,16(sp)
    80004a30:	64a2                	ld	s1,8(sp)
    80004a32:	6902                	ld	s2,0(sp)
    80004a34:	6105                	addi	sp,sp,32
    80004a36:	8082                	ret

0000000080004a38 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a38:	1101                	addi	sp,sp,-32
    80004a3a:	ec06                	sd	ra,24(sp)
    80004a3c:	e822                	sd	s0,16(sp)
    80004a3e:	e426                	sd	s1,8(sp)
    80004a40:	e04a                	sd	s2,0(sp)
    80004a42:	1000                	addi	s0,sp,32
    80004a44:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a46:	00850913          	addi	s2,a0,8
    80004a4a:	854a                	mv	a0,s2
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	43a080e7          	jalr	1082(ra) # 80000e86 <acquire>
  lk->locked = 0;
    80004a54:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a58:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    80004a5c:	8526                	mv	a0,s1
    80004a5e:	ffffe097          	auipc	ra,0xffffe
    80004a62:	e78080e7          	jalr	-392(ra) # 800028d6 <wakeup>
  release(&lk->lk);
    80004a66:	854a                	mv	a0,s2
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	4ee080e7          	jalr	1262(ra) # 80000f56 <release>
}
    80004a70:	60e2                	ld	ra,24(sp)
    80004a72:	6442                	ld	s0,16(sp)
    80004a74:	64a2                	ld	s1,8(sp)
    80004a76:	6902                	ld	s2,0(sp)
    80004a78:	6105                	addi	sp,sp,32
    80004a7a:	8082                	ret

0000000080004a7c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a7c:	7179                	addi	sp,sp,-48
    80004a7e:	f406                	sd	ra,40(sp)
    80004a80:	f022                	sd	s0,32(sp)
    80004a82:	ec26                	sd	s1,24(sp)
    80004a84:	e84a                	sd	s2,16(sp)
    80004a86:	e44e                	sd	s3,8(sp)
    80004a88:	1800                	addi	s0,sp,48
    80004a8a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a8c:	00850913          	addi	s2,a0,8
    80004a90:	854a                	mv	a0,s2
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	3f4080e7          	jalr	1012(ra) # 80000e86 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a9a:	409c                	lw	a5,0(s1)
    80004a9c:	ef99                	bnez	a5,80004aba <holdingsleep+0x3e>
    80004a9e:	4481                	li	s1,0
  release(&lk->lk);
    80004aa0:	854a                	mv	a0,s2
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	4b4080e7          	jalr	1204(ra) # 80000f56 <release>
  return r;
}
    80004aaa:	8526                	mv	a0,s1
    80004aac:	70a2                	ld	ra,40(sp)
    80004aae:	7402                	ld	s0,32(sp)
    80004ab0:	64e2                	ld	s1,24(sp)
    80004ab2:	6942                	ld	s2,16(sp)
    80004ab4:	69a2                	ld	s3,8(sp)
    80004ab6:	6145                	addi	sp,sp,48
    80004ab8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aba:	0304a983          	lw	s3,48(s1)
    80004abe:	ffffd097          	auipc	ra,0xffffd
    80004ac2:	478080e7          	jalr	1144(ra) # 80001f36 <myproc>
    80004ac6:	4124                	lw	s1,64(a0)
    80004ac8:	413484b3          	sub	s1,s1,s3
    80004acc:	0014b493          	seqz	s1,s1
    80004ad0:	bfc1                	j	80004aa0 <holdingsleep+0x24>

0000000080004ad2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ad2:	1141                	addi	sp,sp,-16
    80004ad4:	e406                	sd	ra,8(sp)
    80004ad6:	e022                	sd	s0,0(sp)
    80004ad8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ada:	00004597          	auipc	a1,0x4
    80004ade:	c2658593          	addi	a1,a1,-986 # 80008700 <syscalls+0x268>
    80004ae2:	00052517          	auipc	a0,0x52
    80004ae6:	9e650513          	addi	a0,a0,-1562 # 800564c8 <ftable>
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	528080e7          	jalr	1320(ra) # 80001012 <initlock>
}
    80004af2:	60a2                	ld	ra,8(sp)
    80004af4:	6402                	ld	s0,0(sp)
    80004af6:	0141                	addi	sp,sp,16
    80004af8:	8082                	ret

0000000080004afa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004afa:	1101                	addi	sp,sp,-32
    80004afc:	ec06                	sd	ra,24(sp)
    80004afe:	e822                	sd	s0,16(sp)
    80004b00:	e426                	sd	s1,8(sp)
    80004b02:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b04:	00052517          	auipc	a0,0x52
    80004b08:	9c450513          	addi	a0,a0,-1596 # 800564c8 <ftable>
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	37a080e7          	jalr	890(ra) # 80000e86 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
    80004b14:	00052797          	auipc	a5,0x52
    80004b18:	9b478793          	addi	a5,a5,-1612 # 800564c8 <ftable>
    80004b1c:	53dc                	lw	a5,36(a5)
    80004b1e:	cb8d                	beqz	a5,80004b50 <filealloc+0x56>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b20:	00052497          	auipc	s1,0x52
    80004b24:	9f048493          	addi	s1,s1,-1552 # 80056510 <ftable+0x48>
    80004b28:	00053717          	auipc	a4,0x53
    80004b2c:	96070713          	addi	a4,a4,-1696 # 80057488 <ftable+0xfc0>
    if(f->ref == 0){
    80004b30:	40dc                	lw	a5,4(s1)
    80004b32:	c39d                	beqz	a5,80004b58 <filealloc+0x5e>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b34:	02848493          	addi	s1,s1,40
    80004b38:	fee49ce3          	bne	s1,a4,80004b30 <filealloc+0x36>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b3c:	00052517          	auipc	a0,0x52
    80004b40:	98c50513          	addi	a0,a0,-1652 # 800564c8 <ftable>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	412080e7          	jalr	1042(ra) # 80000f56 <release>
  return 0;
    80004b4c:	4481                	li	s1,0
    80004b4e:	a839                	j	80004b6c <filealloc+0x72>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b50:	00052497          	auipc	s1,0x52
    80004b54:	99848493          	addi	s1,s1,-1640 # 800564e8 <ftable+0x20>
      f->ref = 1;
    80004b58:	4785                	li	a5,1
    80004b5a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b5c:	00052517          	auipc	a0,0x52
    80004b60:	96c50513          	addi	a0,a0,-1684 # 800564c8 <ftable>
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	3f2080e7          	jalr	1010(ra) # 80000f56 <release>
}
    80004b6c:	8526                	mv	a0,s1
    80004b6e:	60e2                	ld	ra,24(sp)
    80004b70:	6442                	ld	s0,16(sp)
    80004b72:	64a2                	ld	s1,8(sp)
    80004b74:	6105                	addi	sp,sp,32
    80004b76:	8082                	ret

0000000080004b78 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b78:	1101                	addi	sp,sp,-32
    80004b7a:	ec06                	sd	ra,24(sp)
    80004b7c:	e822                	sd	s0,16(sp)
    80004b7e:	e426                	sd	s1,8(sp)
    80004b80:	1000                	addi	s0,sp,32
    80004b82:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b84:	00052517          	auipc	a0,0x52
    80004b88:	94450513          	addi	a0,a0,-1724 # 800564c8 <ftable>
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	2fa080e7          	jalr	762(ra) # 80000e86 <acquire>
  if(f->ref < 1)
    80004b94:	40dc                	lw	a5,4(s1)
    80004b96:	02f05263          	blez	a5,80004bba <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b9a:	2785                	addiw	a5,a5,1
    80004b9c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b9e:	00052517          	auipc	a0,0x52
    80004ba2:	92a50513          	addi	a0,a0,-1750 # 800564c8 <ftable>
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	3b0080e7          	jalr	944(ra) # 80000f56 <release>
  return f;
}
    80004bae:	8526                	mv	a0,s1
    80004bb0:	60e2                	ld	ra,24(sp)
    80004bb2:	6442                	ld	s0,16(sp)
    80004bb4:	64a2                	ld	s1,8(sp)
    80004bb6:	6105                	addi	sp,sp,32
    80004bb8:	8082                	ret
    panic("filedup");
    80004bba:	00004517          	auipc	a0,0x4
    80004bbe:	b4e50513          	addi	a0,a0,-1202 # 80008708 <syscalls+0x270>
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	9b6080e7          	jalr	-1610(ra) # 80000578 <panic>

0000000080004bca <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bca:	7139                	addi	sp,sp,-64
    80004bcc:	fc06                	sd	ra,56(sp)
    80004bce:	f822                	sd	s0,48(sp)
    80004bd0:	f426                	sd	s1,40(sp)
    80004bd2:	f04a                	sd	s2,32(sp)
    80004bd4:	ec4e                	sd	s3,24(sp)
    80004bd6:	e852                	sd	s4,16(sp)
    80004bd8:	e456                	sd	s5,8(sp)
    80004bda:	0080                	addi	s0,sp,64
    80004bdc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bde:	00052517          	auipc	a0,0x52
    80004be2:	8ea50513          	addi	a0,a0,-1814 # 800564c8 <ftable>
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	2a0080e7          	jalr	672(ra) # 80000e86 <acquire>
  if(f->ref < 1)
    80004bee:	40dc                	lw	a5,4(s1)
    80004bf0:	06f05163          	blez	a5,80004c52 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bf4:	37fd                	addiw	a5,a5,-1
    80004bf6:	0007871b          	sext.w	a4,a5
    80004bfa:	c0dc                	sw	a5,4(s1)
    80004bfc:	06e04363          	bgtz	a4,80004c62 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c00:	0004a903          	lw	s2,0(s1)
    80004c04:	0094ca83          	lbu	s5,9(s1)
    80004c08:	0104ba03          	ld	s4,16(s1)
    80004c0c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c10:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c14:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c18:	00052517          	auipc	a0,0x52
    80004c1c:	8b050513          	addi	a0,a0,-1872 # 800564c8 <ftable>
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	336080e7          	jalr	822(ra) # 80000f56 <release>

  if(ff.type == FD_PIPE){
    80004c28:	4785                	li	a5,1
    80004c2a:	04f90d63          	beq	s2,a5,80004c84 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c2e:	3979                	addiw	s2,s2,-2
    80004c30:	4785                	li	a5,1
    80004c32:	0527e063          	bltu	a5,s2,80004c72 <fileclose+0xa8>
    begin_op();
    80004c36:	00000097          	auipc	ra,0x0
    80004c3a:	a90080e7          	jalr	-1392(ra) # 800046c6 <begin_op>
    iput(ff.ip);
    80004c3e:	854e                	mv	a0,s3
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	266080e7          	jalr	614(ra) # 80003ea6 <iput>
    end_op();
    80004c48:	00000097          	auipc	ra,0x0
    80004c4c:	afe080e7          	jalr	-1282(ra) # 80004746 <end_op>
    80004c50:	a00d                	j	80004c72 <fileclose+0xa8>
    panic("fileclose");
    80004c52:	00004517          	auipc	a0,0x4
    80004c56:	abe50513          	addi	a0,a0,-1346 # 80008710 <syscalls+0x278>
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	91e080e7          	jalr	-1762(ra) # 80000578 <panic>
    release(&ftable.lock);
    80004c62:	00052517          	auipc	a0,0x52
    80004c66:	86650513          	addi	a0,a0,-1946 # 800564c8 <ftable>
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	2ec080e7          	jalr	748(ra) # 80000f56 <release>
  }
}
    80004c72:	70e2                	ld	ra,56(sp)
    80004c74:	7442                	ld	s0,48(sp)
    80004c76:	74a2                	ld	s1,40(sp)
    80004c78:	7902                	ld	s2,32(sp)
    80004c7a:	69e2                	ld	s3,24(sp)
    80004c7c:	6a42                	ld	s4,16(sp)
    80004c7e:	6aa2                	ld	s5,8(sp)
    80004c80:	6121                	addi	sp,sp,64
    80004c82:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c84:	85d6                	mv	a1,s5
    80004c86:	8552                	mv	a0,s4
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	364080e7          	jalr	868(ra) # 80004fec <pipeclose>
    80004c90:	b7cd                	j	80004c72 <fileclose+0xa8>

0000000080004c92 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c92:	715d                	addi	sp,sp,-80
    80004c94:	e486                	sd	ra,72(sp)
    80004c96:	e0a2                	sd	s0,64(sp)
    80004c98:	fc26                	sd	s1,56(sp)
    80004c9a:	f84a                	sd	s2,48(sp)
    80004c9c:	f44e                	sd	s3,40(sp)
    80004c9e:	0880                	addi	s0,sp,80
    80004ca0:	84aa                	mv	s1,a0
    80004ca2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	292080e7          	jalr	658(ra) # 80001f36 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cac:	409c                	lw	a5,0(s1)
    80004cae:	37f9                	addiw	a5,a5,-2
    80004cb0:	4705                	li	a4,1
    80004cb2:	04f76763          	bltu	a4,a5,80004d00 <filestat+0x6e>
    80004cb6:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cb8:	6c88                	ld	a0,24(s1)
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	030080e7          	jalr	48(ra) # 80003cea <ilock>
    stati(f->ip, &st);
    80004cc2:	fb840593          	addi	a1,s0,-72
    80004cc6:	6c88                	ld	a0,24(s1)
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	2ae080e7          	jalr	686(ra) # 80003f76 <stati>
    iunlock(f->ip);
    80004cd0:	6c88                	ld	a0,24(s1)
    80004cd2:	fffff097          	auipc	ra,0xfffff
    80004cd6:	0dc080e7          	jalr	220(ra) # 80003dae <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cda:	46e1                	li	a3,24
    80004cdc:	fb840613          	addi	a2,s0,-72
    80004ce0:	85ce                	mv	a1,s3
    80004ce2:	05893503          	ld	a0,88(s2)
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	f2c080e7          	jalr	-212(ra) # 80001c12 <copyout>
    80004cee:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cf2:	60a6                	ld	ra,72(sp)
    80004cf4:	6406                	ld	s0,64(sp)
    80004cf6:	74e2                	ld	s1,56(sp)
    80004cf8:	7942                	ld	s2,48(sp)
    80004cfa:	79a2                	ld	s3,40(sp)
    80004cfc:	6161                	addi	sp,sp,80
    80004cfe:	8082                	ret
  return -1;
    80004d00:	557d                	li	a0,-1
    80004d02:	bfc5                	j	80004cf2 <filestat+0x60>

0000000080004d04 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d04:	7179                	addi	sp,sp,-48
    80004d06:	f406                	sd	ra,40(sp)
    80004d08:	f022                	sd	s0,32(sp)
    80004d0a:	ec26                	sd	s1,24(sp)
    80004d0c:	e84a                	sd	s2,16(sp)
    80004d0e:	e44e                	sd	s3,8(sp)
    80004d10:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d12:	00854783          	lbu	a5,8(a0)
    80004d16:	c3d5                	beqz	a5,80004dba <fileread+0xb6>
    80004d18:	89b2                	mv	s3,a2
    80004d1a:	892e                	mv	s2,a1
    80004d1c:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    80004d1e:	411c                	lw	a5,0(a0)
    80004d20:	4705                	li	a4,1
    80004d22:	04e78963          	beq	a5,a4,80004d74 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d26:	470d                	li	a4,3
    80004d28:	04e78d63          	beq	a5,a4,80004d82 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d2c:	4709                	li	a4,2
    80004d2e:	06e79e63          	bne	a5,a4,80004daa <fileread+0xa6>
    ilock(f->ip);
    80004d32:	6d08                	ld	a0,24(a0)
    80004d34:	fffff097          	auipc	ra,0xfffff
    80004d38:	fb6080e7          	jalr	-74(ra) # 80003cea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d3c:	874e                	mv	a4,s3
    80004d3e:	5094                	lw	a3,32(s1)
    80004d40:	864a                	mv	a2,s2
    80004d42:	4585                	li	a1,1
    80004d44:	6c88                	ld	a0,24(s1)
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	25a080e7          	jalr	602(ra) # 80003fa0 <readi>
    80004d4e:	892a                	mv	s2,a0
    80004d50:	00a05563          	blez	a0,80004d5a <fileread+0x56>
      f->off += r;
    80004d54:	509c                	lw	a5,32(s1)
    80004d56:	9fa9                	addw	a5,a5,a0
    80004d58:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d5a:	6c88                	ld	a0,24(s1)
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	052080e7          	jalr	82(ra) # 80003dae <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d64:	854a                	mv	a0,s2
    80004d66:	70a2                	ld	ra,40(sp)
    80004d68:	7402                	ld	s0,32(sp)
    80004d6a:	64e2                	ld	s1,24(sp)
    80004d6c:	6942                	ld	s2,16(sp)
    80004d6e:	69a2                	ld	s3,8(sp)
    80004d70:	6145                	addi	sp,sp,48
    80004d72:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d74:	6908                	ld	a0,16(a0)
    80004d76:	00000097          	auipc	ra,0x0
    80004d7a:	420080e7          	jalr	1056(ra) # 80005196 <piperead>
    80004d7e:	892a                	mv	s2,a0
    80004d80:	b7d5                	j	80004d64 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d82:	02451783          	lh	a5,36(a0)
    80004d86:	03079693          	slli	a3,a5,0x30
    80004d8a:	92c1                	srli	a3,a3,0x30
    80004d8c:	4725                	li	a4,9
    80004d8e:	02d76863          	bltu	a4,a3,80004dbe <fileread+0xba>
    80004d92:	0792                	slli	a5,a5,0x4
    80004d94:	00051717          	auipc	a4,0x51
    80004d98:	69470713          	addi	a4,a4,1684 # 80056428 <devsw>
    80004d9c:	97ba                	add	a5,a5,a4
    80004d9e:	639c                	ld	a5,0(a5)
    80004da0:	c38d                	beqz	a5,80004dc2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004da2:	4505                	li	a0,1
    80004da4:	9782                	jalr	a5
    80004da6:	892a                	mv	s2,a0
    80004da8:	bf75                	j	80004d64 <fileread+0x60>
    panic("fileread");
    80004daa:	00004517          	auipc	a0,0x4
    80004dae:	97650513          	addi	a0,a0,-1674 # 80008720 <syscalls+0x288>
    80004db2:	ffffb097          	auipc	ra,0xffffb
    80004db6:	7c6080e7          	jalr	1990(ra) # 80000578 <panic>
    return -1;
    80004dba:	597d                	li	s2,-1
    80004dbc:	b765                	j	80004d64 <fileread+0x60>
      return -1;
    80004dbe:	597d                	li	s2,-1
    80004dc0:	b755                	j	80004d64 <fileread+0x60>
    80004dc2:	597d                	li	s2,-1
    80004dc4:	b745                	j	80004d64 <fileread+0x60>

0000000080004dc6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004dc6:	00954783          	lbu	a5,9(a0)
    80004dca:	12078e63          	beqz	a5,80004f06 <filewrite+0x140>
{
    80004dce:	715d                	addi	sp,sp,-80
    80004dd0:	e486                	sd	ra,72(sp)
    80004dd2:	e0a2                	sd	s0,64(sp)
    80004dd4:	fc26                	sd	s1,56(sp)
    80004dd6:	f84a                	sd	s2,48(sp)
    80004dd8:	f44e                	sd	s3,40(sp)
    80004dda:	f052                	sd	s4,32(sp)
    80004ddc:	ec56                	sd	s5,24(sp)
    80004dde:	e85a                	sd	s6,16(sp)
    80004de0:	e45e                	sd	s7,8(sp)
    80004de2:	e062                	sd	s8,0(sp)
    80004de4:	0880                	addi	s0,sp,80
    80004de6:	8ab2                	mv	s5,a2
    80004de8:	8b2e                	mv	s6,a1
    80004dea:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    80004dec:	411c                	lw	a5,0(a0)
    80004dee:	4705                	li	a4,1
    80004df0:	02e78263          	beq	a5,a4,80004e14 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004df4:	470d                	li	a4,3
    80004df6:	02e78563          	beq	a5,a4,80004e20 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dfa:	4709                	li	a4,2
    80004dfc:	0ee79d63          	bne	a5,a4,80004ef6 <filewrite+0x130>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e00:	0ec05763          	blez	a2,80004eee <filewrite+0x128>
    int i = 0;
    80004e04:	4901                	li	s2,0
    80004e06:	6b85                	lui	s7,0x1
    80004e08:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e0c:	6c05                	lui	s8,0x1
    80004e0e:	c00c0c1b          	addiw	s8,s8,-1024
    80004e12:	a061                	j	80004e9a <filewrite+0xd4>
    ret = pipewrite(f->pipe, addr, n);
    80004e14:	6908                	ld	a0,16(a0)
    80004e16:	00000097          	auipc	ra,0x0
    80004e1a:	250080e7          	jalr	592(ra) # 80005066 <pipewrite>
    80004e1e:	a065                	j	80004ec6 <filewrite+0x100>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e20:	02451783          	lh	a5,36(a0)
    80004e24:	03079693          	slli	a3,a5,0x30
    80004e28:	92c1                	srli	a3,a3,0x30
    80004e2a:	4725                	li	a4,9
    80004e2c:	0cd76f63          	bltu	a4,a3,80004f0a <filewrite+0x144>
    80004e30:	0792                	slli	a5,a5,0x4
    80004e32:	00051717          	auipc	a4,0x51
    80004e36:	5f670713          	addi	a4,a4,1526 # 80056428 <devsw>
    80004e3a:	97ba                	add	a5,a5,a4
    80004e3c:	679c                	ld	a5,8(a5)
    80004e3e:	cbe1                	beqz	a5,80004f0e <filewrite+0x148>
    ret = devsw[f->major].write(1, addr, n);
    80004e40:	4505                	li	a0,1
    80004e42:	9782                	jalr	a5
    80004e44:	a049                	j	80004ec6 <filewrite+0x100>
    80004e46:	00098a1b          	sext.w	s4,s3
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e4a:	00000097          	auipc	ra,0x0
    80004e4e:	87c080e7          	jalr	-1924(ra) # 800046c6 <begin_op>
      ilock(f->ip);
    80004e52:	6c88                	ld	a0,24(s1)
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	e96080e7          	jalr	-362(ra) # 80003cea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e5c:	8752                	mv	a4,s4
    80004e5e:	5094                	lw	a3,32(s1)
    80004e60:	01690633          	add	a2,s2,s6
    80004e64:	4585                	li	a1,1
    80004e66:	6c88                	ld	a0,24(s1)
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	230080e7          	jalr	560(ra) # 80004098 <writei>
    80004e70:	89aa                	mv	s3,a0
    80004e72:	02a05c63          	blez	a0,80004eaa <filewrite+0xe4>
        f->off += r;
    80004e76:	509c                	lw	a5,32(s1)
    80004e78:	9fa9                	addw	a5,a5,a0
    80004e7a:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    80004e7c:	6c88                	ld	a0,24(s1)
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	f30080e7          	jalr	-208(ra) # 80003dae <iunlock>
      end_op();
    80004e86:	00000097          	auipc	ra,0x0
    80004e8a:	8c0080e7          	jalr	-1856(ra) # 80004746 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004e8e:	05499863          	bne	s3,s4,80004ede <filewrite+0x118>
        panic("short filewrite");
      i += r;
    80004e92:	012a093b          	addw	s2,s4,s2
    while(i < n){
    80004e96:	03595563          	ble	s5,s2,80004ec0 <filewrite+0xfa>
      int n1 = n - i;
    80004e9a:	412a87bb          	subw	a5,s5,s2
      if(n1 > max)
    80004e9e:	89be                	mv	s3,a5
    80004ea0:	2781                	sext.w	a5,a5
    80004ea2:	fafbd2e3          	ble	a5,s7,80004e46 <filewrite+0x80>
    80004ea6:	89e2                	mv	s3,s8
    80004ea8:	bf79                	j	80004e46 <filewrite+0x80>
      iunlock(f->ip);
    80004eaa:	6c88                	ld	a0,24(s1)
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	f02080e7          	jalr	-254(ra) # 80003dae <iunlock>
      end_op();
    80004eb4:	00000097          	auipc	ra,0x0
    80004eb8:	892080e7          	jalr	-1902(ra) # 80004746 <end_op>
      if(r < 0)
    80004ebc:	fc09d9e3          	bgez	s3,80004e8e <filewrite+0xc8>
    }
    ret = (i == n ? n : -1);
    80004ec0:	8556                	mv	a0,s5
    80004ec2:	032a9863          	bne	s5,s2,80004ef2 <filewrite+0x12c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ec6:	60a6                	ld	ra,72(sp)
    80004ec8:	6406                	ld	s0,64(sp)
    80004eca:	74e2                	ld	s1,56(sp)
    80004ecc:	7942                	ld	s2,48(sp)
    80004ece:	79a2                	ld	s3,40(sp)
    80004ed0:	7a02                	ld	s4,32(sp)
    80004ed2:	6ae2                	ld	s5,24(sp)
    80004ed4:	6b42                	ld	s6,16(sp)
    80004ed6:	6ba2                	ld	s7,8(sp)
    80004ed8:	6c02                	ld	s8,0(sp)
    80004eda:	6161                	addi	sp,sp,80
    80004edc:	8082                	ret
        panic("short filewrite");
    80004ede:	00004517          	auipc	a0,0x4
    80004ee2:	85250513          	addi	a0,a0,-1966 # 80008730 <syscalls+0x298>
    80004ee6:	ffffb097          	auipc	ra,0xffffb
    80004eea:	692080e7          	jalr	1682(ra) # 80000578 <panic>
    int i = 0;
    80004eee:	4901                	li	s2,0
    80004ef0:	bfc1                	j	80004ec0 <filewrite+0xfa>
    ret = (i == n ? n : -1);
    80004ef2:	557d                	li	a0,-1
    80004ef4:	bfc9                	j	80004ec6 <filewrite+0x100>
    panic("filewrite");
    80004ef6:	00004517          	auipc	a0,0x4
    80004efa:	84a50513          	addi	a0,a0,-1974 # 80008740 <syscalls+0x2a8>
    80004efe:	ffffb097          	auipc	ra,0xffffb
    80004f02:	67a080e7          	jalr	1658(ra) # 80000578 <panic>
    return -1;
    80004f06:	557d                	li	a0,-1
}
    80004f08:	8082                	ret
      return -1;
    80004f0a:	557d                	li	a0,-1
    80004f0c:	bf6d                	j	80004ec6 <filewrite+0x100>
    80004f0e:	557d                	li	a0,-1
    80004f10:	bf5d                	j	80004ec6 <filewrite+0x100>

0000000080004f12 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f12:	7179                	addi	sp,sp,-48
    80004f14:	f406                	sd	ra,40(sp)
    80004f16:	f022                	sd	s0,32(sp)
    80004f18:	ec26                	sd	s1,24(sp)
    80004f1a:	e84a                	sd	s2,16(sp)
    80004f1c:	e44e                	sd	s3,8(sp)
    80004f1e:	e052                	sd	s4,0(sp)
    80004f20:	1800                	addi	s0,sp,48
    80004f22:	84aa                	mv	s1,a0
    80004f24:	892e                	mv	s2,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f26:	0005b023          	sd	zero,0(a1)
    80004f2a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f2e:	00000097          	auipc	ra,0x0
    80004f32:	bcc080e7          	jalr	-1076(ra) # 80004afa <filealloc>
    80004f36:	e088                	sd	a0,0(s1)
    80004f38:	c551                	beqz	a0,80004fc4 <pipealloc+0xb2>
    80004f3a:	00000097          	auipc	ra,0x0
    80004f3e:	bc0080e7          	jalr	-1088(ra) # 80004afa <filealloc>
    80004f42:	00a93023          	sd	a0,0(s2)
    80004f46:	c92d                	beqz	a0,80004fb8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	e12080e7          	jalr	-494(ra) # 80000d5a <kalloc>
    80004f50:	89aa                	mv	s3,a0
    80004f52:	c125                	beqz	a0,80004fb2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f54:	4a05                	li	s4,1
    80004f56:	23452423          	sw	s4,552(a0)
  pi->writeopen = 1;
    80004f5a:	23452623          	sw	s4,556(a0)
  pi->nwrite = 0;
    80004f5e:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004f62:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004f66:	00003597          	auipc	a1,0x3
    80004f6a:	7ea58593          	addi	a1,a1,2026 # 80008750 <syscalls+0x2b8>
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	0a4080e7          	jalr	164(ra) # 80001012 <initlock>
  (*f0)->type = FD_PIPE;
    80004f76:	609c                	ld	a5,0(s1)
    80004f78:	0147a023          	sw	s4,0(a5)
  (*f0)->readable = 1;
    80004f7c:	609c                	ld	a5,0(s1)
    80004f7e:	01478423          	sb	s4,8(a5)
  (*f0)->writable = 0;
    80004f82:	609c                	ld	a5,0(s1)
    80004f84:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f88:	609c                	ld	a5,0(s1)
    80004f8a:	0137b823          	sd	s3,16(a5)
  (*f1)->type = FD_PIPE;
    80004f8e:	00093783          	ld	a5,0(s2)
    80004f92:	0147a023          	sw	s4,0(a5)
  (*f1)->readable = 0;
    80004f96:	00093783          	ld	a5,0(s2)
    80004f9a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f9e:	00093783          	ld	a5,0(s2)
    80004fa2:	014784a3          	sb	s4,9(a5)
  (*f1)->pipe = pi;
    80004fa6:	00093783          	ld	a5,0(s2)
    80004faa:	0137b823          	sd	s3,16(a5)
  return 0;
    80004fae:	4501                	li	a0,0
    80004fb0:	a025                	j	80004fd8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004fb2:	6088                	ld	a0,0(s1)
    80004fb4:	e501                	bnez	a0,80004fbc <pipealloc+0xaa>
    80004fb6:	a039                	j	80004fc4 <pipealloc+0xb2>
    80004fb8:	6088                	ld	a0,0(s1)
    80004fba:	c51d                	beqz	a0,80004fe8 <pipealloc+0xd6>
    fileclose(*f0);
    80004fbc:	00000097          	auipc	ra,0x0
    80004fc0:	c0e080e7          	jalr	-1010(ra) # 80004bca <fileclose>
  if(*f1)
    80004fc4:	00093783          	ld	a5,0(s2)
    fileclose(*f1);
  return -1;
    80004fc8:	557d                	li	a0,-1
  if(*f1)
    80004fca:	c799                	beqz	a5,80004fd8 <pipealloc+0xc6>
    fileclose(*f1);
    80004fcc:	853e                	mv	a0,a5
    80004fce:	00000097          	auipc	ra,0x0
    80004fd2:	bfc080e7          	jalr	-1028(ra) # 80004bca <fileclose>
  return -1;
    80004fd6:	557d                	li	a0,-1
}
    80004fd8:	70a2                	ld	ra,40(sp)
    80004fda:	7402                	ld	s0,32(sp)
    80004fdc:	64e2                	ld	s1,24(sp)
    80004fde:	6942                	ld	s2,16(sp)
    80004fe0:	69a2                	ld	s3,8(sp)
    80004fe2:	6a02                	ld	s4,0(sp)
    80004fe4:	6145                	addi	sp,sp,48
    80004fe6:	8082                	ret
  return -1;
    80004fe8:	557d                	li	a0,-1
    80004fea:	b7fd                	j	80004fd8 <pipealloc+0xc6>

0000000080004fec <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fec:	1101                	addi	sp,sp,-32
    80004fee:	ec06                	sd	ra,24(sp)
    80004ff0:	e822                	sd	s0,16(sp)
    80004ff2:	e426                	sd	s1,8(sp)
    80004ff4:	e04a                	sd	s2,0(sp)
    80004ff6:	1000                	addi	s0,sp,32
    80004ff8:	84aa                	mv	s1,a0
    80004ffa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	e8a080e7          	jalr	-374(ra) # 80000e86 <acquire>
  if(writable){
    80005004:	04090263          	beqz	s2,80005048 <pipeclose+0x5c>
    pi->writeopen = 0;
    80005008:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    8000500c:	22048513          	addi	a0,s1,544
    80005010:	ffffe097          	auipc	ra,0xffffe
    80005014:	8c6080e7          	jalr	-1850(ra) # 800028d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005018:	2284b783          	ld	a5,552(s1)
    8000501c:	ef9d                	bnez	a5,8000505a <pipeclose+0x6e>
    release(&pi->lock);
    8000501e:	8526                	mv	a0,s1
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	f36080e7          	jalr	-202(ra) # 80000f56 <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	f74080e7          	jalr	-140(ra) # 80000f9e <freelock>
#endif    
    kfree((char*)pi);
    80005032:	8526                	mv	a0,s1
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	c4e080e7          	jalr	-946(ra) # 80000c82 <kfree>
  } else
    release(&pi->lock);
}
    8000503c:	60e2                	ld	ra,24(sp)
    8000503e:	6442                	ld	s0,16(sp)
    80005040:	64a2                	ld	s1,8(sp)
    80005042:	6902                	ld	s2,0(sp)
    80005044:	6105                	addi	sp,sp,32
    80005046:	8082                	ret
    pi->readopen = 0;
    80005048:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    8000504c:	22448513          	addi	a0,s1,548
    80005050:	ffffe097          	auipc	ra,0xffffe
    80005054:	886080e7          	jalr	-1914(ra) # 800028d6 <wakeup>
    80005058:	b7c1                	j	80005018 <pipeclose+0x2c>
    release(&pi->lock);
    8000505a:	8526                	mv	a0,s1
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	efa080e7          	jalr	-262(ra) # 80000f56 <release>
}
    80005064:	bfe1                	j	8000503c <pipeclose+0x50>

0000000080005066 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005066:	7119                	addi	sp,sp,-128
    80005068:	fc86                	sd	ra,120(sp)
    8000506a:	f8a2                	sd	s0,112(sp)
    8000506c:	f4a6                	sd	s1,104(sp)
    8000506e:	f0ca                	sd	s2,96(sp)
    80005070:	ecce                	sd	s3,88(sp)
    80005072:	e8d2                	sd	s4,80(sp)
    80005074:	e4d6                	sd	s5,72(sp)
    80005076:	e0da                	sd	s6,64(sp)
    80005078:	fc5e                	sd	s7,56(sp)
    8000507a:	f862                	sd	s8,48(sp)
    8000507c:	f466                	sd	s9,40(sp)
    8000507e:	f06a                	sd	s10,32(sp)
    80005080:	ec6e                	sd	s11,24(sp)
    80005082:	0100                	addi	s0,sp,128
    80005084:	84aa                	mv	s1,a0
    80005086:	8d2e                	mv	s10,a1
    80005088:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    8000508a:	ffffd097          	auipc	ra,0xffffd
    8000508e:	eac080e7          	jalr	-340(ra) # 80001f36 <myproc>
    80005092:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80005094:	8526                	mv	a0,s1
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	df0080e7          	jalr	-528(ra) # 80000e86 <acquire>
  for(i = 0; i < n; i++){
    8000509e:	0d605f63          	blez	s6,8000517c <pipewrite+0x116>
    800050a2:	89a6                	mv	s3,s1
    800050a4:	3b7d                	addiw	s6,s6,-1
    800050a6:	1b02                	slli	s6,s6,0x20
    800050a8:	020b5b13          	srli	s6,s6,0x20
    800050ac:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    800050ae:	22048a93          	addi	s5,s1,544
      sleep(&pi->nwrite, &pi->lock);
    800050b2:	22448a13          	addi	s4,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050b6:	5dfd                	li	s11,-1
    800050b8:	000b8c9b          	sext.w	s9,s7
    800050bc:	8c66                	mv	s8,s9
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800050be:	2204a783          	lw	a5,544(s1)
    800050c2:	2244a703          	lw	a4,548(s1)
    800050c6:	2007879b          	addiw	a5,a5,512
    800050ca:	06f71763          	bne	a4,a5,80005138 <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    800050ce:	2284a783          	lw	a5,552(s1)
    800050d2:	cf8d                	beqz	a5,8000510c <pipewrite+0xa6>
    800050d4:	03892783          	lw	a5,56(s2)
    800050d8:	eb95                	bnez	a5,8000510c <pipewrite+0xa6>
      wakeup(&pi->nread);
    800050da:	8556                	mv	a0,s5
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	7fa080e7          	jalr	2042(ra) # 800028d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050e4:	85ce                	mv	a1,s3
    800050e6:	8552                	mv	a0,s4
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	668080e7          	jalr	1640(ra) # 80002750 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800050f0:	2204a783          	lw	a5,544(s1)
    800050f4:	2244a703          	lw	a4,548(s1)
    800050f8:	2007879b          	addiw	a5,a5,512
    800050fc:	02f71e63          	bne	a4,a5,80005138 <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80005100:	2284a783          	lw	a5,552(s1)
    80005104:	c781                	beqz	a5,8000510c <pipewrite+0xa6>
    80005106:	03892783          	lw	a5,56(s2)
    8000510a:	dbe1                	beqz	a5,800050da <pipewrite+0x74>
        release(&pi->lock);
    8000510c:	8526                	mv	a0,s1
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	e48080e7          	jalr	-440(ra) # 80000f56 <release>
        return -1;
    80005116:	5c7d                	li	s8,-1
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80005118:	8562                	mv	a0,s8
    8000511a:	70e6                	ld	ra,120(sp)
    8000511c:	7446                	ld	s0,112(sp)
    8000511e:	74a6                	ld	s1,104(sp)
    80005120:	7906                	ld	s2,96(sp)
    80005122:	69e6                	ld	s3,88(sp)
    80005124:	6a46                	ld	s4,80(sp)
    80005126:	6aa6                	ld	s5,72(sp)
    80005128:	6b06                	ld	s6,64(sp)
    8000512a:	7be2                	ld	s7,56(sp)
    8000512c:	7c42                	ld	s8,48(sp)
    8000512e:	7ca2                	ld	s9,40(sp)
    80005130:	7d02                	ld	s10,32(sp)
    80005132:	6de2                	ld	s11,24(sp)
    80005134:	6109                	addi	sp,sp,128
    80005136:	8082                	ret
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005138:	4685                	li	a3,1
    8000513a:	01ab8633          	add	a2,s7,s10
    8000513e:	f8f40593          	addi	a1,s0,-113
    80005142:	05893503          	ld	a0,88(s2)
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	b58080e7          	jalr	-1192(ra) # 80001c9e <copyin>
    8000514e:	03b50863          	beq	a0,s11,8000517e <pipewrite+0x118>
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005152:	2244a783          	lw	a5,548(s1)
    80005156:	0017871b          	addiw	a4,a5,1
    8000515a:	22e4a223          	sw	a4,548(s1)
    8000515e:	1ff7f793          	andi	a5,a5,511
    80005162:	97a6                	add	a5,a5,s1
    80005164:	f8f44703          	lbu	a4,-113(s0)
    80005168:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    8000516c:	001c8c1b          	addiw	s8,s9,1
    80005170:	001b8793          	addi	a5,s7,1
    80005174:	016b8563          	beq	s7,s6,8000517e <pipewrite+0x118>
    80005178:	8bbe                	mv	s7,a5
    8000517a:	bf3d                	j	800050b8 <pipewrite+0x52>
    8000517c:	4c01                	li	s8,0
  wakeup(&pi->nread);
    8000517e:	22048513          	addi	a0,s1,544
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	754080e7          	jalr	1876(ra) # 800028d6 <wakeup>
  release(&pi->lock);
    8000518a:	8526                	mv	a0,s1
    8000518c:	ffffc097          	auipc	ra,0xffffc
    80005190:	dca080e7          	jalr	-566(ra) # 80000f56 <release>
  return i;
    80005194:	b751                	j	80005118 <pipewrite+0xb2>

0000000080005196 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005196:	715d                	addi	sp,sp,-80
    80005198:	e486                	sd	ra,72(sp)
    8000519a:	e0a2                	sd	s0,64(sp)
    8000519c:	fc26                	sd	s1,56(sp)
    8000519e:	f84a                	sd	s2,48(sp)
    800051a0:	f44e                	sd	s3,40(sp)
    800051a2:	f052                	sd	s4,32(sp)
    800051a4:	ec56                	sd	s5,24(sp)
    800051a6:	e85a                	sd	s6,16(sp)
    800051a8:	0880                	addi	s0,sp,80
    800051aa:	84aa                	mv	s1,a0
    800051ac:	89ae                	mv	s3,a1
    800051ae:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051b0:	ffffd097          	auipc	ra,0xffffd
    800051b4:	d86080e7          	jalr	-634(ra) # 80001f36 <myproc>
    800051b8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051ba:	8526                	mv	a0,s1
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	cca080e7          	jalr	-822(ra) # 80000e86 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051c4:	2204a703          	lw	a4,544(s1)
    800051c8:	2244a783          	lw	a5,548(s1)
    800051cc:	06f71b63          	bne	a4,a5,80005242 <piperead+0xac>
    800051d0:	8926                	mv	s2,s1
    800051d2:	22c4a783          	lw	a5,556(s1)
    800051d6:	cf9d                	beqz	a5,80005214 <piperead+0x7e>
    if(pr->killed){
    800051d8:	038a2783          	lw	a5,56(s4)
    800051dc:	e78d                	bnez	a5,80005206 <piperead+0x70>
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051de:	22048b13          	addi	s6,s1,544
    800051e2:	85ca                	mv	a1,s2
    800051e4:	855a                	mv	a0,s6
    800051e6:	ffffd097          	auipc	ra,0xffffd
    800051ea:	56a080e7          	jalr	1386(ra) # 80002750 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051ee:	2204a703          	lw	a4,544(s1)
    800051f2:	2244a783          	lw	a5,548(s1)
    800051f6:	04f71663          	bne	a4,a5,80005242 <piperead+0xac>
    800051fa:	22c4a783          	lw	a5,556(s1)
    800051fe:	cb99                	beqz	a5,80005214 <piperead+0x7e>
    if(pr->killed){
    80005200:	038a2783          	lw	a5,56(s4)
    80005204:	dff9                	beqz	a5,800051e2 <piperead+0x4c>
      release(&pi->lock);
    80005206:	8526                	mv	a0,s1
    80005208:	ffffc097          	auipc	ra,0xffffc
    8000520c:	d4e080e7          	jalr	-690(ra) # 80000f56 <release>
      return -1;
    80005210:	597d                	li	s2,-1
    80005212:	a829                	j	8000522c <piperead+0x96>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(pi->nread == pi->nwrite)
    80005214:	4901                	li	s2,0
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005216:	22448513          	addi	a0,s1,548
    8000521a:	ffffd097          	auipc	ra,0xffffd
    8000521e:	6bc080e7          	jalr	1724(ra) # 800028d6 <wakeup>
  release(&pi->lock);
    80005222:	8526                	mv	a0,s1
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	d32080e7          	jalr	-718(ra) # 80000f56 <release>
  return i;
}
    8000522c:	854a                	mv	a0,s2
    8000522e:	60a6                	ld	ra,72(sp)
    80005230:	6406                	ld	s0,64(sp)
    80005232:	74e2                	ld	s1,56(sp)
    80005234:	7942                	ld	s2,48(sp)
    80005236:	79a2                	ld	s3,40(sp)
    80005238:	7a02                	ld	s4,32(sp)
    8000523a:	6ae2                	ld	s5,24(sp)
    8000523c:	6b42                	ld	s6,16(sp)
    8000523e:	6161                	addi	sp,sp,80
    80005240:	8082                	ret
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005242:	4901                	li	s2,0
    80005244:	fd5059e3          	blez	s5,80005216 <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80005248:	2204a783          	lw	a5,544(s1)
    8000524c:	4901                	li	s2,0
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000524e:	5b7d                	li	s6,-1
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005250:	0017871b          	addiw	a4,a5,1
    80005254:	22e4a023          	sw	a4,544(s1)
    80005258:	1ff7f793          	andi	a5,a5,511
    8000525c:	97a6                	add	a5,a5,s1
    8000525e:	0207c783          	lbu	a5,32(a5)
    80005262:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005266:	4685                	li	a3,1
    80005268:	fbf40613          	addi	a2,s0,-65
    8000526c:	85ce                	mv	a1,s3
    8000526e:	058a3503          	ld	a0,88(s4)
    80005272:	ffffd097          	auipc	ra,0xffffd
    80005276:	9a0080e7          	jalr	-1632(ra) # 80001c12 <copyout>
    8000527a:	f9650ee3          	beq	a0,s6,80005216 <piperead+0x80>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000527e:	2905                	addiw	s2,s2,1
    80005280:	f92a8be3          	beq	s5,s2,80005216 <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80005284:	2204a783          	lw	a5,544(s1)
    80005288:	0985                	addi	s3,s3,1
    8000528a:	2244a703          	lw	a4,548(s1)
    8000528e:	fcf711e3          	bne	a4,a5,80005250 <piperead+0xba>
    80005292:	b751                	j	80005216 <piperead+0x80>

0000000080005294 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005294:	de010113          	addi	sp,sp,-544
    80005298:	20113c23          	sd	ra,536(sp)
    8000529c:	20813823          	sd	s0,528(sp)
    800052a0:	20913423          	sd	s1,520(sp)
    800052a4:	21213023          	sd	s2,512(sp)
    800052a8:	ffce                	sd	s3,504(sp)
    800052aa:	fbd2                	sd	s4,496(sp)
    800052ac:	f7d6                	sd	s5,488(sp)
    800052ae:	f3da                	sd	s6,480(sp)
    800052b0:	efde                	sd	s7,472(sp)
    800052b2:	ebe2                	sd	s8,464(sp)
    800052b4:	e7e6                	sd	s9,456(sp)
    800052b6:	e3ea                	sd	s10,448(sp)
    800052b8:	ff6e                	sd	s11,440(sp)
    800052ba:	1400                	addi	s0,sp,544
    800052bc:	892a                	mv	s2,a0
    800052be:	dea43823          	sd	a0,-528(s0)
    800052c2:	deb43c23          	sd	a1,-520(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052c6:	ffffd097          	auipc	ra,0xffffd
    800052ca:	c70080e7          	jalr	-912(ra) # 80001f36 <myproc>
    800052ce:	84aa                	mv	s1,a0

  begin_op();
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	3f6080e7          	jalr	1014(ra) # 800046c6 <begin_op>

  if((ip = namei(path)) == 0){
    800052d8:	854a                	mv	a0,s2
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	1ce080e7          	jalr	462(ra) # 800044a8 <namei>
    800052e2:	c93d                	beqz	a0,80005358 <exec+0xc4>
    800052e4:	892a                	mv	s2,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	a04080e7          	jalr	-1532(ra) # 80003cea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052ee:	04000713          	li	a4,64
    800052f2:	4681                	li	a3,0
    800052f4:	e4840613          	addi	a2,s0,-440
    800052f8:	4581                	li	a1,0
    800052fa:	854a                	mv	a0,s2
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	ca4080e7          	jalr	-860(ra) # 80003fa0 <readi>
    80005304:	04000793          	li	a5,64
    80005308:	00f51a63          	bne	a0,a5,8000531c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000530c:	e4842703          	lw	a4,-440(s0)
    80005310:	464c47b7          	lui	a5,0x464c4
    80005314:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005318:	04f70663          	beq	a4,a5,80005364 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000531c:	854a                	mv	a0,s2
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	c30080e7          	jalr	-976(ra) # 80003f4e <iunlockput>
    end_op();
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	420080e7          	jalr	1056(ra) # 80004746 <end_op>
  }
  return -1;
    8000532e:	557d                	li	a0,-1
}
    80005330:	21813083          	ld	ra,536(sp)
    80005334:	21013403          	ld	s0,528(sp)
    80005338:	20813483          	ld	s1,520(sp)
    8000533c:	20013903          	ld	s2,512(sp)
    80005340:	79fe                	ld	s3,504(sp)
    80005342:	7a5e                	ld	s4,496(sp)
    80005344:	7abe                	ld	s5,488(sp)
    80005346:	7b1e                	ld	s6,480(sp)
    80005348:	6bfe                	ld	s7,472(sp)
    8000534a:	6c5e                	ld	s8,464(sp)
    8000534c:	6cbe                	ld	s9,456(sp)
    8000534e:	6d1e                	ld	s10,448(sp)
    80005350:	7dfa                	ld	s11,440(sp)
    80005352:	22010113          	addi	sp,sp,544
    80005356:	8082                	ret
    end_op();
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	3ee080e7          	jalr	1006(ra) # 80004746 <end_op>
    return -1;
    80005360:	557d                	li	a0,-1
    80005362:	b7f9                	j	80005330 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005364:	8526                	mv	a0,s1
    80005366:	ffffd097          	auipc	ra,0xffffd
    8000536a:	c96080e7          	jalr	-874(ra) # 80001ffc <proc_pagetable>
    8000536e:	e0a43423          	sd	a0,-504(s0)
    80005372:	d54d                	beqz	a0,8000531c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005374:	e6842983          	lw	s3,-408(s0)
    80005378:	e8045783          	lhu	a5,-384(s0)
    8000537c:	c7ad                	beqz	a5,800053e6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000537e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005380:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005382:	6c05                	lui	s8,0x1
    80005384:	fffc0793          	addi	a5,s8,-1 # fff <_entry-0x7ffff001>
    80005388:	def43423          	sd	a5,-536(s0)
    8000538c:	7cfd                	lui	s9,0xfffff
    8000538e:	ac1d                	j	800055c4 <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005390:	00003517          	auipc	a0,0x3
    80005394:	3c850513          	addi	a0,a0,968 # 80008758 <syscalls+0x2c0>
    80005398:	ffffb097          	auipc	ra,0xffffb
    8000539c:	1e0080e7          	jalr	480(ra) # 80000578 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053a0:	8756                	mv	a4,s5
    800053a2:	009d86bb          	addw	a3,s11,s1
    800053a6:	4581                	li	a1,0
    800053a8:	854a                	mv	a0,s2
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	bf6080e7          	jalr	-1034(ra) # 80003fa0 <readi>
    800053b2:	2501                	sext.w	a0,a0
    800053b4:	1aaa9e63          	bne	s5,a0,80005570 <exec+0x2dc>
  for(i = 0; i < sz; i += PGSIZE){
    800053b8:	6785                	lui	a5,0x1
    800053ba:	9cbd                	addw	s1,s1,a5
    800053bc:	014c8a3b          	addw	s4,s9,s4
    800053c0:	1f74f963          	bleu	s7,s1,800055b2 <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    800053c4:	02049593          	slli	a1,s1,0x20
    800053c8:	9181                	srli	a1,a1,0x20
    800053ca:	95ea                	add	a1,a1,s10
    800053cc:	e0843503          	ld	a0,-504(s0)
    800053d0:	ffffc097          	auipc	ra,0xffffc
    800053d4:	280080e7          	jalr	640(ra) # 80001650 <walkaddr>
    800053d8:	862a                	mv	a2,a0
    if(pa == 0)
    800053da:	d95d                	beqz	a0,80005390 <exec+0xfc>
      n = PGSIZE;
    800053dc:	8ae2                	mv	s5,s8
    if(sz - i < PGSIZE)
    800053de:	fd8a71e3          	bleu	s8,s4,800053a0 <exec+0x10c>
      n = sz - i;
    800053e2:	8ad2                	mv	s5,s4
    800053e4:	bf75                	j	800053a0 <exec+0x10c>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800053e6:	4481                	li	s1,0
  iunlockput(ip);
    800053e8:	854a                	mv	a0,s2
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	b64080e7          	jalr	-1180(ra) # 80003f4e <iunlockput>
  end_op();
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	354080e7          	jalr	852(ra) # 80004746 <end_op>
  p = myproc();
    800053fa:	ffffd097          	auipc	ra,0xffffd
    800053fe:	b3c080e7          	jalr	-1220(ra) # 80001f36 <myproc>
    80005402:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005404:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005408:	6785                	lui	a5,0x1
    8000540a:	17fd                	addi	a5,a5,-1
    8000540c:	94be                	add	s1,s1,a5
    8000540e:	77fd                	lui	a5,0xfffff
    80005410:	8fe5                	and	a5,a5,s1
    80005412:	e0f43023          	sd	a5,-512(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005416:	6609                	lui	a2,0x2
    80005418:	963e                	add	a2,a2,a5
    8000541a:	85be                	mv	a1,a5
    8000541c:	e0843483          	ld	s1,-504(s0)
    80005420:	8526                	mv	a0,s1
    80005422:	ffffc097          	auipc	ra,0xffffc
    80005426:	5a0080e7          	jalr	1440(ra) # 800019c2 <uvmalloc>
    8000542a:	8b2a                	mv	s6,a0
  ip = 0;
    8000542c:	4901                	li	s2,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000542e:	14050163          	beqz	a0,80005570 <exec+0x2dc>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005432:	75f9                	lui	a1,0xffffe
    80005434:	95aa                	add	a1,a1,a0
    80005436:	8526                	mv	a0,s1
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	7a8080e7          	jalr	1960(ra) # 80001be0 <uvmclear>
  stackbase = sp - PGSIZE;
    80005440:	7bfd                	lui	s7,0xfffff
    80005442:	9bda                	add	s7,s7,s6
  for(argc = 0; argv[argc]; argc++) {
    80005444:	df843783          	ld	a5,-520(s0)
    80005448:	6388                	ld	a0,0(a5)
    8000544a:	c925                	beqz	a0,800054ba <exec+0x226>
    8000544c:	e8840993          	addi	s3,s0,-376
    80005450:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005454:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005456:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005458:	ffffc097          	auipc	ra,0xffffc
    8000545c:	fe4080e7          	jalr	-28(ra) # 8000143c <strlen>
    80005460:	2505                	addiw	a0,a0,1
    80005462:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005466:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000546a:	13796863          	bltu	s2,s7,8000559a <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000546e:	df843c83          	ld	s9,-520(s0)
    80005472:	000cba03          	ld	s4,0(s9) # fffffffffffff000 <end+0xffffffff7ffa2fd8>
    80005476:	8552                	mv	a0,s4
    80005478:	ffffc097          	auipc	ra,0xffffc
    8000547c:	fc4080e7          	jalr	-60(ra) # 8000143c <strlen>
    80005480:	0015069b          	addiw	a3,a0,1
    80005484:	8652                	mv	a2,s4
    80005486:	85ca                	mv	a1,s2
    80005488:	e0843503          	ld	a0,-504(s0)
    8000548c:	ffffc097          	auipc	ra,0xffffc
    80005490:	786080e7          	jalr	1926(ra) # 80001c12 <copyout>
    80005494:	10054763          	bltz	a0,800055a2 <exec+0x30e>
    ustack[argc] = sp;
    80005498:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000549c:	0485                	addi	s1,s1,1
    8000549e:	008c8793          	addi	a5,s9,8
    800054a2:	def43c23          	sd	a5,-520(s0)
    800054a6:	008cb503          	ld	a0,8(s9)
    800054aa:	c911                	beqz	a0,800054be <exec+0x22a>
    if(argc >= MAXARG)
    800054ac:	09a1                	addi	s3,s3,8
    800054ae:	fb8995e3          	bne	s3,s8,80005458 <exec+0x1c4>
  sz = sz1;
    800054b2:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800054b6:	4901                	li	s2,0
    800054b8:	a865                	j	80005570 <exec+0x2dc>
  sp = sz;
    800054ba:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800054bc:	4481                	li	s1,0
  ustack[argc] = 0;
    800054be:	00349793          	slli	a5,s1,0x3
    800054c2:	f9040713          	addi	a4,s0,-112
    800054c6:	97ba                	add	a5,a5,a4
    800054c8:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffa2ed0>
  sp -= (argc+1) * sizeof(uint64);
    800054cc:	00148693          	addi	a3,s1,1
    800054d0:	068e                	slli	a3,a3,0x3
    800054d2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800054d6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800054da:	01797663          	bleu	s7,s2,800054e6 <exec+0x252>
  sz = sz1;
    800054de:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800054e2:	4901                	li	s2,0
    800054e4:	a071                	j	80005570 <exec+0x2dc>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800054e6:	e8840613          	addi	a2,s0,-376
    800054ea:	85ca                	mv	a1,s2
    800054ec:	e0843503          	ld	a0,-504(s0)
    800054f0:	ffffc097          	auipc	ra,0xffffc
    800054f4:	722080e7          	jalr	1826(ra) # 80001c12 <copyout>
    800054f8:	0a054963          	bltz	a0,800055aa <exec+0x316>
  p->trapframe->a1 = sp;
    800054fc:	060ab783          	ld	a5,96(s5)
    80005500:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005504:	df043783          	ld	a5,-528(s0)
    80005508:	0007c703          	lbu	a4,0(a5)
    8000550c:	cf11                	beqz	a4,80005528 <exec+0x294>
    8000550e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005510:	02f00693          	li	a3,47
    80005514:	a029                	j	8000551e <exec+0x28a>
  for(last=s=path; *s; s++)
    80005516:	0785                	addi	a5,a5,1
    80005518:	fff7c703          	lbu	a4,-1(a5)
    8000551c:	c711                	beqz	a4,80005528 <exec+0x294>
    if(*s == '/')
    8000551e:	fed71ce3          	bne	a4,a3,80005516 <exec+0x282>
      last = s+1;
    80005522:	def43823          	sd	a5,-528(s0)
    80005526:	bfc5                	j	80005516 <exec+0x282>
  safestrcpy(p->name, last, sizeof(p->name));
    80005528:	4641                	li	a2,16
    8000552a:	df043583          	ld	a1,-528(s0)
    8000552e:	160a8513          	addi	a0,s5,352
    80005532:	ffffc097          	auipc	ra,0xffffc
    80005536:	ed8080e7          	jalr	-296(ra) # 8000140a <safestrcpy>
  oldpagetable = p->pagetable;
    8000553a:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    8000553e:	e0843783          	ld	a5,-504(s0)
    80005542:	04fabc23          	sd	a5,88(s5)
  p->sz = sz;
    80005546:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000554a:	060ab783          	ld	a5,96(s5)
    8000554e:	e6043703          	ld	a4,-416(s0)
    80005552:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005554:	060ab783          	ld	a5,96(s5)
    80005558:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000555c:	85ea                	mv	a1,s10
    8000555e:	ffffd097          	auipc	ra,0xffffd
    80005562:	b3a080e7          	jalr	-1222(ra) # 80002098 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005566:	0004851b          	sext.w	a0,s1
    8000556a:	b3d9                	j	80005330 <exec+0x9c>
    8000556c:	e0943023          	sd	s1,-512(s0)
    proc_freepagetable(pagetable, sz);
    80005570:	e0043583          	ld	a1,-512(s0)
    80005574:	e0843503          	ld	a0,-504(s0)
    80005578:	ffffd097          	auipc	ra,0xffffd
    8000557c:	b20080e7          	jalr	-1248(ra) # 80002098 <proc_freepagetable>
  if(ip){
    80005580:	d8091ee3          	bnez	s2,8000531c <exec+0x88>
  return -1;
    80005584:	557d                	li	a0,-1
    80005586:	b36d                	j	80005330 <exec+0x9c>
    80005588:	e0943023          	sd	s1,-512(s0)
    8000558c:	b7d5                	j	80005570 <exec+0x2dc>
    8000558e:	e0943023          	sd	s1,-512(s0)
    80005592:	bff9                	j	80005570 <exec+0x2dc>
    80005594:	e0943023          	sd	s1,-512(s0)
    80005598:	bfe1                	j	80005570 <exec+0x2dc>
  sz = sz1;
    8000559a:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    8000559e:	4901                	li	s2,0
    800055a0:	bfc1                	j	80005570 <exec+0x2dc>
  sz = sz1;
    800055a2:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800055a6:	4901                	li	s2,0
    800055a8:	b7e1                	j	80005570 <exec+0x2dc>
  sz = sz1;
    800055aa:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800055ae:	4901                	li	s2,0
    800055b0:	b7c1                	j	80005570 <exec+0x2dc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055b2:	e0043483          	ld	s1,-512(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055b6:	2b05                	addiw	s6,s6,1
    800055b8:	0389899b          	addiw	s3,s3,56
    800055bc:	e8045783          	lhu	a5,-384(s0)
    800055c0:	e2fb54e3          	ble	a5,s6,800053e8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055c4:	2981                	sext.w	s3,s3
    800055c6:	03800713          	li	a4,56
    800055ca:	86ce                	mv	a3,s3
    800055cc:	e1040613          	addi	a2,s0,-496
    800055d0:	4581                	li	a1,0
    800055d2:	854a                	mv	a0,s2
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	9cc080e7          	jalr	-1588(ra) # 80003fa0 <readi>
    800055dc:	03800793          	li	a5,56
    800055e0:	f8f516e3          	bne	a0,a5,8000556c <exec+0x2d8>
    if(ph.type != ELF_PROG_LOAD)
    800055e4:	e1042783          	lw	a5,-496(s0)
    800055e8:	4705                	li	a4,1
    800055ea:	fce796e3          	bne	a5,a4,800055b6 <exec+0x322>
    if(ph.memsz < ph.filesz)
    800055ee:	e3843603          	ld	a2,-456(s0)
    800055f2:	e3043783          	ld	a5,-464(s0)
    800055f6:	f8f669e3          	bltu	a2,a5,80005588 <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800055fa:	e2043783          	ld	a5,-480(s0)
    800055fe:	963e                	add	a2,a2,a5
    80005600:	f8f667e3          	bltu	a2,a5,8000558e <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005604:	85a6                	mv	a1,s1
    80005606:	e0843503          	ld	a0,-504(s0)
    8000560a:	ffffc097          	auipc	ra,0xffffc
    8000560e:	3b8080e7          	jalr	952(ra) # 800019c2 <uvmalloc>
    80005612:	e0a43023          	sd	a0,-512(s0)
    80005616:	dd3d                	beqz	a0,80005594 <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    80005618:	e2043d03          	ld	s10,-480(s0)
    8000561c:	de843783          	ld	a5,-536(s0)
    80005620:	00fd77b3          	and	a5,s10,a5
    80005624:	f7b1                	bnez	a5,80005570 <exec+0x2dc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005626:	e1842d83          	lw	s11,-488(s0)
    8000562a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000562e:	f80b82e3          	beqz	s7,800055b2 <exec+0x31e>
    80005632:	8a5e                	mv	s4,s7
    80005634:	4481                	li	s1,0
    80005636:	b379                	j	800053c4 <exec+0x130>

0000000080005638 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005638:	7179                	addi	sp,sp,-48
    8000563a:	f406                	sd	ra,40(sp)
    8000563c:	f022                	sd	s0,32(sp)
    8000563e:	ec26                	sd	s1,24(sp)
    80005640:	e84a                	sd	s2,16(sp)
    80005642:	1800                	addi	s0,sp,48
    80005644:	892e                	mv	s2,a1
    80005646:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005648:	fdc40593          	addi	a1,s0,-36
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	9ba080e7          	jalr	-1606(ra) # 80003006 <argint>
    80005654:	04054063          	bltz	a0,80005694 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005658:	fdc42703          	lw	a4,-36(s0)
    8000565c:	47bd                	li	a5,15
    8000565e:	02e7ed63          	bltu	a5,a4,80005698 <argfd+0x60>
    80005662:	ffffd097          	auipc	ra,0xffffd
    80005666:	8d4080e7          	jalr	-1836(ra) # 80001f36 <myproc>
    8000566a:	fdc42703          	lw	a4,-36(s0)
    8000566e:	01a70793          	addi	a5,a4,26
    80005672:	078e                	slli	a5,a5,0x3
    80005674:	953e                	add	a0,a0,a5
    80005676:	651c                	ld	a5,8(a0)
    80005678:	c395                	beqz	a5,8000569c <argfd+0x64>
    return -1;
  if(pfd)
    8000567a:	00090463          	beqz	s2,80005682 <argfd+0x4a>
    *pfd = fd;
    8000567e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005682:	4501                	li	a0,0
  if(pf)
    80005684:	c091                	beqz	s1,80005688 <argfd+0x50>
    *pf = f;
    80005686:	e09c                	sd	a5,0(s1)
}
    80005688:	70a2                	ld	ra,40(sp)
    8000568a:	7402                	ld	s0,32(sp)
    8000568c:	64e2                	ld	s1,24(sp)
    8000568e:	6942                	ld	s2,16(sp)
    80005690:	6145                	addi	sp,sp,48
    80005692:	8082                	ret
    return -1;
    80005694:	557d                	li	a0,-1
    80005696:	bfcd                	j	80005688 <argfd+0x50>
    return -1;
    80005698:	557d                	li	a0,-1
    8000569a:	b7fd                	j	80005688 <argfd+0x50>
    8000569c:	557d                	li	a0,-1
    8000569e:	b7ed                	j	80005688 <argfd+0x50>

00000000800056a0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056a0:	1101                	addi	sp,sp,-32
    800056a2:	ec06                	sd	ra,24(sp)
    800056a4:	e822                	sd	s0,16(sp)
    800056a6:	e426                	sd	s1,8(sp)
    800056a8:	1000                	addi	s0,sp,32
    800056aa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056ac:	ffffd097          	auipc	ra,0xffffd
    800056b0:	88a080e7          	jalr	-1910(ra) # 80001f36 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){
    800056b4:	6d7c                	ld	a5,216(a0)
    800056b6:	c395                	beqz	a5,800056da <fdalloc+0x3a>
    800056b8:	0e050713          	addi	a4,a0,224
  for(fd = 0; fd < NOFILE; fd++){
    800056bc:	4785                	li	a5,1
    800056be:	4641                	li	a2,16
    if(p->ofile[fd] == 0){
    800056c0:	6314                	ld	a3,0(a4)
    800056c2:	ce89                	beqz	a3,800056dc <fdalloc+0x3c>
  for(fd = 0; fd < NOFILE; fd++){
    800056c4:	2785                	addiw	a5,a5,1
    800056c6:	0721                	addi	a4,a4,8
    800056c8:	fec79ce3          	bne	a5,a2,800056c0 <fdalloc+0x20>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056cc:	57fd                	li	a5,-1
}
    800056ce:	853e                	mv	a0,a5
    800056d0:	60e2                	ld	ra,24(sp)
    800056d2:	6442                	ld	s0,16(sp)
    800056d4:	64a2                	ld	s1,8(sp)
    800056d6:	6105                	addi	sp,sp,32
    800056d8:	8082                	ret
  for(fd = 0; fd < NOFILE; fd++){
    800056da:	4781                	li	a5,0
      p->ofile[fd] = f;
    800056dc:	01a78713          	addi	a4,a5,26
    800056e0:	070e                	slli	a4,a4,0x3
    800056e2:	953a                	add	a0,a0,a4
    800056e4:	e504                	sd	s1,8(a0)
      return fd;
    800056e6:	b7e5                	j	800056ce <fdalloc+0x2e>

00000000800056e8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056e8:	715d                	addi	sp,sp,-80
    800056ea:	e486                	sd	ra,72(sp)
    800056ec:	e0a2                	sd	s0,64(sp)
    800056ee:	fc26                	sd	s1,56(sp)
    800056f0:	f84a                	sd	s2,48(sp)
    800056f2:	f44e                	sd	s3,40(sp)
    800056f4:	f052                	sd	s4,32(sp)
    800056f6:	ec56                	sd	s5,24(sp)
    800056f8:	0880                	addi	s0,sp,80
    800056fa:	89ae                	mv	s3,a1
    800056fc:	8ab2                	mv	s5,a2
    800056fe:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005700:	fb040593          	addi	a1,s0,-80
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	dc2080e7          	jalr	-574(ra) # 800044c6 <nameiparent>
    8000570c:	892a                	mv	s2,a0
    8000570e:	12050f63          	beqz	a0,8000584c <create+0x164>
    return 0;

  ilock(dp);
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	5d8080e7          	jalr	1496(ra) # 80003cea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000571a:	4601                	li	a2,0
    8000571c:	fb040593          	addi	a1,s0,-80
    80005720:	854a                	mv	a0,s2
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	aac080e7          	jalr	-1364(ra) # 800041ce <dirlookup>
    8000572a:	84aa                	mv	s1,a0
    8000572c:	c921                	beqz	a0,8000577c <create+0x94>
    iunlockput(dp);
    8000572e:	854a                	mv	a0,s2
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	81e080e7          	jalr	-2018(ra) # 80003f4e <iunlockput>
    ilock(ip);
    80005738:	8526                	mv	a0,s1
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	5b0080e7          	jalr	1456(ra) # 80003cea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005742:	2981                	sext.w	s3,s3
    80005744:	4789                	li	a5,2
    80005746:	02f99463          	bne	s3,a5,8000576e <create+0x86>
    8000574a:	04c4d783          	lhu	a5,76(s1)
    8000574e:	37f9                	addiw	a5,a5,-2
    80005750:	17c2                	slli	a5,a5,0x30
    80005752:	93c1                	srli	a5,a5,0x30
    80005754:	4705                	li	a4,1
    80005756:	00f76c63          	bltu	a4,a5,8000576e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000575a:	8526                	mv	a0,s1
    8000575c:	60a6                	ld	ra,72(sp)
    8000575e:	6406                	ld	s0,64(sp)
    80005760:	74e2                	ld	s1,56(sp)
    80005762:	7942                	ld	s2,48(sp)
    80005764:	79a2                	ld	s3,40(sp)
    80005766:	7a02                	ld	s4,32(sp)
    80005768:	6ae2                	ld	s5,24(sp)
    8000576a:	6161                	addi	sp,sp,80
    8000576c:	8082                	ret
    iunlockput(ip);
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	7de080e7          	jalr	2014(ra) # 80003f4e <iunlockput>
    return 0;
    80005778:	4481                	li	s1,0
    8000577a:	b7c5                	j	8000575a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000577c:	85ce                	mv	a1,s3
    8000577e:	00092503          	lw	a0,0(s2)
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	3cc080e7          	jalr	972(ra) # 80003b4e <ialloc>
    8000578a:	84aa                	mv	s1,a0
    8000578c:	c529                	beqz	a0,800057d6 <create+0xee>
  ilock(ip);
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	55c080e7          	jalr	1372(ra) # 80003cea <ilock>
  ip->major = major;
    80005796:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    8000579a:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    8000579e:	4785                	li	a5,1
    800057a0:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800057a4:	8526                	mv	a0,s1
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	478080e7          	jalr	1144(ra) # 80003c1e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057ae:	2981                	sext.w	s3,s3
    800057b0:	4785                	li	a5,1
    800057b2:	02f98a63          	beq	s3,a5,800057e6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057b6:	40d0                	lw	a2,4(s1)
    800057b8:	fb040593          	addi	a1,s0,-80
    800057bc:	854a                	mv	a0,s2
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	c28080e7          	jalr	-984(ra) # 800043e6 <dirlink>
    800057c6:	06054b63          	bltz	a0,8000583c <create+0x154>
  iunlockput(dp);
    800057ca:	854a                	mv	a0,s2
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	782080e7          	jalr	1922(ra) # 80003f4e <iunlockput>
  return ip;
    800057d4:	b759                	j	8000575a <create+0x72>
    panic("create: ialloc");
    800057d6:	00003517          	auipc	a0,0x3
    800057da:	fa250513          	addi	a0,a0,-94 # 80008778 <syscalls+0x2e0>
    800057de:	ffffb097          	auipc	ra,0xffffb
    800057e2:	d9a080e7          	jalr	-614(ra) # 80000578 <panic>
    dp->nlink++;  // for ".."
    800057e6:	05295783          	lhu	a5,82(s2)
    800057ea:	2785                	addiw	a5,a5,1
    800057ec:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    800057f0:	854a                	mv	a0,s2
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	42c080e7          	jalr	1068(ra) # 80003c1e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057fa:	40d0                	lw	a2,4(s1)
    800057fc:	00003597          	auipc	a1,0x3
    80005800:	f8c58593          	addi	a1,a1,-116 # 80008788 <syscalls+0x2f0>
    80005804:	8526                	mv	a0,s1
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	be0080e7          	jalr	-1056(ra) # 800043e6 <dirlink>
    8000580e:	00054f63          	bltz	a0,8000582c <create+0x144>
    80005812:	00492603          	lw	a2,4(s2)
    80005816:	00003597          	auipc	a1,0x3
    8000581a:	f7a58593          	addi	a1,a1,-134 # 80008790 <syscalls+0x2f8>
    8000581e:	8526                	mv	a0,s1
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	bc6080e7          	jalr	-1082(ra) # 800043e6 <dirlink>
    80005828:	f80557e3          	bgez	a0,800057b6 <create+0xce>
      panic("create dots");
    8000582c:	00003517          	auipc	a0,0x3
    80005830:	f6c50513          	addi	a0,a0,-148 # 80008798 <syscalls+0x300>
    80005834:	ffffb097          	auipc	ra,0xffffb
    80005838:	d44080e7          	jalr	-700(ra) # 80000578 <panic>
    panic("create: dirlink");
    8000583c:	00003517          	auipc	a0,0x3
    80005840:	f6c50513          	addi	a0,a0,-148 # 800087a8 <syscalls+0x310>
    80005844:	ffffb097          	auipc	ra,0xffffb
    80005848:	d34080e7          	jalr	-716(ra) # 80000578 <panic>
    return 0;
    8000584c:	84aa                	mv	s1,a0
    8000584e:	b731                	j	8000575a <create+0x72>

0000000080005850 <sys_dup>:
{
    80005850:	7179                	addi	sp,sp,-48
    80005852:	f406                	sd	ra,40(sp)
    80005854:	f022                	sd	s0,32(sp)
    80005856:	ec26                	sd	s1,24(sp)
    80005858:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000585a:	fd840613          	addi	a2,s0,-40
    8000585e:	4581                	li	a1,0
    80005860:	4501                	li	a0,0
    80005862:	00000097          	auipc	ra,0x0
    80005866:	dd6080e7          	jalr	-554(ra) # 80005638 <argfd>
    return -1;
    8000586a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000586c:	02054363          	bltz	a0,80005892 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005870:	fd843503          	ld	a0,-40(s0)
    80005874:	00000097          	auipc	ra,0x0
    80005878:	e2c080e7          	jalr	-468(ra) # 800056a0 <fdalloc>
    8000587c:	84aa                	mv	s1,a0
    return -1;
    8000587e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005880:	00054963          	bltz	a0,80005892 <sys_dup+0x42>
  filedup(f);
    80005884:	fd843503          	ld	a0,-40(s0)
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	2f0080e7          	jalr	752(ra) # 80004b78 <filedup>
  return fd;
    80005890:	87a6                	mv	a5,s1
}
    80005892:	853e                	mv	a0,a5
    80005894:	70a2                	ld	ra,40(sp)
    80005896:	7402                	ld	s0,32(sp)
    80005898:	64e2                	ld	s1,24(sp)
    8000589a:	6145                	addi	sp,sp,48
    8000589c:	8082                	ret

000000008000589e <sys_read>:
{
    8000589e:	7179                	addi	sp,sp,-48
    800058a0:	f406                	sd	ra,40(sp)
    800058a2:	f022                	sd	s0,32(sp)
    800058a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058a6:	fe840613          	addi	a2,s0,-24
    800058aa:	4581                	li	a1,0
    800058ac:	4501                	li	a0,0
    800058ae:	00000097          	auipc	ra,0x0
    800058b2:	d8a080e7          	jalr	-630(ra) # 80005638 <argfd>
    return -1;
    800058b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058b8:	04054163          	bltz	a0,800058fa <sys_read+0x5c>
    800058bc:	fe440593          	addi	a1,s0,-28
    800058c0:	4509                	li	a0,2
    800058c2:	ffffd097          	auipc	ra,0xffffd
    800058c6:	744080e7          	jalr	1860(ra) # 80003006 <argint>
    return -1;
    800058ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058cc:	02054763          	bltz	a0,800058fa <sys_read+0x5c>
    800058d0:	fd840593          	addi	a1,s0,-40
    800058d4:	4505                	li	a0,1
    800058d6:	ffffd097          	auipc	ra,0xffffd
    800058da:	752080e7          	jalr	1874(ra) # 80003028 <argaddr>
    return -1;
    800058de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058e0:	00054d63          	bltz	a0,800058fa <sys_read+0x5c>
  return fileread(f, p, n);
    800058e4:	fe442603          	lw	a2,-28(s0)
    800058e8:	fd843583          	ld	a1,-40(s0)
    800058ec:	fe843503          	ld	a0,-24(s0)
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	414080e7          	jalr	1044(ra) # 80004d04 <fileread>
    800058f8:	87aa                	mv	a5,a0
}
    800058fa:	853e                	mv	a0,a5
    800058fc:	70a2                	ld	ra,40(sp)
    800058fe:	7402                	ld	s0,32(sp)
    80005900:	6145                	addi	sp,sp,48
    80005902:	8082                	ret

0000000080005904 <sys_write>:
{
    80005904:	7179                	addi	sp,sp,-48
    80005906:	f406                	sd	ra,40(sp)
    80005908:	f022                	sd	s0,32(sp)
    8000590a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000590c:	fe840613          	addi	a2,s0,-24
    80005910:	4581                	li	a1,0
    80005912:	4501                	li	a0,0
    80005914:	00000097          	auipc	ra,0x0
    80005918:	d24080e7          	jalr	-732(ra) # 80005638 <argfd>
    return -1;
    8000591c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000591e:	04054163          	bltz	a0,80005960 <sys_write+0x5c>
    80005922:	fe440593          	addi	a1,s0,-28
    80005926:	4509                	li	a0,2
    80005928:	ffffd097          	auipc	ra,0xffffd
    8000592c:	6de080e7          	jalr	1758(ra) # 80003006 <argint>
    return -1;
    80005930:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005932:	02054763          	bltz	a0,80005960 <sys_write+0x5c>
    80005936:	fd840593          	addi	a1,s0,-40
    8000593a:	4505                	li	a0,1
    8000593c:	ffffd097          	auipc	ra,0xffffd
    80005940:	6ec080e7          	jalr	1772(ra) # 80003028 <argaddr>
    return -1;
    80005944:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005946:	00054d63          	bltz	a0,80005960 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000594a:	fe442603          	lw	a2,-28(s0)
    8000594e:	fd843583          	ld	a1,-40(s0)
    80005952:	fe843503          	ld	a0,-24(s0)
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	470080e7          	jalr	1136(ra) # 80004dc6 <filewrite>
    8000595e:	87aa                	mv	a5,a0
}
    80005960:	853e                	mv	a0,a5
    80005962:	70a2                	ld	ra,40(sp)
    80005964:	7402                	ld	s0,32(sp)
    80005966:	6145                	addi	sp,sp,48
    80005968:	8082                	ret

000000008000596a <sys_close>:
{
    8000596a:	1101                	addi	sp,sp,-32
    8000596c:	ec06                	sd	ra,24(sp)
    8000596e:	e822                	sd	s0,16(sp)
    80005970:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005972:	fe040613          	addi	a2,s0,-32
    80005976:	fec40593          	addi	a1,s0,-20
    8000597a:	4501                	li	a0,0
    8000597c:	00000097          	auipc	ra,0x0
    80005980:	cbc080e7          	jalr	-836(ra) # 80005638 <argfd>
    return -1;
    80005984:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005986:	02054463          	bltz	a0,800059ae <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000598a:	ffffc097          	auipc	ra,0xffffc
    8000598e:	5ac080e7          	jalr	1452(ra) # 80001f36 <myproc>
    80005992:	fec42783          	lw	a5,-20(s0)
    80005996:	07e9                	addi	a5,a5,26
    80005998:	078e                	slli	a5,a5,0x3
    8000599a:	953e                	add	a0,a0,a5
    8000599c:	00053423          	sd	zero,8(a0)
  fileclose(f);
    800059a0:	fe043503          	ld	a0,-32(s0)
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	226080e7          	jalr	550(ra) # 80004bca <fileclose>
  return 0;
    800059ac:	4781                	li	a5,0
}
    800059ae:	853e                	mv	a0,a5
    800059b0:	60e2                	ld	ra,24(sp)
    800059b2:	6442                	ld	s0,16(sp)
    800059b4:	6105                	addi	sp,sp,32
    800059b6:	8082                	ret

00000000800059b8 <sys_fstat>:
{
    800059b8:	1101                	addi	sp,sp,-32
    800059ba:	ec06                	sd	ra,24(sp)
    800059bc:	e822                	sd	s0,16(sp)
    800059be:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059c0:	fe840613          	addi	a2,s0,-24
    800059c4:	4581                	li	a1,0
    800059c6:	4501                	li	a0,0
    800059c8:	00000097          	auipc	ra,0x0
    800059cc:	c70080e7          	jalr	-912(ra) # 80005638 <argfd>
    return -1;
    800059d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059d2:	02054563          	bltz	a0,800059fc <sys_fstat+0x44>
    800059d6:	fe040593          	addi	a1,s0,-32
    800059da:	4505                	li	a0,1
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	64c080e7          	jalr	1612(ra) # 80003028 <argaddr>
    return -1;
    800059e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059e6:	00054b63          	bltz	a0,800059fc <sys_fstat+0x44>
  return filestat(f, st);
    800059ea:	fe043583          	ld	a1,-32(s0)
    800059ee:	fe843503          	ld	a0,-24(s0)
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	2a0080e7          	jalr	672(ra) # 80004c92 <filestat>
    800059fa:	87aa                	mv	a5,a0
}
    800059fc:	853e                	mv	a0,a5
    800059fe:	60e2                	ld	ra,24(sp)
    80005a00:	6442                	ld	s0,16(sp)
    80005a02:	6105                	addi	sp,sp,32
    80005a04:	8082                	ret

0000000080005a06 <sys_link>:
{
    80005a06:	7169                	addi	sp,sp,-304
    80005a08:	f606                	sd	ra,296(sp)
    80005a0a:	f222                	sd	s0,288(sp)
    80005a0c:	ee26                	sd	s1,280(sp)
    80005a0e:	ea4a                	sd	s2,272(sp)
    80005a10:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a12:	08000613          	li	a2,128
    80005a16:	ed040593          	addi	a1,s0,-304
    80005a1a:	4501                	li	a0,0
    80005a1c:	ffffd097          	auipc	ra,0xffffd
    80005a20:	62e080e7          	jalr	1582(ra) # 8000304a <argstr>
    return -1;
    80005a24:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a26:	10054e63          	bltz	a0,80005b42 <sys_link+0x13c>
    80005a2a:	08000613          	li	a2,128
    80005a2e:	f5040593          	addi	a1,s0,-176
    80005a32:	4505                	li	a0,1
    80005a34:	ffffd097          	auipc	ra,0xffffd
    80005a38:	616080e7          	jalr	1558(ra) # 8000304a <argstr>
    return -1;
    80005a3c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a3e:	10054263          	bltz	a0,80005b42 <sys_link+0x13c>
  begin_op();
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	c84080e7          	jalr	-892(ra) # 800046c6 <begin_op>
  if((ip = namei(old)) == 0){
    80005a4a:	ed040513          	addi	a0,s0,-304
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	a5a080e7          	jalr	-1446(ra) # 800044a8 <namei>
    80005a56:	84aa                	mv	s1,a0
    80005a58:	c551                	beqz	a0,80005ae4 <sys_link+0xde>
  ilock(ip);
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	290080e7          	jalr	656(ra) # 80003cea <ilock>
  if(ip->type == T_DIR){
    80005a62:	04c49703          	lh	a4,76(s1)
    80005a66:	4785                	li	a5,1
    80005a68:	08f70463          	beq	a4,a5,80005af0 <sys_link+0xea>
  ip->nlink++;
    80005a6c:	0524d783          	lhu	a5,82(s1)
    80005a70:	2785                	addiw	a5,a5,1
    80005a72:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005a76:	8526                	mv	a0,s1
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	1a6080e7          	jalr	422(ra) # 80003c1e <iupdate>
  iunlock(ip);
    80005a80:	8526                	mv	a0,s1
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	32c080e7          	jalr	812(ra) # 80003dae <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a8a:	fd040593          	addi	a1,s0,-48
    80005a8e:	f5040513          	addi	a0,s0,-176
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	a34080e7          	jalr	-1484(ra) # 800044c6 <nameiparent>
    80005a9a:	892a                	mv	s2,a0
    80005a9c:	c935                	beqz	a0,80005b10 <sys_link+0x10a>
  ilock(dp);
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	24c080e7          	jalr	588(ra) # 80003cea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005aa6:	00092703          	lw	a4,0(s2)
    80005aaa:	409c                	lw	a5,0(s1)
    80005aac:	04f71d63          	bne	a4,a5,80005b06 <sys_link+0x100>
    80005ab0:	40d0                	lw	a2,4(s1)
    80005ab2:	fd040593          	addi	a1,s0,-48
    80005ab6:	854a                	mv	a0,s2
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	92e080e7          	jalr	-1746(ra) # 800043e6 <dirlink>
    80005ac0:	04054363          	bltz	a0,80005b06 <sys_link+0x100>
  iunlockput(dp);
    80005ac4:	854a                	mv	a0,s2
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	488080e7          	jalr	1160(ra) # 80003f4e <iunlockput>
  iput(ip);
    80005ace:	8526                	mv	a0,s1
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	3d6080e7          	jalr	982(ra) # 80003ea6 <iput>
  end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	c6e080e7          	jalr	-914(ra) # 80004746 <end_op>
  return 0;
    80005ae0:	4781                	li	a5,0
    80005ae2:	a085                	j	80005b42 <sys_link+0x13c>
    end_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	c62080e7          	jalr	-926(ra) # 80004746 <end_op>
    return -1;
    80005aec:	57fd                	li	a5,-1
    80005aee:	a891                	j	80005b42 <sys_link+0x13c>
    iunlockput(ip);
    80005af0:	8526                	mv	a0,s1
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	45c080e7          	jalr	1116(ra) # 80003f4e <iunlockput>
    end_op();
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	c4c080e7          	jalr	-948(ra) # 80004746 <end_op>
    return -1;
    80005b02:	57fd                	li	a5,-1
    80005b04:	a83d                	j	80005b42 <sys_link+0x13c>
    iunlockput(dp);
    80005b06:	854a                	mv	a0,s2
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	446080e7          	jalr	1094(ra) # 80003f4e <iunlockput>
  ilock(ip);
    80005b10:	8526                	mv	a0,s1
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	1d8080e7          	jalr	472(ra) # 80003cea <ilock>
  ip->nlink--;
    80005b1a:	0524d783          	lhu	a5,82(s1)
    80005b1e:	37fd                	addiw	a5,a5,-1
    80005b20:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005b24:	8526                	mv	a0,s1
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	0f8080e7          	jalr	248(ra) # 80003c1e <iupdate>
  iunlockput(ip);
    80005b2e:	8526                	mv	a0,s1
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	41e080e7          	jalr	1054(ra) # 80003f4e <iunlockput>
  end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	c0e080e7          	jalr	-1010(ra) # 80004746 <end_op>
  return -1;
    80005b40:	57fd                	li	a5,-1
}
    80005b42:	853e                	mv	a0,a5
    80005b44:	70b2                	ld	ra,296(sp)
    80005b46:	7412                	ld	s0,288(sp)
    80005b48:	64f2                	ld	s1,280(sp)
    80005b4a:	6952                	ld	s2,272(sp)
    80005b4c:	6155                	addi	sp,sp,304
    80005b4e:	8082                	ret

0000000080005b50 <sys_unlink>:
{
    80005b50:	7151                	addi	sp,sp,-240
    80005b52:	f586                	sd	ra,232(sp)
    80005b54:	f1a2                	sd	s0,224(sp)
    80005b56:	eda6                	sd	s1,216(sp)
    80005b58:	e9ca                	sd	s2,208(sp)
    80005b5a:	e5ce                	sd	s3,200(sp)
    80005b5c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b5e:	08000613          	li	a2,128
    80005b62:	f3040593          	addi	a1,s0,-208
    80005b66:	4501                	li	a0,0
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	4e2080e7          	jalr	1250(ra) # 8000304a <argstr>
    80005b70:	16054f63          	bltz	a0,80005cee <sys_unlink+0x19e>
  begin_op();
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	b52080e7          	jalr	-1198(ra) # 800046c6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b7c:	fb040593          	addi	a1,s0,-80
    80005b80:	f3040513          	addi	a0,s0,-208
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	942080e7          	jalr	-1726(ra) # 800044c6 <nameiparent>
    80005b8c:	89aa                	mv	s3,a0
    80005b8e:	c979                	beqz	a0,80005c64 <sys_unlink+0x114>
  ilock(dp);
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	15a080e7          	jalr	346(ra) # 80003cea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b98:	00003597          	auipc	a1,0x3
    80005b9c:	bf058593          	addi	a1,a1,-1040 # 80008788 <syscalls+0x2f0>
    80005ba0:	fb040513          	addi	a0,s0,-80
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	610080e7          	jalr	1552(ra) # 800041b4 <namecmp>
    80005bac:	14050863          	beqz	a0,80005cfc <sys_unlink+0x1ac>
    80005bb0:	00003597          	auipc	a1,0x3
    80005bb4:	be058593          	addi	a1,a1,-1056 # 80008790 <syscalls+0x2f8>
    80005bb8:	fb040513          	addi	a0,s0,-80
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	5f8080e7          	jalr	1528(ra) # 800041b4 <namecmp>
    80005bc4:	12050c63          	beqz	a0,80005cfc <sys_unlink+0x1ac>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bc8:	f2c40613          	addi	a2,s0,-212
    80005bcc:	fb040593          	addi	a1,s0,-80
    80005bd0:	854e                	mv	a0,s3
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	5fc080e7          	jalr	1532(ra) # 800041ce <dirlookup>
    80005bda:	84aa                	mv	s1,a0
    80005bdc:	12050063          	beqz	a0,80005cfc <sys_unlink+0x1ac>
  ilock(ip);
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	10a080e7          	jalr	266(ra) # 80003cea <ilock>
  if(ip->nlink < 1)
    80005be8:	05249783          	lh	a5,82(s1)
    80005bec:	08f05263          	blez	a5,80005c70 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005bf0:	04c49703          	lh	a4,76(s1)
    80005bf4:	4785                	li	a5,1
    80005bf6:	08f70563          	beq	a4,a5,80005c80 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005bfa:	4641                	li	a2,16
    80005bfc:	4581                	li	a1,0
    80005bfe:	fc040513          	addi	a0,s0,-64
    80005c02:	ffffb097          	auipc	ra,0xffffb
    80005c06:	690080e7          	jalr	1680(ra) # 80001292 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c0a:	4741                	li	a4,16
    80005c0c:	f2c42683          	lw	a3,-212(s0)
    80005c10:	fc040613          	addi	a2,s0,-64
    80005c14:	4581                	li	a1,0
    80005c16:	854e                	mv	a0,s3
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	480080e7          	jalr	1152(ra) # 80004098 <writei>
    80005c20:	47c1                	li	a5,16
    80005c22:	0af51363          	bne	a0,a5,80005cc8 <sys_unlink+0x178>
  if(ip->type == T_DIR){
    80005c26:	04c49703          	lh	a4,76(s1)
    80005c2a:	4785                	li	a5,1
    80005c2c:	0af70663          	beq	a4,a5,80005cd8 <sys_unlink+0x188>
  iunlockput(dp);
    80005c30:	854e                	mv	a0,s3
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	31c080e7          	jalr	796(ra) # 80003f4e <iunlockput>
  ip->nlink--;
    80005c3a:	0524d783          	lhu	a5,82(s1)
    80005c3e:	37fd                	addiw	a5,a5,-1
    80005c40:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005c44:	8526                	mv	a0,s1
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	fd8080e7          	jalr	-40(ra) # 80003c1e <iupdate>
  iunlockput(ip);
    80005c4e:	8526                	mv	a0,s1
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	2fe080e7          	jalr	766(ra) # 80003f4e <iunlockput>
  end_op();
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	aee080e7          	jalr	-1298(ra) # 80004746 <end_op>
  return 0;
    80005c60:	4501                	li	a0,0
    80005c62:	a07d                	j	80005d10 <sys_unlink+0x1c0>
    end_op();
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	ae2080e7          	jalr	-1310(ra) # 80004746 <end_op>
    return -1;
    80005c6c:	557d                	li	a0,-1
    80005c6e:	a04d                	j	80005d10 <sys_unlink+0x1c0>
    panic("unlink: nlink < 1");
    80005c70:	00003517          	auipc	a0,0x3
    80005c74:	b4850513          	addi	a0,a0,-1208 # 800087b8 <syscalls+0x320>
    80005c78:	ffffb097          	auipc	ra,0xffffb
    80005c7c:	900080e7          	jalr	-1792(ra) # 80000578 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c80:	48f8                	lw	a4,84(s1)
    80005c82:	02000793          	li	a5,32
    80005c86:	f6e7fae3          	bleu	a4,a5,80005bfa <sys_unlink+0xaa>
    80005c8a:	02000913          	li	s2,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c8e:	4741                	li	a4,16
    80005c90:	86ca                	mv	a3,s2
    80005c92:	f1840613          	addi	a2,s0,-232
    80005c96:	4581                	li	a1,0
    80005c98:	8526                	mv	a0,s1
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	306080e7          	jalr	774(ra) # 80003fa0 <readi>
    80005ca2:	47c1                	li	a5,16
    80005ca4:	00f51a63          	bne	a0,a5,80005cb8 <sys_unlink+0x168>
    if(de.inum != 0)
    80005ca8:	f1845783          	lhu	a5,-232(s0)
    80005cac:	e3b9                	bnez	a5,80005cf2 <sys_unlink+0x1a2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cae:	2941                	addiw	s2,s2,16
    80005cb0:	48fc                	lw	a5,84(s1)
    80005cb2:	fcf96ee3          	bltu	s2,a5,80005c8e <sys_unlink+0x13e>
    80005cb6:	b791                	j	80005bfa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cb8:	00003517          	auipc	a0,0x3
    80005cbc:	b1850513          	addi	a0,a0,-1256 # 800087d0 <syscalls+0x338>
    80005cc0:	ffffb097          	auipc	ra,0xffffb
    80005cc4:	8b8080e7          	jalr	-1864(ra) # 80000578 <panic>
    panic("unlink: writei");
    80005cc8:	00003517          	auipc	a0,0x3
    80005ccc:	b2050513          	addi	a0,a0,-1248 # 800087e8 <syscalls+0x350>
    80005cd0:	ffffb097          	auipc	ra,0xffffb
    80005cd4:	8a8080e7          	jalr	-1880(ra) # 80000578 <panic>
    dp->nlink--;
    80005cd8:	0529d783          	lhu	a5,82(s3)
    80005cdc:	37fd                	addiw	a5,a5,-1
    80005cde:	04f99923          	sh	a5,82(s3)
    iupdate(dp);
    80005ce2:	854e                	mv	a0,s3
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	f3a080e7          	jalr	-198(ra) # 80003c1e <iupdate>
    80005cec:	b791                	j	80005c30 <sys_unlink+0xe0>
    return -1;
    80005cee:	557d                	li	a0,-1
    80005cf0:	a005                	j	80005d10 <sys_unlink+0x1c0>
    iunlockput(ip);
    80005cf2:	8526                	mv	a0,s1
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	25a080e7          	jalr	602(ra) # 80003f4e <iunlockput>
  iunlockput(dp);
    80005cfc:	854e                	mv	a0,s3
    80005cfe:	ffffe097          	auipc	ra,0xffffe
    80005d02:	250080e7          	jalr	592(ra) # 80003f4e <iunlockput>
  end_op();
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	a40080e7          	jalr	-1472(ra) # 80004746 <end_op>
  return -1;
    80005d0e:	557d                	li	a0,-1
}
    80005d10:	70ae                	ld	ra,232(sp)
    80005d12:	740e                	ld	s0,224(sp)
    80005d14:	64ee                	ld	s1,216(sp)
    80005d16:	694e                	ld	s2,208(sp)
    80005d18:	69ae                	ld	s3,200(sp)
    80005d1a:	616d                	addi	sp,sp,240
    80005d1c:	8082                	ret

0000000080005d1e <sys_open>:

uint64
sys_open(void)
{
    80005d1e:	7131                	addi	sp,sp,-192
    80005d20:	fd06                	sd	ra,184(sp)
    80005d22:	f922                	sd	s0,176(sp)
    80005d24:	f526                	sd	s1,168(sp)
    80005d26:	f14a                	sd	s2,160(sp)
    80005d28:	ed4e                	sd	s3,152(sp)
    80005d2a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d2c:	08000613          	li	a2,128
    80005d30:	f5040593          	addi	a1,s0,-176
    80005d34:	4501                	li	a0,0
    80005d36:	ffffd097          	auipc	ra,0xffffd
    80005d3a:	314080e7          	jalr	788(ra) # 8000304a <argstr>
    return -1;
    80005d3e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d40:	0c054163          	bltz	a0,80005e02 <sys_open+0xe4>
    80005d44:	f4c40593          	addi	a1,s0,-180
    80005d48:	4505                	li	a0,1
    80005d4a:	ffffd097          	auipc	ra,0xffffd
    80005d4e:	2bc080e7          	jalr	700(ra) # 80003006 <argint>
    80005d52:	0a054863          	bltz	a0,80005e02 <sys_open+0xe4>

  begin_op();
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	970080e7          	jalr	-1680(ra) # 800046c6 <begin_op>

  if(omode & O_CREATE){
    80005d5e:	f4c42783          	lw	a5,-180(s0)
    80005d62:	2007f793          	andi	a5,a5,512
    80005d66:	cbdd                	beqz	a5,80005e1c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d68:	4681                	li	a3,0
    80005d6a:	4601                	li	a2,0
    80005d6c:	4589                	li	a1,2
    80005d6e:	f5040513          	addi	a0,s0,-176
    80005d72:	00000097          	auipc	ra,0x0
    80005d76:	976080e7          	jalr	-1674(ra) # 800056e8 <create>
    80005d7a:	892a                	mv	s2,a0
    if(ip == 0){
    80005d7c:	c959                	beqz	a0,80005e12 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d7e:	04c91703          	lh	a4,76(s2)
    80005d82:	478d                	li	a5,3
    80005d84:	00f71763          	bne	a4,a5,80005d92 <sys_open+0x74>
    80005d88:	04e95703          	lhu	a4,78(s2)
    80005d8c:	47a5                	li	a5,9
    80005d8e:	0ce7ec63          	bltu	a5,a4,80005e66 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	d68080e7          	jalr	-664(ra) # 80004afa <filealloc>
    80005d9a:	89aa                	mv	s3,a0
    80005d9c:	10050263          	beqz	a0,80005ea0 <sys_open+0x182>
    80005da0:	00000097          	auipc	ra,0x0
    80005da4:	900080e7          	jalr	-1792(ra) # 800056a0 <fdalloc>
    80005da8:	84aa                	mv	s1,a0
    80005daa:	0e054663          	bltz	a0,80005e96 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005dae:	04c91703          	lh	a4,76(s2)
    80005db2:	478d                	li	a5,3
    80005db4:	0cf70463          	beq	a4,a5,80005e7c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005db8:	4789                	li	a5,2
    80005dba:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005dbe:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005dc2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005dc6:	f4c42783          	lw	a5,-180(s0)
    80005dca:	0017c713          	xori	a4,a5,1
    80005dce:	8b05                	andi	a4,a4,1
    80005dd0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005dd4:	0037f713          	andi	a4,a5,3
    80005dd8:	00e03733          	snez	a4,a4
    80005ddc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005de0:	4007f793          	andi	a5,a5,1024
    80005de4:	c791                	beqz	a5,80005df0 <sys_open+0xd2>
    80005de6:	04c91703          	lh	a4,76(s2)
    80005dea:	4789                	li	a5,2
    80005dec:	08f70f63          	beq	a4,a5,80005e8a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005df0:	854a                	mv	a0,s2
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	fbc080e7          	jalr	-68(ra) # 80003dae <iunlock>
  end_op();
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	94c080e7          	jalr	-1716(ra) # 80004746 <end_op>

  return fd;
}
    80005e02:	8526                	mv	a0,s1
    80005e04:	70ea                	ld	ra,184(sp)
    80005e06:	744a                	ld	s0,176(sp)
    80005e08:	74aa                	ld	s1,168(sp)
    80005e0a:	790a                	ld	s2,160(sp)
    80005e0c:	69ea                	ld	s3,152(sp)
    80005e0e:	6129                	addi	sp,sp,192
    80005e10:	8082                	ret
      end_op();
    80005e12:	fffff097          	auipc	ra,0xfffff
    80005e16:	934080e7          	jalr	-1740(ra) # 80004746 <end_op>
      return -1;
    80005e1a:	b7e5                	j	80005e02 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e1c:	f5040513          	addi	a0,s0,-176
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	688080e7          	jalr	1672(ra) # 800044a8 <namei>
    80005e28:	892a                	mv	s2,a0
    80005e2a:	c905                	beqz	a0,80005e5a <sys_open+0x13c>
    ilock(ip);
    80005e2c:	ffffe097          	auipc	ra,0xffffe
    80005e30:	ebe080e7          	jalr	-322(ra) # 80003cea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e34:	04c91703          	lh	a4,76(s2)
    80005e38:	4785                	li	a5,1
    80005e3a:	f4f712e3          	bne	a4,a5,80005d7e <sys_open+0x60>
    80005e3e:	f4c42783          	lw	a5,-180(s0)
    80005e42:	dba1                	beqz	a5,80005d92 <sys_open+0x74>
      iunlockput(ip);
    80005e44:	854a                	mv	a0,s2
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	108080e7          	jalr	264(ra) # 80003f4e <iunlockput>
      end_op();
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	8f8080e7          	jalr	-1800(ra) # 80004746 <end_op>
      return -1;
    80005e56:	54fd                	li	s1,-1
    80005e58:	b76d                	j	80005e02 <sys_open+0xe4>
      end_op();
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	8ec080e7          	jalr	-1812(ra) # 80004746 <end_op>
      return -1;
    80005e62:	54fd                	li	s1,-1
    80005e64:	bf79                	j	80005e02 <sys_open+0xe4>
    iunlockput(ip);
    80005e66:	854a                	mv	a0,s2
    80005e68:	ffffe097          	auipc	ra,0xffffe
    80005e6c:	0e6080e7          	jalr	230(ra) # 80003f4e <iunlockput>
    end_op();
    80005e70:	fffff097          	auipc	ra,0xfffff
    80005e74:	8d6080e7          	jalr	-1834(ra) # 80004746 <end_op>
    return -1;
    80005e78:	54fd                	li	s1,-1
    80005e7a:	b761                	j	80005e02 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e7c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e80:	04e91783          	lh	a5,78(s2)
    80005e84:	02f99223          	sh	a5,36(s3)
    80005e88:	bf2d                	j	80005dc2 <sys_open+0xa4>
    itrunc(ip);
    80005e8a:	854a                	mv	a0,s2
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	f6e080e7          	jalr	-146(ra) # 80003dfa <itrunc>
    80005e94:	bfb1                	j	80005df0 <sys_open+0xd2>
      fileclose(f);
    80005e96:	854e                	mv	a0,s3
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	d32080e7          	jalr	-718(ra) # 80004bca <fileclose>
    iunlockput(ip);
    80005ea0:	854a                	mv	a0,s2
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	0ac080e7          	jalr	172(ra) # 80003f4e <iunlockput>
    end_op();
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	89c080e7          	jalr	-1892(ra) # 80004746 <end_op>
    return -1;
    80005eb2:	54fd                	li	s1,-1
    80005eb4:	b7b9                	j	80005e02 <sys_open+0xe4>

0000000080005eb6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005eb6:	7175                	addi	sp,sp,-144
    80005eb8:	e506                	sd	ra,136(sp)
    80005eba:	e122                	sd	s0,128(sp)
    80005ebc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	808080e7          	jalr	-2040(ra) # 800046c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ec6:	08000613          	li	a2,128
    80005eca:	f7040593          	addi	a1,s0,-144
    80005ece:	4501                	li	a0,0
    80005ed0:	ffffd097          	auipc	ra,0xffffd
    80005ed4:	17a080e7          	jalr	378(ra) # 8000304a <argstr>
    80005ed8:	02054963          	bltz	a0,80005f0a <sys_mkdir+0x54>
    80005edc:	4681                	li	a3,0
    80005ede:	4601                	li	a2,0
    80005ee0:	4585                	li	a1,1
    80005ee2:	f7040513          	addi	a0,s0,-144
    80005ee6:	00000097          	auipc	ra,0x0
    80005eea:	802080e7          	jalr	-2046(ra) # 800056e8 <create>
    80005eee:	cd11                	beqz	a0,80005f0a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	05e080e7          	jalr	94(ra) # 80003f4e <iunlockput>
  end_op();
    80005ef8:	fffff097          	auipc	ra,0xfffff
    80005efc:	84e080e7          	jalr	-1970(ra) # 80004746 <end_op>
  return 0;
    80005f00:	4501                	li	a0,0
}
    80005f02:	60aa                	ld	ra,136(sp)
    80005f04:	640a                	ld	s0,128(sp)
    80005f06:	6149                	addi	sp,sp,144
    80005f08:	8082                	ret
    end_op();
    80005f0a:	fffff097          	auipc	ra,0xfffff
    80005f0e:	83c080e7          	jalr	-1988(ra) # 80004746 <end_op>
    return -1;
    80005f12:	557d                	li	a0,-1
    80005f14:	b7fd                	j	80005f02 <sys_mkdir+0x4c>

0000000080005f16 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f16:	7135                	addi	sp,sp,-160
    80005f18:	ed06                	sd	ra,152(sp)
    80005f1a:	e922                	sd	s0,144(sp)
    80005f1c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f1e:	ffffe097          	auipc	ra,0xffffe
    80005f22:	7a8080e7          	jalr	1960(ra) # 800046c6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f26:	08000613          	li	a2,128
    80005f2a:	f7040593          	addi	a1,s0,-144
    80005f2e:	4501                	li	a0,0
    80005f30:	ffffd097          	auipc	ra,0xffffd
    80005f34:	11a080e7          	jalr	282(ra) # 8000304a <argstr>
    80005f38:	04054a63          	bltz	a0,80005f8c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f3c:	f6c40593          	addi	a1,s0,-148
    80005f40:	4505                	li	a0,1
    80005f42:	ffffd097          	auipc	ra,0xffffd
    80005f46:	0c4080e7          	jalr	196(ra) # 80003006 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f4a:	04054163          	bltz	a0,80005f8c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f4e:	f6840593          	addi	a1,s0,-152
    80005f52:	4509                	li	a0,2
    80005f54:	ffffd097          	auipc	ra,0xffffd
    80005f58:	0b2080e7          	jalr	178(ra) # 80003006 <argint>
     argint(1, &major) < 0 ||
    80005f5c:	02054863          	bltz	a0,80005f8c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f60:	f6841683          	lh	a3,-152(s0)
    80005f64:	f6c41603          	lh	a2,-148(s0)
    80005f68:	458d                	li	a1,3
    80005f6a:	f7040513          	addi	a0,s0,-144
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	77a080e7          	jalr	1914(ra) # 800056e8 <create>
     argint(2, &minor) < 0 ||
    80005f76:	c919                	beqz	a0,80005f8c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f78:	ffffe097          	auipc	ra,0xffffe
    80005f7c:	fd6080e7          	jalr	-42(ra) # 80003f4e <iunlockput>
  end_op();
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	7c6080e7          	jalr	1990(ra) # 80004746 <end_op>
  return 0;
    80005f88:	4501                	li	a0,0
    80005f8a:	a031                	j	80005f96 <sys_mknod+0x80>
    end_op();
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	7ba080e7          	jalr	1978(ra) # 80004746 <end_op>
    return -1;
    80005f94:	557d                	li	a0,-1
}
    80005f96:	60ea                	ld	ra,152(sp)
    80005f98:	644a                	ld	s0,144(sp)
    80005f9a:	610d                	addi	sp,sp,160
    80005f9c:	8082                	ret

0000000080005f9e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f9e:	7135                	addi	sp,sp,-160
    80005fa0:	ed06                	sd	ra,152(sp)
    80005fa2:	e922                	sd	s0,144(sp)
    80005fa4:	e526                	sd	s1,136(sp)
    80005fa6:	e14a                	sd	s2,128(sp)
    80005fa8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005faa:	ffffc097          	auipc	ra,0xffffc
    80005fae:	f8c080e7          	jalr	-116(ra) # 80001f36 <myproc>
    80005fb2:	892a                	mv	s2,a0
  
  begin_op();
    80005fb4:	ffffe097          	auipc	ra,0xffffe
    80005fb8:	712080e7          	jalr	1810(ra) # 800046c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fbc:	08000613          	li	a2,128
    80005fc0:	f6040593          	addi	a1,s0,-160
    80005fc4:	4501                	li	a0,0
    80005fc6:	ffffd097          	auipc	ra,0xffffd
    80005fca:	084080e7          	jalr	132(ra) # 8000304a <argstr>
    80005fce:	04054b63          	bltz	a0,80006024 <sys_chdir+0x86>
    80005fd2:	f6040513          	addi	a0,s0,-160
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	4d2080e7          	jalr	1234(ra) # 800044a8 <namei>
    80005fde:	84aa                	mv	s1,a0
    80005fe0:	c131                	beqz	a0,80006024 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fe2:	ffffe097          	auipc	ra,0xffffe
    80005fe6:	d08080e7          	jalr	-760(ra) # 80003cea <ilock>
  if(ip->type != T_DIR){
    80005fea:	04c49703          	lh	a4,76(s1)
    80005fee:	4785                	li	a5,1
    80005ff0:	04f71063          	bne	a4,a5,80006030 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ff4:	8526                	mv	a0,s1
    80005ff6:	ffffe097          	auipc	ra,0xffffe
    80005ffa:	db8080e7          	jalr	-584(ra) # 80003dae <iunlock>
  iput(p->cwd);
    80005ffe:	15893503          	ld	a0,344(s2)
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	ea4080e7          	jalr	-348(ra) # 80003ea6 <iput>
  end_op();
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	73c080e7          	jalr	1852(ra) # 80004746 <end_op>
  p->cwd = ip;
    80006012:	14993c23          	sd	s1,344(s2)
  return 0;
    80006016:	4501                	li	a0,0
}
    80006018:	60ea                	ld	ra,152(sp)
    8000601a:	644a                	ld	s0,144(sp)
    8000601c:	64aa                	ld	s1,136(sp)
    8000601e:	690a                	ld	s2,128(sp)
    80006020:	610d                	addi	sp,sp,160
    80006022:	8082                	ret
    end_op();
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	722080e7          	jalr	1826(ra) # 80004746 <end_op>
    return -1;
    8000602c:	557d                	li	a0,-1
    8000602e:	b7ed                	j	80006018 <sys_chdir+0x7a>
    iunlockput(ip);
    80006030:	8526                	mv	a0,s1
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	f1c080e7          	jalr	-228(ra) # 80003f4e <iunlockput>
    end_op();
    8000603a:	ffffe097          	auipc	ra,0xffffe
    8000603e:	70c080e7          	jalr	1804(ra) # 80004746 <end_op>
    return -1;
    80006042:	557d                	li	a0,-1
    80006044:	bfd1                	j	80006018 <sys_chdir+0x7a>

0000000080006046 <sys_exec>:

uint64
sys_exec(void)
{
    80006046:	7145                	addi	sp,sp,-464
    80006048:	e786                	sd	ra,456(sp)
    8000604a:	e3a2                	sd	s0,448(sp)
    8000604c:	ff26                	sd	s1,440(sp)
    8000604e:	fb4a                	sd	s2,432(sp)
    80006050:	f74e                	sd	s3,424(sp)
    80006052:	f352                	sd	s4,416(sp)
    80006054:	ef56                	sd	s5,408(sp)
    80006056:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006058:	08000613          	li	a2,128
    8000605c:	f4040593          	addi	a1,s0,-192
    80006060:	4501                	li	a0,0
    80006062:	ffffd097          	auipc	ra,0xffffd
    80006066:	fe8080e7          	jalr	-24(ra) # 8000304a <argstr>
    return -1;
    8000606a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000606c:	0e054c63          	bltz	a0,80006164 <sys_exec+0x11e>
    80006070:	e3840593          	addi	a1,s0,-456
    80006074:	4505                	li	a0,1
    80006076:	ffffd097          	auipc	ra,0xffffd
    8000607a:	fb2080e7          	jalr	-78(ra) # 80003028 <argaddr>
    8000607e:	0e054363          	bltz	a0,80006164 <sys_exec+0x11e>
  }
  memset(argv, 0, sizeof(argv));
    80006082:	e4040913          	addi	s2,s0,-448
    80006086:	10000613          	li	a2,256
    8000608a:	4581                	li	a1,0
    8000608c:	854a                	mv	a0,s2
    8000608e:	ffffb097          	auipc	ra,0xffffb
    80006092:	204080e7          	jalr	516(ra) # 80001292 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006096:	89ca                	mv	s3,s2
  memset(argv, 0, sizeof(argv));
    80006098:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    8000609a:	02000a93          	li	s5,32
    8000609e:	00048a1b          	sext.w	s4,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060a2:	00349513          	slli	a0,s1,0x3
    800060a6:	e3040593          	addi	a1,s0,-464
    800060aa:	e3843783          	ld	a5,-456(s0)
    800060ae:	953e                	add	a0,a0,a5
    800060b0:	ffffd097          	auipc	ra,0xffffd
    800060b4:	eba080e7          	jalr	-326(ra) # 80002f6a <fetchaddr>
    800060b8:	02054a63          	bltz	a0,800060ec <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800060bc:	e3043783          	ld	a5,-464(s0)
    800060c0:	cfa9                	beqz	a5,8000611a <sys_exec+0xd4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	c98080e7          	jalr	-872(ra) # 80000d5a <kalloc>
    800060ca:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    800060ce:	cd19                	beqz	a0,800060ec <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060d0:	6605                	lui	a2,0x1
    800060d2:	85aa                	mv	a1,a0
    800060d4:	e3043503          	ld	a0,-464(s0)
    800060d8:	ffffd097          	auipc	ra,0xffffd
    800060dc:	ee6080e7          	jalr	-282(ra) # 80002fbe <fetchstr>
    800060e0:	00054663          	bltz	a0,800060ec <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800060e4:	0485                	addi	s1,s1,1
    800060e6:	0921                	addi	s2,s2,8
    800060e8:	fb549be3          	bne	s1,s5,8000609e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060ec:	e4043503          	ld	a0,-448(s0)
    kfree(argv[i]);
  return -1;
    800060f0:	597d                	li	s2,-1
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060f2:	c92d                	beqz	a0,80006164 <sys_exec+0x11e>
    kfree(argv[i]);
    800060f4:	ffffb097          	auipc	ra,0xffffb
    800060f8:	b8e080e7          	jalr	-1138(ra) # 80000c82 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060fc:	e4840493          	addi	s1,s0,-440
    80006100:	10098993          	addi	s3,s3,256
    80006104:	6088                	ld	a0,0(s1)
    80006106:	cd31                	beqz	a0,80006162 <sys_exec+0x11c>
    kfree(argv[i]);
    80006108:	ffffb097          	auipc	ra,0xffffb
    8000610c:	b7a080e7          	jalr	-1158(ra) # 80000c82 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006110:	04a1                	addi	s1,s1,8
    80006112:	ff3499e3          	bne	s1,s3,80006104 <sys_exec+0xbe>
  return -1;
    80006116:	597d                	li	s2,-1
    80006118:	a0b1                	j	80006164 <sys_exec+0x11e>
      argv[i] = 0;
    8000611a:	0a0e                	slli	s4,s4,0x3
    8000611c:	fc040793          	addi	a5,s0,-64
    80006120:	9a3e                	add	s4,s4,a5
    80006122:	e80a3023          	sd	zero,-384(s4)
  int ret = exec(path, argv);
    80006126:	e4040593          	addi	a1,s0,-448
    8000612a:	f4040513          	addi	a0,s0,-192
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	166080e7          	jalr	358(ra) # 80005294 <exec>
    80006136:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006138:	e4043503          	ld	a0,-448(s0)
    8000613c:	c505                	beqz	a0,80006164 <sys_exec+0x11e>
    kfree(argv[i]);
    8000613e:	ffffb097          	auipc	ra,0xffffb
    80006142:	b44080e7          	jalr	-1212(ra) # 80000c82 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006146:	e4840493          	addi	s1,s0,-440
    8000614a:	10098993          	addi	s3,s3,256
    8000614e:	6088                	ld	a0,0(s1)
    80006150:	c911                	beqz	a0,80006164 <sys_exec+0x11e>
    kfree(argv[i]);
    80006152:	ffffb097          	auipc	ra,0xffffb
    80006156:	b30080e7          	jalr	-1232(ra) # 80000c82 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000615a:	04a1                	addi	s1,s1,8
    8000615c:	ff3499e3          	bne	s1,s3,8000614e <sys_exec+0x108>
    80006160:	a011                	j	80006164 <sys_exec+0x11e>
  return -1;
    80006162:	597d                	li	s2,-1
}
    80006164:	854a                	mv	a0,s2
    80006166:	60be                	ld	ra,456(sp)
    80006168:	641e                	ld	s0,448(sp)
    8000616a:	74fa                	ld	s1,440(sp)
    8000616c:	795a                	ld	s2,432(sp)
    8000616e:	79ba                	ld	s3,424(sp)
    80006170:	7a1a                	ld	s4,416(sp)
    80006172:	6afa                	ld	s5,408(sp)
    80006174:	6179                	addi	sp,sp,464
    80006176:	8082                	ret

0000000080006178 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006178:	7139                	addi	sp,sp,-64
    8000617a:	fc06                	sd	ra,56(sp)
    8000617c:	f822                	sd	s0,48(sp)
    8000617e:	f426                	sd	s1,40(sp)
    80006180:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006182:	ffffc097          	auipc	ra,0xffffc
    80006186:	db4080e7          	jalr	-588(ra) # 80001f36 <myproc>
    8000618a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000618c:	fd840593          	addi	a1,s0,-40
    80006190:	4501                	li	a0,0
    80006192:	ffffd097          	auipc	ra,0xffffd
    80006196:	e96080e7          	jalr	-362(ra) # 80003028 <argaddr>
    return -1;
    8000619a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000619c:	0c054f63          	bltz	a0,8000627a <sys_pipe+0x102>
  if(pipealloc(&rf, &wf) < 0)
    800061a0:	fc840593          	addi	a1,s0,-56
    800061a4:	fd040513          	addi	a0,s0,-48
    800061a8:	fffff097          	auipc	ra,0xfffff
    800061ac:	d6a080e7          	jalr	-662(ra) # 80004f12 <pipealloc>
    return -1;
    800061b0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061b2:	0c054463          	bltz	a0,8000627a <sys_pipe+0x102>
  fd0 = -1;
    800061b6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061ba:	fd043503          	ld	a0,-48(s0)
    800061be:	fffff097          	auipc	ra,0xfffff
    800061c2:	4e2080e7          	jalr	1250(ra) # 800056a0 <fdalloc>
    800061c6:	fca42223          	sw	a0,-60(s0)
    800061ca:	08054b63          	bltz	a0,80006260 <sys_pipe+0xe8>
    800061ce:	fc843503          	ld	a0,-56(s0)
    800061d2:	fffff097          	auipc	ra,0xfffff
    800061d6:	4ce080e7          	jalr	1230(ra) # 800056a0 <fdalloc>
    800061da:	fca42023          	sw	a0,-64(s0)
    800061de:	06054863          	bltz	a0,8000624e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061e2:	4691                	li	a3,4
    800061e4:	fc440613          	addi	a2,s0,-60
    800061e8:	fd843583          	ld	a1,-40(s0)
    800061ec:	6ca8                	ld	a0,88(s1)
    800061ee:	ffffc097          	auipc	ra,0xffffc
    800061f2:	a24080e7          	jalr	-1500(ra) # 80001c12 <copyout>
    800061f6:	02054063          	bltz	a0,80006216 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061fa:	4691                	li	a3,4
    800061fc:	fc040613          	addi	a2,s0,-64
    80006200:	fd843583          	ld	a1,-40(s0)
    80006204:	0591                	addi	a1,a1,4
    80006206:	6ca8                	ld	a0,88(s1)
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	a0a080e7          	jalr	-1526(ra) # 80001c12 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006210:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006212:	06055463          	bgez	a0,8000627a <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    80006216:	fc442783          	lw	a5,-60(s0)
    8000621a:	07e9                	addi	a5,a5,26
    8000621c:	078e                	slli	a5,a5,0x3
    8000621e:	97a6                	add	a5,a5,s1
    80006220:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006224:	fc042783          	lw	a5,-64(s0)
    80006228:	07e9                	addi	a5,a5,26
    8000622a:	078e                	slli	a5,a5,0x3
    8000622c:	94be                	add	s1,s1,a5
    8000622e:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80006232:	fd043503          	ld	a0,-48(s0)
    80006236:	fffff097          	auipc	ra,0xfffff
    8000623a:	994080e7          	jalr	-1644(ra) # 80004bca <fileclose>
    fileclose(wf);
    8000623e:	fc843503          	ld	a0,-56(s0)
    80006242:	fffff097          	auipc	ra,0xfffff
    80006246:	988080e7          	jalr	-1656(ra) # 80004bca <fileclose>
    return -1;
    8000624a:	57fd                	li	a5,-1
    8000624c:	a03d                	j	8000627a <sys_pipe+0x102>
    if(fd0 >= 0)
    8000624e:	fc442783          	lw	a5,-60(s0)
    80006252:	0007c763          	bltz	a5,80006260 <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    80006256:	07e9                	addi	a5,a5,26
    80006258:	078e                	slli	a5,a5,0x3
    8000625a:	94be                	add	s1,s1,a5
    8000625c:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80006260:	fd043503          	ld	a0,-48(s0)
    80006264:	fffff097          	auipc	ra,0xfffff
    80006268:	966080e7          	jalr	-1690(ra) # 80004bca <fileclose>
    fileclose(wf);
    8000626c:	fc843503          	ld	a0,-56(s0)
    80006270:	fffff097          	auipc	ra,0xfffff
    80006274:	95a080e7          	jalr	-1702(ra) # 80004bca <fileclose>
    return -1;
    80006278:	57fd                	li	a5,-1
}
    8000627a:	853e                	mv	a0,a5
    8000627c:	70e2                	ld	ra,56(sp)
    8000627e:	7442                	ld	s0,48(sp)
    80006280:	74a2                	ld	s1,40(sp)
    80006282:	6121                	addi	sp,sp,64
    80006284:	8082                	ret
	...

0000000080006290 <kernelvec>:
    80006290:	7111                	addi	sp,sp,-256
    80006292:	e006                	sd	ra,0(sp)
    80006294:	e40a                	sd	sp,8(sp)
    80006296:	e80e                	sd	gp,16(sp)
    80006298:	ec12                	sd	tp,24(sp)
    8000629a:	f016                	sd	t0,32(sp)
    8000629c:	f41a                	sd	t1,40(sp)
    8000629e:	f81e                	sd	t2,48(sp)
    800062a0:	fc22                	sd	s0,56(sp)
    800062a2:	e0a6                	sd	s1,64(sp)
    800062a4:	e4aa                	sd	a0,72(sp)
    800062a6:	e8ae                	sd	a1,80(sp)
    800062a8:	ecb2                	sd	a2,88(sp)
    800062aa:	f0b6                	sd	a3,96(sp)
    800062ac:	f4ba                	sd	a4,104(sp)
    800062ae:	f8be                	sd	a5,112(sp)
    800062b0:	fcc2                	sd	a6,120(sp)
    800062b2:	e146                	sd	a7,128(sp)
    800062b4:	e54a                	sd	s2,136(sp)
    800062b6:	e94e                	sd	s3,144(sp)
    800062b8:	ed52                	sd	s4,152(sp)
    800062ba:	f156                	sd	s5,160(sp)
    800062bc:	f55a                	sd	s6,168(sp)
    800062be:	f95e                	sd	s7,176(sp)
    800062c0:	fd62                	sd	s8,184(sp)
    800062c2:	e1e6                	sd	s9,192(sp)
    800062c4:	e5ea                	sd	s10,200(sp)
    800062c6:	e9ee                	sd	s11,208(sp)
    800062c8:	edf2                	sd	t3,216(sp)
    800062ca:	f1f6                	sd	t4,224(sp)
    800062cc:	f5fa                	sd	t5,232(sp)
    800062ce:	f9fe                	sd	t6,240(sp)
    800062d0:	b63fc0ef          	jal	ra,80002e32 <kerneltrap>
    800062d4:	6082                	ld	ra,0(sp)
    800062d6:	6122                	ld	sp,8(sp)
    800062d8:	61c2                	ld	gp,16(sp)
    800062da:	7282                	ld	t0,32(sp)
    800062dc:	7322                	ld	t1,40(sp)
    800062de:	73c2                	ld	t2,48(sp)
    800062e0:	7462                	ld	s0,56(sp)
    800062e2:	6486                	ld	s1,64(sp)
    800062e4:	6526                	ld	a0,72(sp)
    800062e6:	65c6                	ld	a1,80(sp)
    800062e8:	6666                	ld	a2,88(sp)
    800062ea:	7686                	ld	a3,96(sp)
    800062ec:	7726                	ld	a4,104(sp)
    800062ee:	77c6                	ld	a5,112(sp)
    800062f0:	7866                	ld	a6,120(sp)
    800062f2:	688a                	ld	a7,128(sp)
    800062f4:	692a                	ld	s2,136(sp)
    800062f6:	69ca                	ld	s3,144(sp)
    800062f8:	6a6a                	ld	s4,152(sp)
    800062fa:	7a8a                	ld	s5,160(sp)
    800062fc:	7b2a                	ld	s6,168(sp)
    800062fe:	7bca                	ld	s7,176(sp)
    80006300:	7c6a                	ld	s8,184(sp)
    80006302:	6c8e                	ld	s9,192(sp)
    80006304:	6d2e                	ld	s10,200(sp)
    80006306:	6dce                	ld	s11,208(sp)
    80006308:	6e6e                	ld	t3,216(sp)
    8000630a:	7e8e                	ld	t4,224(sp)
    8000630c:	7f2e                	ld	t5,232(sp)
    8000630e:	7fce                	ld	t6,240(sp)
    80006310:	6111                	addi	sp,sp,256
    80006312:	10200073          	sret
    80006316:	00000013          	nop
    8000631a:	00000013          	nop
    8000631e:	0001                	nop

0000000080006320 <timervec>:
    80006320:	34051573          	csrrw	a0,mscratch,a0
    80006324:	e10c                	sd	a1,0(a0)
    80006326:	e510                	sd	a2,8(a0)
    80006328:	e914                	sd	a3,16(a0)
    8000632a:	6d0c                	ld	a1,24(a0)
    8000632c:	7110                	ld	a2,32(a0)
    8000632e:	6194                	ld	a3,0(a1)
    80006330:	96b2                	add	a3,a3,a2
    80006332:	e194                	sd	a3,0(a1)
    80006334:	4589                	li	a1,2
    80006336:	14459073          	csrw	sip,a1
    8000633a:	6914                	ld	a3,16(a0)
    8000633c:	6510                	ld	a2,8(a0)
    8000633e:	610c                	ld	a1,0(a0)
    80006340:	34051573          	csrrw	a0,mscratch,a0
    80006344:	30200073          	mret
	...

000000008000634a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000634a:	1141                	addi	sp,sp,-16
    8000634c:	e422                	sd	s0,8(sp)
    8000634e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006350:	0c0007b7          	lui	a5,0xc000
    80006354:	4705                	li	a4,1
    80006356:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006358:	c3d8                	sw	a4,4(a5)
}
    8000635a:	6422                	ld	s0,8(sp)
    8000635c:	0141                	addi	sp,sp,16
    8000635e:	8082                	ret

0000000080006360 <plicinithart>:

void
plicinithart(void)
{
    80006360:	1141                	addi	sp,sp,-16
    80006362:	e406                	sd	ra,8(sp)
    80006364:	e022                	sd	s0,0(sp)
    80006366:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006368:	ffffc097          	auipc	ra,0xffffc
    8000636c:	ba2080e7          	jalr	-1118(ra) # 80001f0a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006370:	0085171b          	slliw	a4,a0,0x8
    80006374:	0c0027b7          	lui	a5,0xc002
    80006378:	97ba                	add	a5,a5,a4
    8000637a:	40200713          	li	a4,1026
    8000637e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006382:	00d5151b          	slliw	a0,a0,0xd
    80006386:	0c2017b7          	lui	a5,0xc201
    8000638a:	953e                	add	a0,a0,a5
    8000638c:	00052023          	sw	zero,0(a0)
}
    80006390:	60a2                	ld	ra,8(sp)
    80006392:	6402                	ld	s0,0(sp)
    80006394:	0141                	addi	sp,sp,16
    80006396:	8082                	ret

0000000080006398 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006398:	1141                	addi	sp,sp,-16
    8000639a:	e406                	sd	ra,8(sp)
    8000639c:	e022                	sd	s0,0(sp)
    8000639e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063a0:	ffffc097          	auipc	ra,0xffffc
    800063a4:	b6a080e7          	jalr	-1174(ra) # 80001f0a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063a8:	00d5151b          	slliw	a0,a0,0xd
    800063ac:	0c2017b7          	lui	a5,0xc201
    800063b0:	97aa                	add	a5,a5,a0
  return irq;
}
    800063b2:	43c8                	lw	a0,4(a5)
    800063b4:	60a2                	ld	ra,8(sp)
    800063b6:	6402                	ld	s0,0(sp)
    800063b8:	0141                	addi	sp,sp,16
    800063ba:	8082                	ret

00000000800063bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063bc:	1101                	addi	sp,sp,-32
    800063be:	ec06                	sd	ra,24(sp)
    800063c0:	e822                	sd	s0,16(sp)
    800063c2:	e426                	sd	s1,8(sp)
    800063c4:	1000                	addi	s0,sp,32
    800063c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063c8:	ffffc097          	auipc	ra,0xffffc
    800063cc:	b42080e7          	jalr	-1214(ra) # 80001f0a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063d0:	00d5151b          	slliw	a0,a0,0xd
    800063d4:	0c2017b7          	lui	a5,0xc201
    800063d8:	97aa                	add	a5,a5,a0
    800063da:	c3c4                	sw	s1,4(a5)
}
    800063dc:	60e2                	ld	ra,24(sp)
    800063de:	6442                	ld	s0,16(sp)
    800063e0:	64a2                	ld	s1,8(sp)
    800063e2:	6105                	addi	sp,sp,32
    800063e4:	8082                	ret

00000000800063e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063e6:	1141                	addi	sp,sp,-16
    800063e8:	e406                	sd	ra,8(sp)
    800063ea:	e022                	sd	s0,0(sp)
    800063ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063ee:	479d                	li	a5,7
    800063f0:	06a7c963          	blt	a5,a0,80006462 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800063f4:	00052797          	auipc	a5,0x52
    800063f8:	c0c78793          	addi	a5,a5,-1012 # 80058000 <disk>
    800063fc:	00a78733          	add	a4,a5,a0
    80006400:	6789                	lui	a5,0x2
    80006402:	97ba                	add	a5,a5,a4
    80006404:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006408:	e7ad                	bnez	a5,80006472 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000640a:	00451793          	slli	a5,a0,0x4
    8000640e:	00054717          	auipc	a4,0x54
    80006412:	bf270713          	addi	a4,a4,-1038 # 8005a000 <disk+0x2000>
    80006416:	6314                	ld	a3,0(a4)
    80006418:	96be                	add	a3,a3,a5
    8000641a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000641e:	6314                	ld	a3,0(a4)
    80006420:	96be                	add	a3,a3,a5
    80006422:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006426:	6314                	ld	a3,0(a4)
    80006428:	96be                	add	a3,a3,a5
    8000642a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000642e:	6318                	ld	a4,0(a4)
    80006430:	97ba                	add	a5,a5,a4
    80006432:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006436:	00052797          	auipc	a5,0x52
    8000643a:	bca78793          	addi	a5,a5,-1078 # 80058000 <disk>
    8000643e:	97aa                	add	a5,a5,a0
    80006440:	6509                	lui	a0,0x2
    80006442:	953e                	add	a0,a0,a5
    80006444:	4785                	li	a5,1
    80006446:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000644a:	00054517          	auipc	a0,0x54
    8000644e:	bce50513          	addi	a0,a0,-1074 # 8005a018 <disk+0x2018>
    80006452:	ffffc097          	auipc	ra,0xffffc
    80006456:	484080e7          	jalr	1156(ra) # 800028d6 <wakeup>
}
    8000645a:	60a2                	ld	ra,8(sp)
    8000645c:	6402                	ld	s0,0(sp)
    8000645e:	0141                	addi	sp,sp,16
    80006460:	8082                	ret
    panic("free_desc 1");
    80006462:	00002517          	auipc	a0,0x2
    80006466:	39650513          	addi	a0,a0,918 # 800087f8 <syscalls+0x360>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	10e080e7          	jalr	270(ra) # 80000578 <panic>
    panic("free_desc 2");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	39650513          	addi	a0,a0,918 # 80008808 <syscalls+0x370>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0fe080e7          	jalr	254(ra) # 80000578 <panic>

0000000080006482 <virtio_disk_init>:
{
    80006482:	1101                	addi	sp,sp,-32
    80006484:	ec06                	sd	ra,24(sp)
    80006486:	e822                	sd	s0,16(sp)
    80006488:	e426                	sd	s1,8(sp)
    8000648a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000648c:	00002597          	auipc	a1,0x2
    80006490:	38c58593          	addi	a1,a1,908 # 80008818 <syscalls+0x380>
    80006494:	00054517          	auipc	a0,0x54
    80006498:	c9450513          	addi	a0,a0,-876 # 8005a128 <disk+0x2128>
    8000649c:	ffffb097          	auipc	ra,0xffffb
    800064a0:	b76080e7          	jalr	-1162(ra) # 80001012 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064a4:	100017b7          	lui	a5,0x10001
    800064a8:	4398                	lw	a4,0(a5)
    800064aa:	2701                	sext.w	a4,a4
    800064ac:	747277b7          	lui	a5,0x74727
    800064b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064b4:	0ef71163          	bne	a4,a5,80006596 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064b8:	100017b7          	lui	a5,0x10001
    800064bc:	43dc                	lw	a5,4(a5)
    800064be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064c0:	4705                	li	a4,1
    800064c2:	0ce79a63          	bne	a5,a4,80006596 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064c6:	100017b7          	lui	a5,0x10001
    800064ca:	479c                	lw	a5,8(a5)
    800064cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064ce:	4709                	li	a4,2
    800064d0:	0ce79363          	bne	a5,a4,80006596 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064d4:	100017b7          	lui	a5,0x10001
    800064d8:	47d8                	lw	a4,12(a5)
    800064da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064dc:	554d47b7          	lui	a5,0x554d4
    800064e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064e4:	0af71963          	bne	a4,a5,80006596 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e8:	100017b7          	lui	a5,0x10001
    800064ec:	4705                	li	a4,1
    800064ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f0:	470d                	li	a4,3
    800064f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064f6:	c7ffe737          	lui	a4,0xc7ffe
    800064fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fa2737>
    800064fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006500:	2701                	sext.w	a4,a4
    80006502:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006504:	472d                	li	a4,11
    80006506:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006508:	473d                	li	a4,15
    8000650a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000650c:	6705                	lui	a4,0x1
    8000650e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006510:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006514:	5bdc                	lw	a5,52(a5)
    80006516:	2781                	sext.w	a5,a5
  if(max == 0)
    80006518:	c7d9                	beqz	a5,800065a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000651a:	471d                	li	a4,7
    8000651c:	08f77d63          	bleu	a5,a4,800065b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006520:	100014b7          	lui	s1,0x10001
    80006524:	47a1                	li	a5,8
    80006526:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006528:	6609                	lui	a2,0x2
    8000652a:	4581                	li	a1,0
    8000652c:	00052517          	auipc	a0,0x52
    80006530:	ad450513          	addi	a0,a0,-1324 # 80058000 <disk>
    80006534:	ffffb097          	auipc	ra,0xffffb
    80006538:	d5e080e7          	jalr	-674(ra) # 80001292 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000653c:	00052717          	auipc	a4,0x52
    80006540:	ac470713          	addi	a4,a4,-1340 # 80058000 <disk>
    80006544:	00c75793          	srli	a5,a4,0xc
    80006548:	2781                	sext.w	a5,a5
    8000654a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000654c:	00054797          	auipc	a5,0x54
    80006550:	ab478793          	addi	a5,a5,-1356 # 8005a000 <disk+0x2000>
    80006554:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006556:	00052717          	auipc	a4,0x52
    8000655a:	b2a70713          	addi	a4,a4,-1238 # 80058080 <disk+0x80>
    8000655e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006560:	00053717          	auipc	a4,0x53
    80006564:	aa070713          	addi	a4,a4,-1376 # 80059000 <disk+0x1000>
    80006568:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000656a:	4705                	li	a4,1
    8000656c:	00e78c23          	sb	a4,24(a5)
    80006570:	00e78ca3          	sb	a4,25(a5)
    80006574:	00e78d23          	sb	a4,26(a5)
    80006578:	00e78da3          	sb	a4,27(a5)
    8000657c:	00e78e23          	sb	a4,28(a5)
    80006580:	00e78ea3          	sb	a4,29(a5)
    80006584:	00e78f23          	sb	a4,30(a5)
    80006588:	00e78fa3          	sb	a4,31(a5)
}
    8000658c:	60e2                	ld	ra,24(sp)
    8000658e:	6442                	ld	s0,16(sp)
    80006590:	64a2                	ld	s1,8(sp)
    80006592:	6105                	addi	sp,sp,32
    80006594:	8082                	ret
    panic("could not find virtio disk");
    80006596:	00002517          	auipc	a0,0x2
    8000659a:	29250513          	addi	a0,a0,658 # 80008828 <syscalls+0x390>
    8000659e:	ffffa097          	auipc	ra,0xffffa
    800065a2:	fda080e7          	jalr	-38(ra) # 80000578 <panic>
    panic("virtio disk has no queue 0");
    800065a6:	00002517          	auipc	a0,0x2
    800065aa:	2a250513          	addi	a0,a0,674 # 80008848 <syscalls+0x3b0>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	fca080e7          	jalr	-54(ra) # 80000578 <panic>
    panic("virtio disk max queue too short");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	2b250513          	addi	a0,a0,690 # 80008868 <syscalls+0x3d0>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	fba080e7          	jalr	-70(ra) # 80000578 <panic>

00000000800065c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065c6:	711d                	addi	sp,sp,-96
    800065c8:	ec86                	sd	ra,88(sp)
    800065ca:	e8a2                	sd	s0,80(sp)
    800065cc:	e4a6                	sd	s1,72(sp)
    800065ce:	e0ca                	sd	s2,64(sp)
    800065d0:	fc4e                	sd	s3,56(sp)
    800065d2:	f852                	sd	s4,48(sp)
    800065d4:	f456                	sd	s5,40(sp)
    800065d6:	f05a                	sd	s6,32(sp)
    800065d8:	ec5e                	sd	s7,24(sp)
    800065da:	e862                	sd	s8,16(sp)
    800065dc:	1080                	addi	s0,sp,96
    800065de:	892a                	mv	s2,a0
    800065e0:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065e2:	00c52b83          	lw	s7,12(a0)
    800065e6:	001b9b9b          	slliw	s7,s7,0x1
    800065ea:	1b82                	slli	s7,s7,0x20
    800065ec:	020bdb93          	srli	s7,s7,0x20

  acquire(&disk.vdisk_lock);
    800065f0:	00054517          	auipc	a0,0x54
    800065f4:	b3850513          	addi	a0,a0,-1224 # 8005a128 <disk+0x2128>
    800065f8:	ffffb097          	auipc	ra,0xffffb
    800065fc:	88e080e7          	jalr	-1906(ra) # 80000e86 <acquire>
    if(disk.free[i]){
    80006600:	00054997          	auipc	s3,0x54
    80006604:	a0098993          	addi	s3,s3,-1536 # 8005a000 <disk+0x2000>
  for(int i = 0; i < NUM; i++){
    80006608:	4b21                	li	s6,8
      disk.free[i] = 0;
    8000660a:	00052a97          	auipc	s5,0x52
    8000660e:	9f6a8a93          	addi	s5,s5,-1546 # 80058000 <disk>
  for(int i = 0; i < 3; i++){
    80006612:	4a0d                	li	s4,3
    80006614:	a079                	j	800066a2 <virtio_disk_rw+0xdc>
      disk.free[i] = 0;
    80006616:	00fa86b3          	add	a3,s5,a5
    8000661a:	96ae                	add	a3,a3,a1
    8000661c:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006620:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006622:	0207ca63          	bltz	a5,80006656 <virtio_disk_rw+0x90>
  for(int i = 0; i < 3; i++){
    80006626:	2485                	addiw	s1,s1,1
    80006628:	0711                	addi	a4,a4,4
    8000662a:	25448b63          	beq	s1,s4,80006880 <virtio_disk_rw+0x2ba>
    idx[i] = alloc_desc();
    8000662e:	863a                	mv	a2,a4
    if(disk.free[i]){
    80006630:	0189c783          	lbu	a5,24(s3)
    80006634:	26079e63          	bnez	a5,800068b0 <virtio_disk_rw+0x2ea>
    80006638:	00054697          	auipc	a3,0x54
    8000663c:	9e168693          	addi	a3,a3,-1567 # 8005a019 <disk+0x2019>
  for(int i = 0; i < NUM; i++){
    80006640:	87aa                	mv	a5,a0
    if(disk.free[i]){
    80006642:	0006c803          	lbu	a6,0(a3)
    80006646:	fc0818e3          	bnez	a6,80006616 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    8000664a:	2785                	addiw	a5,a5,1
    8000664c:	0685                	addi	a3,a3,1
    8000664e:	ff679ae3          	bne	a5,s6,80006642 <virtio_disk_rw+0x7c>
    idx[i] = alloc_desc();
    80006652:	57fd                	li	a5,-1
    80006654:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006656:	02905a63          	blez	s1,8000668a <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    8000665a:	fa042503          	lw	a0,-96(s0)
    8000665e:	00000097          	auipc	ra,0x0
    80006662:	d88080e7          	jalr	-632(ra) # 800063e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006666:	4785                	li	a5,1
    80006668:	0297d163          	ble	s1,a5,8000668a <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    8000666c:	fa442503          	lw	a0,-92(s0)
    80006670:	00000097          	auipc	ra,0x0
    80006674:	d76080e7          	jalr	-650(ra) # 800063e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006678:	4789                	li	a5,2
    8000667a:	0097d863          	ble	s1,a5,8000668a <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    8000667e:	fa842503          	lw	a0,-88(s0)
    80006682:	00000097          	auipc	ra,0x0
    80006686:	d64080e7          	jalr	-668(ra) # 800063e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000668a:	00054597          	auipc	a1,0x54
    8000668e:	a9e58593          	addi	a1,a1,-1378 # 8005a128 <disk+0x2128>
    80006692:	00054517          	auipc	a0,0x54
    80006696:	98650513          	addi	a0,a0,-1658 # 8005a018 <disk+0x2018>
    8000669a:	ffffc097          	auipc	ra,0xffffc
    8000669e:	0b6080e7          	jalr	182(ra) # 80002750 <sleep>
  for(int i = 0; i < 3; i++){
    800066a2:	fa040713          	addi	a4,s0,-96
    800066a6:	4481                	li	s1,0
  for(int i = 0; i < NUM; i++){
    800066a8:	4505                	li	a0,1
      disk.free[i] = 0;
    800066aa:	6589                	lui	a1,0x2
    800066ac:	b749                	j	8000662e <virtio_disk_rw+0x68>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066ae:	20058793          	addi	a5,a1,512 # 2200 <_entry-0x7fffde00>
    800066b2:	00479613          	slli	a2,a5,0x4
    800066b6:	00052797          	auipc	a5,0x52
    800066ba:	94a78793          	addi	a5,a5,-1718 # 80058000 <disk>
    800066be:	97b2                	add	a5,a5,a2
    800066c0:	4605                	li	a2,1
    800066c2:	0ac7a423          	sw	a2,168(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066c6:	20058793          	addi	a5,a1,512
    800066ca:	00479613          	slli	a2,a5,0x4
    800066ce:	00052797          	auipc	a5,0x52
    800066d2:	93278793          	addi	a5,a5,-1742 # 80058000 <disk>
    800066d6:	97b2                	add	a5,a5,a2
    800066d8:	0a07a623          	sw	zero,172(a5)
  buf0->sector = sector;
    800066dc:	0b77b823          	sd	s7,176(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e0:	00054797          	auipc	a5,0x54
    800066e4:	92078793          	addi	a5,a5,-1760 # 8005a000 <disk+0x2000>
    800066e8:	6390                	ld	a2,0(a5)
    800066ea:	963a                	add	a2,a2,a4
    800066ec:	7779                	lui	a4,0xffffe
    800066ee:	9732                	add	a4,a4,a2
    800066f0:	e314                	sd	a3,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066f2:	00459713          	slli	a4,a1,0x4
    800066f6:	6394                	ld	a3,0(a5)
    800066f8:	96ba                	add	a3,a3,a4
    800066fa:	4641                	li	a2,16
    800066fc:	c690                	sw	a2,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066fe:	6394                	ld	a3,0(a5)
    80006700:	96ba                	add	a3,a3,a4
    80006702:	4605                	li	a2,1
    80006704:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006708:	fa442683          	lw	a3,-92(s0)
    8000670c:	6390                	ld	a2,0(a5)
    8000670e:	963a                	add	a2,a2,a4
    80006710:	00d61723          	sh	a3,14(a2) # 200e <_entry-0x7fffdff2>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006714:	0692                	slli	a3,a3,0x4
    80006716:	6390                	ld	a2,0(a5)
    80006718:	9636                	add	a2,a2,a3
    8000671a:	06090513          	addi	a0,s2,96
    8000671e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006720:	639c                	ld	a5,0(a5)
    80006722:	97b6                	add	a5,a5,a3
    80006724:	40000613          	li	a2,1024
    80006728:	c790                	sw	a2,8(a5)
  if(write)
    8000672a:	140c0163          	beqz	s8,8000686c <virtio_disk_rw+0x2a6>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000672e:	00054797          	auipc	a5,0x54
    80006732:	8d278793          	addi	a5,a5,-1838 # 8005a000 <disk+0x2000>
    80006736:	639c                	ld	a5,0(a5)
    80006738:	97b6                	add	a5,a5,a3
    8000673a:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000673e:	00052897          	auipc	a7,0x52
    80006742:	8c288893          	addi	a7,a7,-1854 # 80058000 <disk>
    80006746:	00054797          	auipc	a5,0x54
    8000674a:	8ba78793          	addi	a5,a5,-1862 # 8005a000 <disk+0x2000>
    8000674e:	6390                	ld	a2,0(a5)
    80006750:	9636                	add	a2,a2,a3
    80006752:	00c65503          	lhu	a0,12(a2)
    80006756:	00156513          	ori	a0,a0,1
    8000675a:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    8000675e:	fa842603          	lw	a2,-88(s0)
    80006762:	6388                	ld	a0,0(a5)
    80006764:	96aa                	add	a3,a3,a0
    80006766:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000676a:	20058513          	addi	a0,a1,512
    8000676e:	0512                	slli	a0,a0,0x4
    80006770:	9546                	add	a0,a0,a7
    80006772:	56fd                	li	a3,-1
    80006774:	02d50823          	sb	a3,48(a0)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006778:	00461693          	slli	a3,a2,0x4
    8000677c:	6390                	ld	a2,0(a5)
    8000677e:	9636                	add	a2,a2,a3
    80006780:	6809                	lui	a6,0x2
    80006782:	03080813          	addi	a6,a6,48 # 2030 <_entry-0x7fffdfd0>
    80006786:	9742                	add	a4,a4,a6
    80006788:	9746                	add	a4,a4,a7
    8000678a:	e218                	sd	a4,0(a2)
  disk.desc[idx[2]].len = 1;
    8000678c:	6398                	ld	a4,0(a5)
    8000678e:	9736                	add	a4,a4,a3
    80006790:	4605                	li	a2,1
    80006792:	c710                	sw	a2,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006794:	6398                	ld	a4,0(a5)
    80006796:	9736                	add	a4,a4,a3
    80006798:	4809                	li	a6,2
    8000679a:	01071623          	sh	a6,12(a4) # ffffffffffffe00c <end+0xffffffff7ffa1fe4>
  disk.desc[idx[2]].next = 0;
    8000679e:	6398                	ld	a4,0(a5)
    800067a0:	96ba                	add	a3,a3,a4
    800067a2:	00069723          	sh	zero,14(a3)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067a6:	00c92223          	sw	a2,4(s2)
  disk.info[idx[0]].b = b;
    800067aa:	03253423          	sd	s2,40(a0)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067ae:	6794                	ld	a3,8(a5)
    800067b0:	0026d703          	lhu	a4,2(a3)
    800067b4:	8b1d                	andi	a4,a4,7
    800067b6:	0706                	slli	a4,a4,0x1
    800067b8:	9736                	add	a4,a4,a3
    800067ba:	00b71223          	sh	a1,4(a4)

  __sync_synchronize();
    800067be:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067c2:	6798                	ld	a4,8(a5)
    800067c4:	00275783          	lhu	a5,2(a4)
    800067c8:	2785                	addiw	a5,a5,1
    800067ca:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067ce:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067d2:	100017b7          	lui	a5,0x10001
    800067d6:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067da:	00492703          	lw	a4,4(s2)
    800067de:	4785                	li	a5,1
    800067e0:	02f71163          	bne	a4,a5,80006802 <virtio_disk_rw+0x23c>
    sleep(b, &disk.vdisk_lock);
    800067e4:	00054997          	auipc	s3,0x54
    800067e8:	94498993          	addi	s3,s3,-1724 # 8005a128 <disk+0x2128>
  while(b->disk == 1) {
    800067ec:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067ee:	85ce                	mv	a1,s3
    800067f0:	854a                	mv	a0,s2
    800067f2:	ffffc097          	auipc	ra,0xffffc
    800067f6:	f5e080e7          	jalr	-162(ra) # 80002750 <sleep>
  while(b->disk == 1) {
    800067fa:	00492783          	lw	a5,4(s2)
    800067fe:	fe9788e3          	beq	a5,s1,800067ee <virtio_disk_rw+0x228>
  }

  disk.info[idx[0]].b = 0;
    80006802:	fa042503          	lw	a0,-96(s0)
    80006806:	20050793          	addi	a5,a0,512
    8000680a:	00479713          	slli	a4,a5,0x4
    8000680e:	00051797          	auipc	a5,0x51
    80006812:	7f278793          	addi	a5,a5,2034 # 80058000 <disk>
    80006816:	97ba                	add	a5,a5,a4
    80006818:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000681c:	00053997          	auipc	s3,0x53
    80006820:	7e498993          	addi	s3,s3,2020 # 8005a000 <disk+0x2000>
    80006824:	00451713          	slli	a4,a0,0x4
    80006828:	0009b783          	ld	a5,0(s3)
    8000682c:	97ba                	add	a5,a5,a4
    8000682e:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006832:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006836:	00000097          	auipc	ra,0x0
    8000683a:	bb0080e7          	jalr	-1104(ra) # 800063e6 <free_desc>
      i = nxt;
    8000683e:	854a                	mv	a0,s2
    if(flag & VRING_DESC_F_NEXT)
    80006840:	8885                	andi	s1,s1,1
    80006842:	f0ed                	bnez	s1,80006824 <virtio_disk_rw+0x25e>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006844:	00054517          	auipc	a0,0x54
    80006848:	8e450513          	addi	a0,a0,-1820 # 8005a128 <disk+0x2128>
    8000684c:	ffffa097          	auipc	ra,0xffffa
    80006850:	70a080e7          	jalr	1802(ra) # 80000f56 <release>
}
    80006854:	60e6                	ld	ra,88(sp)
    80006856:	6446                	ld	s0,80(sp)
    80006858:	64a6                	ld	s1,72(sp)
    8000685a:	6906                	ld	s2,64(sp)
    8000685c:	79e2                	ld	s3,56(sp)
    8000685e:	7a42                	ld	s4,48(sp)
    80006860:	7aa2                	ld	s5,40(sp)
    80006862:	7b02                	ld	s6,32(sp)
    80006864:	6be2                	ld	s7,24(sp)
    80006866:	6c42                	ld	s8,16(sp)
    80006868:	6125                	addi	sp,sp,96
    8000686a:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000686c:	00053797          	auipc	a5,0x53
    80006870:	79478793          	addi	a5,a5,1940 # 8005a000 <disk+0x2000>
    80006874:	639c                	ld	a5,0(a5)
    80006876:	97b6                	add	a5,a5,a3
    80006878:	4609                	li	a2,2
    8000687a:	00c79623          	sh	a2,12(a5)
    8000687e:	b5c1                	j	8000673e <virtio_disk_rw+0x178>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006880:	fa042583          	lw	a1,-96(s0)
    80006884:	20058713          	addi	a4,a1,512
    80006888:	0712                	slli	a4,a4,0x4
    8000688a:	00052697          	auipc	a3,0x52
    8000688e:	81e68693          	addi	a3,a3,-2018 # 800580a8 <disk+0xa8>
    80006892:	96ba                	add	a3,a3,a4
  if(write)
    80006894:	e00c1de3          	bnez	s8,800066ae <virtio_disk_rw+0xe8>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006898:	20058793          	addi	a5,a1,512
    8000689c:	00479613          	slli	a2,a5,0x4
    800068a0:	00051797          	auipc	a5,0x51
    800068a4:	76078793          	addi	a5,a5,1888 # 80058000 <disk>
    800068a8:	97b2                	add	a5,a5,a2
    800068aa:	0a07a423          	sw	zero,168(a5)
    800068ae:	bd21                	j	800066c6 <virtio_disk_rw+0x100>
      disk.free[i] = 0;
    800068b0:	00098c23          	sb	zero,24(s3)
    idx[i] = alloc_desc();
    800068b4:	00072023          	sw	zero,0(a4)
    if(idx[i] < 0){
    800068b8:	b3bd                	j	80006626 <virtio_disk_rw+0x60>

00000000800068ba <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068ba:	1101                	addi	sp,sp,-32
    800068bc:	ec06                	sd	ra,24(sp)
    800068be:	e822                	sd	s0,16(sp)
    800068c0:	e426                	sd	s1,8(sp)
    800068c2:	e04a                	sd	s2,0(sp)
    800068c4:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068c6:	00054517          	auipc	a0,0x54
    800068ca:	86250513          	addi	a0,a0,-1950 # 8005a128 <disk+0x2128>
    800068ce:	ffffa097          	auipc	ra,0xffffa
    800068d2:	5b8080e7          	jalr	1464(ra) # 80000e86 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068d6:	10001737          	lui	a4,0x10001
    800068da:	533c                	lw	a5,96(a4)
    800068dc:	8b8d                	andi	a5,a5,3
    800068de:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068e0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068e4:	00053797          	auipc	a5,0x53
    800068e8:	71c78793          	addi	a5,a5,1820 # 8005a000 <disk+0x2000>
    800068ec:	6b94                	ld	a3,16(a5)
    800068ee:	0207d703          	lhu	a4,32(a5)
    800068f2:	0026d783          	lhu	a5,2(a3)
    800068f6:	06f70163          	beq	a4,a5,80006958 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068fa:	00051917          	auipc	s2,0x51
    800068fe:	70690913          	addi	s2,s2,1798 # 80058000 <disk>
    80006902:	00053497          	auipc	s1,0x53
    80006906:	6fe48493          	addi	s1,s1,1790 # 8005a000 <disk+0x2000>
    __sync_synchronize();
    8000690a:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000690e:	6898                	ld	a4,16(s1)
    80006910:	0204d783          	lhu	a5,32(s1)
    80006914:	8b9d                	andi	a5,a5,7
    80006916:	078e                	slli	a5,a5,0x3
    80006918:	97ba                	add	a5,a5,a4
    8000691a:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000691c:	20078713          	addi	a4,a5,512
    80006920:	0712                	slli	a4,a4,0x4
    80006922:	974a                	add	a4,a4,s2
    80006924:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006928:	e731                	bnez	a4,80006974 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000692a:	20078793          	addi	a5,a5,512
    8000692e:	0792                	slli	a5,a5,0x4
    80006930:	97ca                	add	a5,a5,s2
    80006932:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006934:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006938:	ffffc097          	auipc	ra,0xffffc
    8000693c:	f9e080e7          	jalr	-98(ra) # 800028d6 <wakeup>

    disk.used_idx += 1;
    80006940:	0204d783          	lhu	a5,32(s1)
    80006944:	2785                	addiw	a5,a5,1
    80006946:	17c2                	slli	a5,a5,0x30
    80006948:	93c1                	srli	a5,a5,0x30
    8000694a:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000694e:	6898                	ld	a4,16(s1)
    80006950:	00275703          	lhu	a4,2(a4)
    80006954:	faf71be3          	bne	a4,a5,8000690a <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006958:	00053517          	auipc	a0,0x53
    8000695c:	7d050513          	addi	a0,a0,2000 # 8005a128 <disk+0x2128>
    80006960:	ffffa097          	auipc	ra,0xffffa
    80006964:	5f6080e7          	jalr	1526(ra) # 80000f56 <release>
}
    80006968:	60e2                	ld	ra,24(sp)
    8000696a:	6442                	ld	s0,16(sp)
    8000696c:	64a2                	ld	s1,8(sp)
    8000696e:	6902                	ld	s2,0(sp)
    80006970:	6105                	addi	sp,sp,32
    80006972:	8082                	ret
      panic("virtio_disk_intr status");
    80006974:	00002517          	auipc	a0,0x2
    80006978:	f1450513          	addi	a0,a0,-236 # 80008888 <syscalls+0x3f0>
    8000697c:	ffffa097          	auipc	ra,0xffffa
    80006980:	bfc080e7          	jalr	-1028(ra) # 80000578 <panic>

0000000080006984 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006984:	1141                	addi	sp,sp,-16
    80006986:	e422                	sd	s0,8(sp)
    80006988:	0800                	addi	s0,sp,16
  return -1;
}
    8000698a:	557d                	li	a0,-1
    8000698c:	6422                	ld	s0,8(sp)
    8000698e:	0141                	addi	sp,sp,16
    80006990:	8082                	ret

0000000080006992 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006992:	7179                	addi	sp,sp,-48
    80006994:	f406                	sd	ra,40(sp)
    80006996:	f022                	sd	s0,32(sp)
    80006998:	ec26                	sd	s1,24(sp)
    8000699a:	e84a                	sd	s2,16(sp)
    8000699c:	e44e                	sd	s3,8(sp)
    8000699e:	e052                	sd	s4,0(sp)
    800069a0:	1800                	addi	s0,sp,48
    800069a2:	89aa                	mv	s3,a0
    800069a4:	8a2e                	mv	s4,a1
    800069a6:	8932                	mv	s2,a2
  int m;

  acquire(&stats.lock);
    800069a8:	00054517          	auipc	a0,0x54
    800069ac:	65850513          	addi	a0,a0,1624 # 8005b000 <stats>
    800069b0:	ffffa097          	auipc	ra,0xffffa
    800069b4:	4d6080e7          	jalr	1238(ra) # 80000e86 <acquire>

  if(stats.sz == 0) {
    800069b8:	00055797          	auipc	a5,0x55
    800069bc:	64878793          	addi	a5,a5,1608 # 8005c000 <stats+0x1000>
    800069c0:	539c                	lw	a5,32(a5)
    800069c2:	cbad                	beqz	a5,80006a34 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800069c4:	00055797          	auipc	a5,0x55
    800069c8:	63c78793          	addi	a5,a5,1596 # 8005c000 <stats+0x1000>
    800069cc:	53d8                	lw	a4,36(a5)
    800069ce:	539c                	lw	a5,32(a5)
    800069d0:	9f99                	subw	a5,a5,a4
    800069d2:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800069d6:	06d05d63          	blez	a3,80006a50 <statsread+0xbe>
    if(m > n)
    800069da:	84be                	mv	s1,a5
    800069dc:	00d95363          	ble	a3,s2,800069e2 <statsread+0x50>
    800069e0:	84ca                	mv	s1,s2
    800069e2:	0004891b          	sext.w	s2,s1
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800069e6:	86ca                	mv	a3,s2
    800069e8:	00054617          	auipc	a2,0x54
    800069ec:	63860613          	addi	a2,a2,1592 # 8005b020 <stats+0x20>
    800069f0:	963a                	add	a2,a2,a4
    800069f2:	85d2                	mv	a1,s4
    800069f4:	854e                	mv	a0,s3
    800069f6:	ffffc097          	auipc	ra,0xffffc
    800069fa:	fbc080e7          	jalr	-68(ra) # 800029b2 <either_copyout>
    800069fe:	57fd                	li	a5,-1
    80006a00:	00f50963          	beq	a0,a5,80006a12 <statsread+0x80>
      stats.off += m;
    80006a04:	00055717          	auipc	a4,0x55
    80006a08:	5fc70713          	addi	a4,a4,1532 # 8005c000 <stats+0x1000>
    80006a0c:	535c                	lw	a5,36(a4)
    80006a0e:	9cbd                	addw	s1,s1,a5
    80006a10:	d344                	sw	s1,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006a12:	00054517          	auipc	a0,0x54
    80006a16:	5ee50513          	addi	a0,a0,1518 # 8005b000 <stats>
    80006a1a:	ffffa097          	auipc	ra,0xffffa
    80006a1e:	53c080e7          	jalr	1340(ra) # 80000f56 <release>
  return m;
}
    80006a22:	854a                	mv	a0,s2
    80006a24:	70a2                	ld	ra,40(sp)
    80006a26:	7402                	ld	s0,32(sp)
    80006a28:	64e2                	ld	s1,24(sp)
    80006a2a:	6942                	ld	s2,16(sp)
    80006a2c:	69a2                	ld	s3,8(sp)
    80006a2e:	6a02                	ld	s4,0(sp)
    80006a30:	6145                	addi	sp,sp,48
    80006a32:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    80006a34:	6585                	lui	a1,0x1
    80006a36:	00054517          	auipc	a0,0x54
    80006a3a:	5ea50513          	addi	a0,a0,1514 # 8005b020 <stats+0x20>
    80006a3e:	ffffa097          	auipc	ra,0xffffa
    80006a42:	690080e7          	jalr	1680(ra) # 800010ce <statslock>
    80006a46:	00055797          	auipc	a5,0x55
    80006a4a:	5ca7ad23          	sw	a0,1498(a5) # 8005c020 <stats+0x1020>
    80006a4e:	bf9d                	j	800069c4 <statsread+0x32>
    stats.sz = 0;
    80006a50:	00055797          	auipc	a5,0x55
    80006a54:	5b078793          	addi	a5,a5,1456 # 8005c000 <stats+0x1000>
    80006a58:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    80006a5c:	0207a223          	sw	zero,36(a5)
    m = -1;
    80006a60:	597d                	li	s2,-1
    80006a62:	bf45                	j	80006a12 <statsread+0x80>

0000000080006a64 <statsinit>:

void
statsinit(void)
{
    80006a64:	1141                	addi	sp,sp,-16
    80006a66:	e406                	sd	ra,8(sp)
    80006a68:	e022                	sd	s0,0(sp)
    80006a6a:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006a6c:	00002597          	auipc	a1,0x2
    80006a70:	e3458593          	addi	a1,a1,-460 # 800088a0 <syscalls+0x408>
    80006a74:	00054517          	auipc	a0,0x54
    80006a78:	58c50513          	addi	a0,a0,1420 # 8005b000 <stats>
    80006a7c:	ffffa097          	auipc	ra,0xffffa
    80006a80:	596080e7          	jalr	1430(ra) # 80001012 <initlock>

  devsw[STATS].read = statsread;
    80006a84:	00050797          	auipc	a5,0x50
    80006a88:	9a478793          	addi	a5,a5,-1628 # 80056428 <devsw>
    80006a8c:	00000717          	auipc	a4,0x0
    80006a90:	f0670713          	addi	a4,a4,-250 # 80006992 <statsread>
    80006a94:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006a96:	00000717          	auipc	a4,0x0
    80006a9a:	eee70713          	addi	a4,a4,-274 # 80006984 <statswrite>
    80006a9e:	f798                	sd	a4,40(a5)
}
    80006aa0:	60a2                	ld	ra,8(sp)
    80006aa2:	6402                	ld	s0,0(sp)
    80006aa4:	0141                	addi	sp,sp,16
    80006aa6:	8082                	ret

0000000080006aa8 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006aa8:	1101                	addi	sp,sp,-32
    80006aaa:	ec22                	sd	s0,24(sp)
    80006aac:	1000                	addi	s0,sp,32
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006aae:	c299                	beqz	a3,80006ab4 <sprintint+0xc>
    80006ab0:	0005cd63          	bltz	a1,80006aca <sprintint+0x22>
    x = -xx;
  else
    x = xx;
    80006ab4:	2581                	sext.w	a1,a1
    80006ab6:	4301                	li	t1,0

  i = 0;
    80006ab8:	fe040713          	addi	a4,s0,-32
    80006abc:	4801                	li	a6,0
  do {
    buf[i++] = digits[x % base];
    80006abe:	2601                	sext.w	a2,a2
    80006ac0:	00002897          	auipc	a7,0x2
    80006ac4:	de888893          	addi	a7,a7,-536 # 800088a8 <digits>
    80006ac8:	a801                	j	80006ad8 <sprintint+0x30>
    x = -xx;
    80006aca:	40b005bb          	negw	a1,a1
    80006ace:	2581                	sext.w	a1,a1
  if(sign && (sign = xx < 0))
    80006ad0:	4305                	li	t1,1
    x = -xx;
    80006ad2:	b7dd                	j	80006ab8 <sprintint+0x10>
  } while((x /= base) != 0);
    80006ad4:	85be                	mv	a1,a5
    buf[i++] = digits[x % base];
    80006ad6:	8836                	mv	a6,a3
    80006ad8:	0018069b          	addiw	a3,a6,1
    80006adc:	02c5f7bb          	remuw	a5,a1,a2
    80006ae0:	1782                	slli	a5,a5,0x20
    80006ae2:	9381                	srli	a5,a5,0x20
    80006ae4:	97c6                	add	a5,a5,a7
    80006ae6:	0007c783          	lbu	a5,0(a5)
    80006aea:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    80006aee:	0705                	addi	a4,a4,1
    80006af0:	02c5d7bb          	divuw	a5,a1,a2
    80006af4:	fec5f0e3          	bleu	a2,a1,80006ad4 <sprintint+0x2c>

  if(sign)
    80006af8:	00030b63          	beqz	t1,80006b0e <sprintint+0x66>
    buf[i++] = '-';
    80006afc:	ff040793          	addi	a5,s0,-16
    80006b00:	96be                	add	a3,a3,a5
    80006b02:	02d00793          	li	a5,45
    80006b06:	fef68823          	sb	a5,-16(a3)
    80006b0a:	0028069b          	addiw	a3,a6,2

  n = 0;
  while(--i >= 0)
    80006b0e:	02d05963          	blez	a3,80006b40 <sprintint+0x98>
    80006b12:	fe040793          	addi	a5,s0,-32
    80006b16:	00d78733          	add	a4,a5,a3
    80006b1a:	87aa                	mv	a5,a0
    80006b1c:	0505                	addi	a0,a0,1
    80006b1e:	fff6861b          	addiw	a2,a3,-1
    80006b22:	1602                	slli	a2,a2,0x20
    80006b24:	9201                	srli	a2,a2,0x20
    80006b26:	9532                	add	a0,a0,a2
  *s = c;
    80006b28:	fff74603          	lbu	a2,-1(a4)
    80006b2c:	00c78023          	sb	a2,0(a5)
  while(--i >= 0)
    80006b30:	177d                	addi	a4,a4,-1
    80006b32:	0785                	addi	a5,a5,1
    80006b34:	fea79ae3          	bne	a5,a0,80006b28 <sprintint+0x80>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006b38:	8536                	mv	a0,a3
    80006b3a:	6462                	ld	s0,24(sp)
    80006b3c:	6105                	addi	sp,sp,32
    80006b3e:	8082                	ret
  while(--i >= 0)
    80006b40:	4681                	li	a3,0
    80006b42:	bfdd                	j	80006b38 <sprintint+0x90>

0000000080006b44 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006b44:	7171                	addi	sp,sp,-176
    80006b46:	fc86                	sd	ra,120(sp)
    80006b48:	f8a2                	sd	s0,112(sp)
    80006b4a:	f4a6                	sd	s1,104(sp)
    80006b4c:	f0ca                	sd	s2,96(sp)
    80006b4e:	ecce                	sd	s3,88(sp)
    80006b50:	e8d2                	sd	s4,80(sp)
    80006b52:	e4d6                	sd	s5,72(sp)
    80006b54:	e0da                	sd	s6,64(sp)
    80006b56:	fc5e                	sd	s7,56(sp)
    80006b58:	f862                	sd	s8,48(sp)
    80006b5a:	f466                	sd	s9,40(sp)
    80006b5c:	f06a                	sd	s10,32(sp)
    80006b5e:	ec6e                	sd	s11,24(sp)
    80006b60:	0100                	addi	s0,sp,128
    80006b62:	e414                	sd	a3,8(s0)
    80006b64:	e818                	sd	a4,16(s0)
    80006b66:	ec1c                	sd	a5,24(s0)
    80006b68:	03043023          	sd	a6,32(s0)
    80006b6c:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006b70:	ce1d                	beqz	a2,80006bae <snprintf+0x6a>
    80006b72:	8baa                	mv	s7,a0
    80006b74:	89ae                	mv	s3,a1
    80006b76:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006b78:	00840793          	addi	a5,s0,8
    80006b7c:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006b80:	14b05263          	blez	a1,80006cc4 <snprintf+0x180>
    80006b84:	00064703          	lbu	a4,0(a2)
    80006b88:	0007079b          	sext.w	a5,a4
    80006b8c:	12078e63          	beqz	a5,80006cc8 <snprintf+0x184>
  int off = 0;
    80006b90:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006b92:	4901                	li	s2,0
    if(c != '%'){
    80006b94:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006b98:	06400b13          	li	s6,100
  *s = c;
    80006b9c:	02500d13          	li	s10,37
    switch(c){
    80006ba0:	07300c93          	li	s9,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    80006ba4:	02800d93          	li	s11,40
    switch(c){
    80006ba8:	07800c13          	li	s8,120
    80006bac:	a805                	j	80006bdc <snprintf+0x98>
    panic("null fmt");
    80006bae:	00001517          	auipc	a0,0x1
    80006bb2:	49250513          	addi	a0,a0,1170 # 80008040 <digits+0x28>
    80006bb6:	ffffa097          	auipc	ra,0xffffa
    80006bba:	9c2080e7          	jalr	-1598(ra) # 80000578 <panic>
  *s = c;
    80006bbe:	009b87b3          	add	a5,s7,s1
    80006bc2:	00e78023          	sb	a4,0(a5)
      off += sputc(buf+off, c);
    80006bc6:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006bc8:	2905                	addiw	s2,s2,1
    80006bca:	0b34dc63          	ble	s3,s1,80006c82 <snprintf+0x13e>
    80006bce:	012a07b3          	add	a5,s4,s2
    80006bd2:	0007c703          	lbu	a4,0(a5)
    80006bd6:	0007079b          	sext.w	a5,a4
    80006bda:	c7c5                	beqz	a5,80006c82 <snprintf+0x13e>
    if(c != '%'){
    80006bdc:	ff5791e3          	bne	a5,s5,80006bbe <snprintf+0x7a>
    c = fmt[++i] & 0xff;
    80006be0:	2905                	addiw	s2,s2,1
    80006be2:	012a07b3          	add	a5,s4,s2
    80006be6:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006bea:	cfc1                	beqz	a5,80006c82 <snprintf+0x13e>
    switch(c){
    80006bec:	05678163          	beq	a5,s6,80006c2e <snprintf+0xea>
    80006bf0:	02fb7763          	bleu	a5,s6,80006c1e <snprintf+0xda>
    80006bf4:	05978e63          	beq	a5,s9,80006c50 <snprintf+0x10c>
    80006bf8:	0b879b63          	bne	a5,s8,80006cae <snprintf+0x16a>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006bfc:	f8843783          	ld	a5,-120(s0)
    80006c00:	00878713          	addi	a4,a5,8
    80006c04:	f8e43423          	sd	a4,-120(s0)
    80006c08:	4685                	li	a3,1
    80006c0a:	4641                	li	a2,16
    80006c0c:	438c                	lw	a1,0(a5)
    80006c0e:	009b8533          	add	a0,s7,s1
    80006c12:	00000097          	auipc	ra,0x0
    80006c16:	e96080e7          	jalr	-362(ra) # 80006aa8 <sprintint>
    80006c1a:	9ca9                	addw	s1,s1,a0
      break;
    80006c1c:	b775                	j	80006bc8 <snprintf+0x84>
    switch(c){
    80006c1e:	09579863          	bne	a5,s5,80006cae <snprintf+0x16a>
  *s = c;
    80006c22:	009b87b3          	add	a5,s7,s1
    80006c26:	01a78023          	sb	s10,0(a5)
        off += sputc(buf+off, *s);
      break;
    case '%':
      off += sputc(buf+off, '%');
    80006c2a:	2485                	addiw	s1,s1,1
      break;
    80006c2c:	bf71                	j	80006bc8 <snprintf+0x84>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006c2e:	f8843783          	ld	a5,-120(s0)
    80006c32:	00878713          	addi	a4,a5,8
    80006c36:	f8e43423          	sd	a4,-120(s0)
    80006c3a:	4685                	li	a3,1
    80006c3c:	4629                	li	a2,10
    80006c3e:	438c                	lw	a1,0(a5)
    80006c40:	009b8533          	add	a0,s7,s1
    80006c44:	00000097          	auipc	ra,0x0
    80006c48:	e64080e7          	jalr	-412(ra) # 80006aa8 <sprintint>
    80006c4c:	9ca9                	addw	s1,s1,a0
      break;
    80006c4e:	bfad                	j	80006bc8 <snprintf+0x84>
      if((s = va_arg(ap, char*)) == 0)
    80006c50:	f8843783          	ld	a5,-120(s0)
    80006c54:	00878713          	addi	a4,a5,8
    80006c58:	f8e43423          	sd	a4,-120(s0)
    80006c5c:	639c                	ld	a5,0(a5)
    80006c5e:	c3b1                	beqz	a5,80006ca2 <snprintf+0x15e>
      for(; *s && off < sz; s++)
    80006c60:	0007c703          	lbu	a4,0(a5)
    80006c64:	d335                	beqz	a4,80006bc8 <snprintf+0x84>
    80006c66:	0134de63          	ble	s3,s1,80006c82 <snprintf+0x13e>
    80006c6a:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006c6e:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006c72:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006c74:	0785                	addi	a5,a5,1
    80006c76:	0007c703          	lbu	a4,0(a5)
    80006c7a:	d739                	beqz	a4,80006bc8 <snprintf+0x84>
    80006c7c:	0685                	addi	a3,a3,1
    80006c7e:	fe9998e3          	bne	s3,s1,80006c6e <snprintf+0x12a>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006c82:	8526                	mv	a0,s1
    80006c84:	70e6                	ld	ra,120(sp)
    80006c86:	7446                	ld	s0,112(sp)
    80006c88:	74a6                	ld	s1,104(sp)
    80006c8a:	7906                	ld	s2,96(sp)
    80006c8c:	69e6                	ld	s3,88(sp)
    80006c8e:	6a46                	ld	s4,80(sp)
    80006c90:	6aa6                	ld	s5,72(sp)
    80006c92:	6b06                	ld	s6,64(sp)
    80006c94:	7be2                	ld	s7,56(sp)
    80006c96:	7c42                	ld	s8,48(sp)
    80006c98:	7ca2                	ld	s9,40(sp)
    80006c9a:	7d02                	ld	s10,32(sp)
    80006c9c:	6de2                	ld	s11,24(sp)
    80006c9e:	614d                	addi	sp,sp,176
    80006ca0:	8082                	ret
      for(; *s && off < sz; s++)
    80006ca2:	876e                	mv	a4,s11
        s = "(null)";
    80006ca4:	00001797          	auipc	a5,0x1
    80006ca8:	39478793          	addi	a5,a5,916 # 80008038 <digits+0x20>
    80006cac:	bf6d                	j	80006c66 <snprintf+0x122>
  *s = c;
    80006cae:	009b8733          	add	a4,s7,s1
    80006cb2:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006cb6:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006cba:	975e                	add	a4,a4,s7
    80006cbc:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006cc0:	2489                	addiw	s1,s1,2
      break;
    80006cc2:	b719                	j	80006bc8 <snprintf+0x84>
  int off = 0;
    80006cc4:	4481                	li	s1,0
    80006cc6:	bf75                	j	80006c82 <snprintf+0x13e>
    80006cc8:	84be                	mv	s1,a5
    80006cca:	bf65                	j	80006c82 <snprintf+0x13e>
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
