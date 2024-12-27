
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	aa010113          	addi	sp,sp,-1376 # 80008aa0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	90e70713          	addi	a4,a4,-1778 # 80008960 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	35c78793          	addi	a5,a5,860 # 800063c0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd53c7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	7e4080e7          	jalr	2020(ra) # 80002910 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	91650513          	addi	a0,a0,-1770 # 80010aa0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	90648493          	addi	s1,s1,-1786 # 80010aa0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	99690913          	addi	s2,s2,-1642 # 80010b38 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	a36080e7          	jalr	-1482(ra) # 80001bf6 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	576080e7          	jalr	1398(ra) # 8000273e <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	278080e7          	jalr	632(ra) # 8000244e <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	6a8080e7          	jalr	1704(ra) # 800028ba <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	87a50513          	addi	a0,a0,-1926 # 80010aa0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	86450513          	addi	a0,a0,-1948 # 80010aa0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8cf72323          	sw	a5,-1850(a4) # 80010b38 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7d450513          	addi	a0,a0,2004 # 80010aa0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	674080e7          	jalr	1652(ra) # 80002966 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7a650513          	addi	a0,a0,1958 # 80010aa0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	78270713          	addi	a4,a4,1922 # 80010aa0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	75878793          	addi	a5,a5,1880 # 80010aa0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7c27a783          	lw	a5,1986(a5) # 80010b38 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	71670713          	addi	a4,a4,1814 # 80010aa0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	70648493          	addi	s1,s1,1798 # 80010aa0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6ca70713          	addi	a4,a4,1738 # 80010aa0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	74f72a23          	sw	a5,1876(a4) # 80010b40 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	68e78793          	addi	a5,a5,1678 # 80010aa0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	70c7a323          	sw	a2,1798(a5) # 80010b3c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6fa50513          	addi	a0,a0,1786 # 80010b38 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	07a080e7          	jalr	122(ra) # 800024c0 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	64050513          	addi	a0,a0,1600 # 80010aa0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00028797          	auipc	a5,0x28
    8000047c:	e2878793          	addi	a5,a5,-472 # 800282a0 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	6007ab23          	sw	zero,1558(a5) # 80010b60 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	3af72123          	sw	a5,930(a4) # 80008920 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	5a6dad83          	lw	s11,1446(s11) # 80010b60 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	55050513          	addi	a0,a0,1360 # 80010b48 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3f250513          	addi	a0,a0,1010 # 80010b48 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	3d648493          	addi	s1,s1,982 # 80010b48 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	39650513          	addi	a0,a0,918 # 80010b68 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	1227a783          	lw	a5,290(a5) # 80008920 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0f27b783          	ld	a5,242(a5) # 80008928 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0f273703          	ld	a4,242(a4) # 80008930 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	308a0a13          	addi	s4,s4,776 # 80010b68 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	0c048493          	addi	s1,s1,192 # 80008928 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	0c098993          	addi	s3,s3,192 # 80008930 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	c2e080e7          	jalr	-978(ra) # 800024c0 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	29a50513          	addi	a0,a0,666 # 80010b68 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0427a783          	lw	a5,66(a5) # 80008920 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	04873703          	ld	a4,72(a4) # 80008930 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0387b783          	ld	a5,56(a5) # 80008928 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	26c98993          	addi	s3,s3,620 # 80010b68 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	02448493          	addi	s1,s1,36 # 80008928 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	02490913          	addi	s2,s2,36 # 80008930 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	b32080e7          	jalr	-1230(ra) # 8000244e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	23648493          	addi	s1,s1,566 # 80010b68 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fee7b523          	sd	a4,-22(a5) # 80008930 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	1ac48493          	addi	s1,s1,428 # 80010b68 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00029797          	auipc	a5,0x29
    80000a02:	a3a78793          	addi	a5,a5,-1478 # 80029438 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	18290913          	addi	s2,s2,386 # 80010ba0 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0e650513          	addi	a0,a0,230 # 80010ba0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00029517          	auipc	a0,0x29
    80000ad2:	96a50513          	addi	a0,a0,-1686 # 80029438 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	0b048493          	addi	s1,s1,176 # 80010ba0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	09850513          	addi	a0,a0,152 # 80010ba0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	06c50513          	addi	a0,a0,108 # 80010ba0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	06a080e7          	jalr	106(ra) # 80001bda <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	038080e7          	jalr	56(ra) # 80001bda <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	02c080e7          	jalr	44(ra) # 80001bda <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	014080e7          	jalr	20(ra) # 80001bda <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	fd4080e7          	jalr	-44(ra) # 80001bda <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	fa8080e7          	jalr	-88(ra) # 80001bda <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:

volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if (cpuid() == 0)
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	d4a080e7          	jalr	-694(ra) # 80001bca <cpuid>
    __sync_synchronize();
    started = 1;
  }
  else
  {
    while (started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	ab070713          	addi	a4,a4,-1360 # 80008938 <started>
  if (cpuid() == 0)
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while (started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	d2e080e7          	jalr	-722(ra) # 80001bca <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();  // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart(); // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	d84080e7          	jalr	-636(ra) # 80002c42 <trapinithart>
    plicinithart(); // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	53a080e7          	jalr	1338(ra) # 80006400 <plicinithart>

// #ifdef MLFQ
//   mlfq_init(); // initialize MLFQ
// #endif

  scheduler();
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	2ae080e7          	jalr	686(ra) # 8000217c <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();            // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();          // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();      // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();         // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	be8080e7          	jalr	-1048(ra) # 80001b16 <procinit>
    trapinit();         // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	ce4080e7          	jalr	-796(ra) # 80002c1a <trapinit>
    trapinithart();     // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	d04080e7          	jalr	-764(ra) # 80002c42 <trapinithart>
    plicinit();         // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	4a4080e7          	jalr	1188(ra) # 800063ea <plicinit>
    plicinithart();     // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	4b2080e7          	jalr	1202(ra) # 80006400 <plicinithart>
    binit();            // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	652080e7          	jalr	1618(ra) # 800035a8 <binit>
    iinit();            // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	cf6080e7          	jalr	-778(ra) # 80003c54 <iinit>
    fileinit();         // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	c94080e7          	jalr	-876(ra) # 80004bfa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	59a080e7          	jalr	1434(ra) # 80006508 <virtio_disk_init>
    userinit();         // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	fb6080e7          	jalr	-74(ra) # 80001f2c <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9af72a23          	sw	a5,-1612(a4) # 80008938 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9a87b783          	ld	a5,-1624(a5) # 80008940 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00001097          	auipc	ra,0x1
    80001232:	852080e7          	jalr	-1966(ra) # 80001a80 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6ea7b623          	sd	a0,1772(a5) # 80008940 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <mlfq_init>:
} mlfq;

static int next_boost;

void mlfq_init(void)
{
    80001836:	1101                	addi	sp,sp,-32
    80001838:	ec06                	sd	ra,24(sp)
    8000183a:	e822                	sd	s0,16(sp)
    8000183c:	e426                	sd	s1,8(sp)
    8000183e:	1000                	addi	s0,sp,32
  initlock(&mlfq.lock, "mlfq");
    80001840:	0000f497          	auipc	s1,0xf
    80001844:	38048493          	addi	s1,s1,896 # 80010bc0 <mlfq>
    80001848:	00007597          	auipc	a1,0x7
    8000184c:	99058593          	addi	a1,a1,-1648 # 800081d8 <digits+0x198>
    80001850:	8526                	mv	a0,s1
    80001852:	fffff097          	auipc	ra,0xfffff
    80001856:	2f4080e7          	jalr	756(ra) # 80000b46 <initlock>
  for (int i = 0; i < MLFQ_LEVELS; i++)
  {
    mlfq.queues[i].head = mlfq.queues[i].tail = 0;
    8000185a:	0204b023          	sd	zero,32(s1)
    8000185e:	0004bc23          	sd	zero,24(s1)
    80001862:	0204b823          	sd	zero,48(s1)
    80001866:	0204b423          	sd	zero,40(s1)
    8000186a:	0404b023          	sd	zero,64(s1)
    8000186e:	0204bc23          	sd	zero,56(s1)
    80001872:	0404b823          	sd	zero,80(s1)
    80001876:	0404b423          	sd	zero,72(s1)
  }
  mlfq.time_slices[0] = 1;
    8000187a:	4785                	li	a5,1
    8000187c:	ccbc                	sw	a5,88(s1)
  mlfq.time_slices[1] = 4;
    8000187e:	4791                	li	a5,4
    80001880:	ccfc                	sw	a5,92(s1)
  mlfq.time_slices[2] = 8;
    80001882:	47a1                	li	a5,8
    80001884:	d0bc                	sw	a5,96(s1)
  mlfq.time_slices[3] = 16;
    80001886:	47c1                	li	a5,16
    80001888:	d0fc                	sw	a5,100(s1)
  next_boost = BOOST_INTERVAL;
    8000188a:	03000793          	li	a5,48
    8000188e:	00007717          	auipc	a4,0x7
    80001892:	0cf72123          	sw	a5,194(a4) # 80008950 <next_boost>
}
    80001896:	60e2                	ld	ra,24(sp)
    80001898:	6442                	ld	s0,16(sp)
    8000189a:	64a2                	ld	s1,8(sp)
    8000189c:	6105                	addi	sp,sp,32
    8000189e:	8082                	ret

00000000800018a0 <enqueue>:

void enqueue(struct proc *p, int level)
{
    800018a0:	1141                	addi	sp,sp,-16
    800018a2:	e422                	sd	s0,8(sp)
    800018a4:	0800                	addi	s0,sp,16
  if (mlfq.queues[level].tail)
    800018a6:	00158793          	addi	a5,a1,1
    800018aa:	00479713          	slli	a4,a5,0x4
    800018ae:	0000f797          	auipc	a5,0xf
    800018b2:	31278793          	addi	a5,a5,786 # 80010bc0 <mlfq>
    800018b6:	97ba                	add	a5,a5,a4
    800018b8:	6b9c                	ld	a5,16(a5)
    800018ba:	c385                	beqz	a5,800018da <enqueue+0x3a>
  {
    mlfq.queues[level].tail->next = p;
    800018bc:	32a7bc23          	sd	a0,824(a5)
  }
  else
  {
    mlfq.queues[level].head = p;
  }
  mlfq.queues[level].tail = p;
    800018c0:	0585                	addi	a1,a1,1
    800018c2:	0592                	slli	a1,a1,0x4
    800018c4:	0000f797          	auipc	a5,0xf
    800018c8:	2fc78793          	addi	a5,a5,764 # 80010bc0 <mlfq>
    800018cc:	95be                	add	a1,a1,a5
    800018ce:	e988                	sd	a0,16(a1)
  p->next = 0;
    800018d0:	32053c23          	sd	zero,824(a0)
}
    800018d4:	6422                	ld	s0,8(sp)
    800018d6:	0141                	addi	sp,sp,16
    800018d8:	8082                	ret
    mlfq.queues[level].head = p;
    800018da:	00158793          	addi	a5,a1,1
    800018de:	00479713          	slli	a4,a5,0x4
    800018e2:	0000f797          	auipc	a5,0xf
    800018e6:	2de78793          	addi	a5,a5,734 # 80010bc0 <mlfq>
    800018ea:	97ba                	add	a5,a5,a4
    800018ec:	e788                	sd	a0,8(a5)
    800018ee:	bfc9                	j	800018c0 <enqueue+0x20>

00000000800018f0 <dequeue>:

struct proc *dequeue(int level)
{
    800018f0:	1141                	addi	sp,sp,-16
    800018f2:	e422                	sd	s0,8(sp)
    800018f4:	0800                	addi	s0,sp,16
  struct proc *p = mlfq.queues[level].head;
    800018f6:	00150713          	addi	a4,a0,1
    800018fa:	00471693          	slli	a3,a4,0x4
    800018fe:	0000f717          	auipc	a4,0xf
    80001902:	2c270713          	addi	a4,a4,706 # 80010bc0 <mlfq>
    80001906:	9736                	add	a4,a4,a3
    80001908:	6708                	ld	a0,8(a4)
  if (p)
    8000190a:	c911                	beqz	a0,8000191e <dequeue+0x2e>
  {
    mlfq.queues[level].head = p->next;
    8000190c:	33853603          	ld	a2,824(a0)
    80001910:	0000f717          	auipc	a4,0xf
    80001914:	2b070713          	addi	a4,a4,688 # 80010bc0 <mlfq>
    80001918:	9736                	add	a4,a4,a3
    8000191a:	e710                	sd	a2,8(a4)
    if (!mlfq.queues[level].head)
    8000191c:	c601                	beqz	a2,80001924 <dequeue+0x34>
    {
      mlfq.queues[level].tail = 0;
    }
  }
  return p;
}
    8000191e:	6422                	ld	s0,8(sp)
    80001920:	0141                	addi	sp,sp,16
    80001922:	8082                	ret
      mlfq.queues[level].tail = 0;
    80001924:	0000f717          	auipc	a4,0xf
    80001928:	29c70713          	addi	a4,a4,668 # 80010bc0 <mlfq>
    8000192c:	00d707b3          	add	a5,a4,a3
    80001930:	0007b823          	sd	zero,16(a5)
  return p;
    80001934:	b7ed                	j	8000191e <dequeue+0x2e>

0000000080001936 <priority_boosting>:

void priority_boosting()
{
    80001936:	7179                	addi	sp,sp,-48
    80001938:	f406                	sd	ra,40(sp)
    8000193a:	f022                	sd	s0,32(sp)
    8000193c:	ec26                	sd	s1,24(sp)
    8000193e:	e84a                	sd	s2,16(sp)
    80001940:	e44e                	sd	s3,8(sp)
    80001942:	e052                	sd	s4,0(sp)
    80001944:	1800                	addi	s0,sp,48
  struct proc *p;

  // Acquire the global lock for queue operations
  acquire(&mlfq.lock);
    80001946:	0000f517          	auipc	a0,0xf
    8000194a:	27a50513          	addi	a0,a0,634 # 80010bc0 <mlfq>
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	288080e7          	jalr	648(ra) # 80000bd6 <acquire>

  for (p = proc; p < &proc[NPROC]; p++)
    80001956:	0000f497          	auipc	s1,0xf
    8000195a:	70248493          	addi	s1,s1,1794 # 80011058 <proc>
  {
    acquire(&p->lock); // Lock individual process
    if (p->state == RUNNABLE || p->state == RUNNING)
    8000195e:	4985                	li	s3,1
    {
      p->priority = 0;                          // Boost to highest priority
      p->remaining_ticks = mlfq.time_slices[0]; // Reset time slice
    80001960:	0000fa17          	auipc	s4,0xf
    80001964:	260a0a13          	addi	s4,s4,608 # 80010bc0 <mlfq>
  for (p = proc; p < &proc[NPROC]; p++)
    80001968:	0001c917          	auipc	s2,0x1c
    8000196c:	6f090913          	addi	s2,s2,1776 # 8001e058 <tickslock>
    80001970:	a811                	j	80001984 <priority_boosting+0x4e>
      enqueue(p, 0);                            // Move to highest priority queue
    }
    release(&p->lock); // Unlock process
    80001972:	8526                	mv	a0,s1
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	316080e7          	jalr	790(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000197c:	34048493          	addi	s1,s1,832
    80001980:	03248863          	beq	s1,s2,800019b0 <priority_boosting+0x7a>
    acquire(&p->lock); // Lock individual process
    80001984:	8526                	mv	a0,s1
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	250080e7          	jalr	592(ra) # 80000bd6 <acquire>
    if (p->state == RUNNABLE || p->state == RUNNING)
    8000198e:	4c9c                	lw	a5,24(s1)
    80001990:	37f5                	addiw	a5,a5,-3
    80001992:	fef9e0e3          	bltu	s3,a5,80001972 <priority_boosting+0x3c>
      p->priority = 0;                          // Boost to highest priority
    80001996:	3204a623          	sw	zero,812(s1)
      p->remaining_ticks = mlfq.time_slices[0]; // Reset time slice
    8000199a:	058a2783          	lw	a5,88(s4)
    8000199e:	32f4a823          	sw	a5,816(s1)
      enqueue(p, 0);                            // Move to highest priority queue
    800019a2:	4581                	li	a1,0
    800019a4:	8526                	mv	a0,s1
    800019a6:	00000097          	auipc	ra,0x0
    800019aa:	efa080e7          	jalr	-262(ra) # 800018a0 <enqueue>
    800019ae:	b7d1                	j	80001972 <priority_boosting+0x3c>
  }

  release(&mlfq.lock); // Release global lock
    800019b0:	0000f517          	auipc	a0,0xf
    800019b4:	21050513          	addi	a0,a0,528 # 80010bc0 <mlfq>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	2d2080e7          	jalr	722(ra) # 80000c8a <release>
}
    800019c0:	70a2                	ld	ra,40(sp)
    800019c2:	7402                	ld	s0,32(sp)
    800019c4:	64e2                	ld	s1,24(sp)
    800019c6:	6942                	ld	s2,16(sp)
    800019c8:	69a2                	ld	s3,8(sp)
    800019ca:	6a02                	ld	s4,0(sp)
    800019cc:	6145                	addi	sp,sp,48
    800019ce:	8082                	ret

00000000800019d0 <mlfq_remove>:

void mlfq_remove(struct proc *p, int level)
{
    800019d0:	7179                	addi	sp,sp,-48
    800019d2:	f406                	sd	ra,40(sp)
    800019d4:	f022                	sd	s0,32(sp)
    800019d6:	ec26                	sd	s1,24(sp)
    800019d8:	e84a                	sd	s2,16(sp)
    800019da:	e44e                	sd	s3,8(sp)
    800019dc:	1800                	addi	s0,sp,48
    800019de:	84aa                	mv	s1,a0
    800019e0:	89ae                	mv	s3,a1
  acquire(&mlfq.lock); // Acquire the MLFQ lock
    800019e2:	0000f917          	auipc	s2,0xf
    800019e6:	1de90913          	addi	s2,s2,478 # 80010bc0 <mlfq>
    800019ea:	854a                	mv	a0,s2
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	1ea080e7          	jalr	490(ra) # 80000bd6 <acquire>

  struct proc_queue *queue = &mlfq.queues[level];
  struct proc *current = queue->head;
    800019f4:	00198793          	addi	a5,s3,1 # 1001 <_entry-0x7fffefff>
    800019f8:	0792                	slli	a5,a5,0x4
    800019fa:	993e                	add	s2,s2,a5
    800019fc:	00893783          	ld	a5,8(s2)
  struct proc *prev = 0;

  // Iterate through the queue to find the process to remove
  while (current != 0)
    80001a00:	cb9d                	beqz	a5,80001a36 <mlfq_remove+0x66>
  {
    if (current == p)
    80001a02:	06978063          	beq	a5,s1,80001a62 <mlfq_remove+0x92>
      // Clean up process fields if necessary
      current->next = 0; // Clear the next pointer for safety
      break;             // Exit the loop since we've removed the process
    }
    prev = current;
    current = current->next; // Move to the next process
    80001a06:	873e                	mv	a4,a5
    80001a08:	3387b783          	ld	a5,824(a5)
  while (current != 0)
    80001a0c:	c78d                	beqz	a5,80001a36 <mlfq_remove+0x66>
    if (current == p)
    80001a0e:	fef49ce3          	bne	s1,a5,80001a06 <mlfq_remove+0x36>
        prev->next = current->next;
    80001a12:	3387b683          	ld	a3,824(a5)
    80001a16:	32d73c23          	sd	a3,824(a4)
      if (current == queue->tail)
    80001a1a:	00198693          	addi	a3,s3,1
    80001a1e:	00469613          	slli	a2,a3,0x4
    80001a22:	0000f697          	auipc	a3,0xf
    80001a26:	19e68693          	addi	a3,a3,414 # 80010bc0 <mlfq>
    80001a2a:	96b2                	add	a3,a3,a2
    80001a2c:	6a94                	ld	a3,16(a3)
    80001a2e:	02f68363          	beq	a3,a5,80001a54 <mlfq_remove+0x84>
      current->next = 0; // Clear the next pointer for safety
    80001a32:	3207bc23          	sd	zero,824(a5)
  }

  release(&mlfq.lock); // Release the MLFQ lock
    80001a36:	0000f517          	auipc	a0,0xf
    80001a3a:	18a50513          	addi	a0,a0,394 # 80010bc0 <mlfq>
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	24c080e7          	jalr	588(ra) # 80000c8a <release>
}
    80001a46:	70a2                	ld	ra,40(sp)
    80001a48:	7402                	ld	s0,32(sp)
    80001a4a:	64e2                	ld	s1,24(sp)
    80001a4c:	6942                	ld	s2,16(sp)
    80001a4e:	69a2                	ld	s3,8(sp)
    80001a50:	6145                	addi	sp,sp,48
    80001a52:	8082                	ret
        queue->tail = prev;
    80001a54:	0000f697          	auipc	a3,0xf
    80001a58:	16c68693          	addi	a3,a3,364 # 80010bc0 <mlfq>
    80001a5c:	96b2                	add	a3,a3,a2
    80001a5e:	ea98                	sd	a4,16(a3)
    80001a60:	bfc9                	j	80001a32 <mlfq_remove+0x62>
        queue->head = current->next;
    80001a62:	00198793          	addi	a5,s3,1
    80001a66:	00479713          	slli	a4,a5,0x4
    80001a6a:	0000f797          	auipc	a5,0xf
    80001a6e:	15678793          	addi	a5,a5,342 # 80010bc0 <mlfq>
    80001a72:	97ba                	add	a5,a5,a4
    80001a74:	3384b703          	ld	a4,824(s1)
    80001a78:	e798                	sd	a4,8(a5)
  struct proc *current = queue->head;
    80001a7a:	87a6                	mv	a5,s1
  struct proc *prev = 0;
    80001a7c:	4701                	li	a4,0
    80001a7e:	bf71                	j	80001a1a <mlfq_remove+0x4a>

0000000080001a80 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a80:	7139                	addi	sp,sp,-64
    80001a82:	fc06                	sd	ra,56(sp)
    80001a84:	f822                	sd	s0,48(sp)
    80001a86:	f426                	sd	s1,40(sp)
    80001a88:	f04a                	sd	s2,32(sp)
    80001a8a:	ec4e                	sd	s3,24(sp)
    80001a8c:	e852                	sd	s4,16(sp)
    80001a8e:	e456                	sd	s5,8(sp)
    80001a90:	e05a                	sd	s6,0(sp)
    80001a92:	0080                	addi	s0,sp,64
    80001a94:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a96:	0000f497          	auipc	s1,0xf
    80001a9a:	5c248493          	addi	s1,s1,1474 # 80011058 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a9e:	8b26                	mv	s6,s1
    80001aa0:	00006a97          	auipc	s5,0x6
    80001aa4:	560a8a93          	addi	s5,s5,1376 # 80008000 <etext>
    80001aa8:	04000937          	lui	s2,0x4000
    80001aac:	197d                	addi	s2,s2,-1
    80001aae:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001ab0:	0001ca17          	auipc	s4,0x1c
    80001ab4:	5a8a0a13          	addi	s4,s4,1448 # 8001e058 <tickslock>
    char *pa = kalloc();
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	02e080e7          	jalr	46(ra) # 80000ae6 <kalloc>
    80001ac0:	862a                	mv	a2,a0
    if (pa == 0)
    80001ac2:	c131                	beqz	a0,80001b06 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001ac4:	416485b3          	sub	a1,s1,s6
    80001ac8:	8599                	srai	a1,a1,0x6
    80001aca:	000ab783          	ld	a5,0(s5)
    80001ace:	02f585b3          	mul	a1,a1,a5
    80001ad2:	2585                	addiw	a1,a1,1
    80001ad4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ad8:	4719                	li	a4,6
    80001ada:	6685                	lui	a3,0x1
    80001adc:	40b905b3          	sub	a1,s2,a1
    80001ae0:	854e                	mv	a0,s3
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	65c080e7          	jalr	1628(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001aea:	34048493          	addi	s1,s1,832
    80001aee:	fd4495e3          	bne	s1,s4,80001ab8 <proc_mapstacks+0x38>
  }
}
    80001af2:	70e2                	ld	ra,56(sp)
    80001af4:	7442                	ld	s0,48(sp)
    80001af6:	74a2                	ld	s1,40(sp)
    80001af8:	7902                	ld	s2,32(sp)
    80001afa:	69e2                	ld	s3,24(sp)
    80001afc:	6a42                	ld	s4,16(sp)
    80001afe:	6aa2                	ld	s5,8(sp)
    80001b00:	6b02                	ld	s6,0(sp)
    80001b02:	6121                	addi	sp,sp,64
    80001b04:	8082                	ret
      panic("kalloc");
    80001b06:	00006517          	auipc	a0,0x6
    80001b0a:	6da50513          	addi	a0,a0,1754 # 800081e0 <digits+0x1a0>
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	a30080e7          	jalr	-1488(ra) # 8000053e <panic>

0000000080001b16 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001b16:	7139                	addi	sp,sp,-64
    80001b18:	fc06                	sd	ra,56(sp)
    80001b1a:	f822                	sd	s0,48(sp)
    80001b1c:	f426                	sd	s1,40(sp)
    80001b1e:	f04a                	sd	s2,32(sp)
    80001b20:	ec4e                	sd	s3,24(sp)
    80001b22:	e852                	sd	s4,16(sp)
    80001b24:	e456                	sd	s5,8(sp)
    80001b26:	e05a                	sd	s6,0(sp)
    80001b28:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001b2a:	00006597          	auipc	a1,0x6
    80001b2e:	6be58593          	addi	a1,a1,1726 # 800081e8 <digits+0x1a8>
    80001b32:	0000f517          	auipc	a0,0xf
    80001b36:	0f650513          	addi	a0,a0,246 # 80010c28 <pid_lock>
    80001b3a:	fffff097          	auipc	ra,0xfffff
    80001b3e:	00c080e7          	jalr	12(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b42:	00006597          	auipc	a1,0x6
    80001b46:	6ae58593          	addi	a1,a1,1710 # 800081f0 <digits+0x1b0>
    80001b4a:	0000f517          	auipc	a0,0xf
    80001b4e:	0f650513          	addi	a0,a0,246 # 80010c40 <wait_lock>
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	ff4080e7          	jalr	-12(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001b5a:	0000f497          	auipc	s1,0xf
    80001b5e:	4fe48493          	addi	s1,s1,1278 # 80011058 <proc>
  {
    initlock(&p->lock, "proc");
    80001b62:	00006b17          	auipc	s6,0x6
    80001b66:	69eb0b13          	addi	s6,s6,1694 # 80008200 <digits+0x1c0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001b6a:	8aa6                	mv	s5,s1
    80001b6c:	00006a17          	auipc	s4,0x6
    80001b70:	494a0a13          	addi	s4,s4,1172 # 80008000 <etext>
    80001b74:	04000937          	lui	s2,0x4000
    80001b78:	197d                	addi	s2,s2,-1
    80001b7a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b7c:	0001c997          	auipc	s3,0x1c
    80001b80:	4dc98993          	addi	s3,s3,1244 # 8001e058 <tickslock>
    initlock(&p->lock, "proc");
    80001b84:	85da                	mv	a1,s6
    80001b86:	8526                	mv	a0,s1
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	fbe080e7          	jalr	-66(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001b90:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b94:	415487b3          	sub	a5,s1,s5
    80001b98:	8799                	srai	a5,a5,0x6
    80001b9a:	000a3703          	ld	a4,0(s4)
    80001b9e:	02e787b3          	mul	a5,a5,a4
    80001ba2:	2785                	addiw	a5,a5,1
    80001ba4:	00d7979b          	slliw	a5,a5,0xd
    80001ba8:	40f907b3          	sub	a5,s2,a5
    80001bac:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001bae:	34048493          	addi	s1,s1,832
    80001bb2:	fd3499e3          	bne	s1,s3,80001b84 <procinit+0x6e>
  }
}
    80001bb6:	70e2                	ld	ra,56(sp)
    80001bb8:	7442                	ld	s0,48(sp)
    80001bba:	74a2                	ld	s1,40(sp)
    80001bbc:	7902                	ld	s2,32(sp)
    80001bbe:	69e2                	ld	s3,24(sp)
    80001bc0:	6a42                	ld	s4,16(sp)
    80001bc2:	6aa2                	ld	s5,8(sp)
    80001bc4:	6b02                	ld	s6,0(sp)
    80001bc6:	6121                	addi	sp,sp,64
    80001bc8:	8082                	ret

0000000080001bca <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001bca:	1141                	addi	sp,sp,-16
    80001bcc:	e422                	sd	s0,8(sp)
    80001bce:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bd0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001bd2:	2501                	sext.w	a0,a0
    80001bd4:	6422                	ld	s0,8(sp)
    80001bd6:	0141                	addi	sp,sp,16
    80001bd8:	8082                	ret

0000000080001bda <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001bda:	1141                	addi	sp,sp,-16
    80001bdc:	e422                	sd	s0,8(sp)
    80001bde:	0800                	addi	s0,sp,16
    80001be0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001be2:	2781                	sext.w	a5,a5
    80001be4:	079e                	slli	a5,a5,0x7
  return c;
}
    80001be6:	0000f517          	auipc	a0,0xf
    80001bea:	07250513          	addi	a0,a0,114 # 80010c58 <cpus>
    80001bee:	953e                	add	a0,a0,a5
    80001bf0:	6422                	ld	s0,8(sp)
    80001bf2:	0141                	addi	sp,sp,16
    80001bf4:	8082                	ret

0000000080001bf6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001bf6:	1101                	addi	sp,sp,-32
    80001bf8:	ec06                	sd	ra,24(sp)
    80001bfa:	e822                	sd	s0,16(sp)
    80001bfc:	e426                	sd	s1,8(sp)
    80001bfe:	1000                	addi	s0,sp,32
  push_off();
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	f8a080e7          	jalr	-118(ra) # 80000b8a <push_off>
    80001c08:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c0a:	2781                	sext.w	a5,a5
    80001c0c:	079e                	slli	a5,a5,0x7
    80001c0e:	0000f717          	auipc	a4,0xf
    80001c12:	fb270713          	addi	a4,a4,-78 # 80010bc0 <mlfq>
    80001c16:	97ba                	add	a5,a5,a4
    80001c18:	6fc4                	ld	s1,152(a5)
  pop_off();
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	010080e7          	jalr	16(ra) # 80000c2a <pop_off>
  return p;
}
    80001c22:	8526                	mv	a0,s1
    80001c24:	60e2                	ld	ra,24(sp)
    80001c26:	6442                	ld	s0,16(sp)
    80001c28:	64a2                	ld	s1,8(sp)
    80001c2a:	6105                	addi	sp,sp,32
    80001c2c:	8082                	ret

0000000080001c2e <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c2e:	1141                	addi	sp,sp,-16
    80001c30:	e406                	sd	ra,8(sp)
    80001c32:	e022                	sd	s0,0(sp)
    80001c34:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	fc0080e7          	jalr	-64(ra) # 80001bf6 <myproc>
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	04c080e7          	jalr	76(ra) # 80000c8a <release>

  if (first)
    80001c46:	00007797          	auipc	a5,0x7
    80001c4a:	c8a7a783          	lw	a5,-886(a5) # 800088d0 <first.1>
    80001c4e:	eb89                	bnez	a5,80001c60 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c50:	00001097          	auipc	ra,0x1
    80001c54:	00a080e7          	jalr	10(ra) # 80002c5a <usertrapret>
}
    80001c58:	60a2                	ld	ra,8(sp)
    80001c5a:	6402                	ld	s0,0(sp)
    80001c5c:	0141                	addi	sp,sp,16
    80001c5e:	8082                	ret
    first = 0;
    80001c60:	00007797          	auipc	a5,0x7
    80001c64:	c607a823          	sw	zero,-912(a5) # 800088d0 <first.1>
    fsinit(ROOTDEV);
    80001c68:	4505                	li	a0,1
    80001c6a:	00002097          	auipc	ra,0x2
    80001c6e:	f6a080e7          	jalr	-150(ra) # 80003bd4 <fsinit>
    80001c72:	bff9                	j	80001c50 <forkret+0x22>

0000000080001c74 <allocpid>:
{
    80001c74:	1101                	addi	sp,sp,-32
    80001c76:	ec06                	sd	ra,24(sp)
    80001c78:	e822                	sd	s0,16(sp)
    80001c7a:	e426                	sd	s1,8(sp)
    80001c7c:	e04a                	sd	s2,0(sp)
    80001c7e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c80:	0000f917          	auipc	s2,0xf
    80001c84:	fa890913          	addi	s2,s2,-88 # 80010c28 <pid_lock>
    80001c88:	854a                	mv	a0,s2
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	f4c080e7          	jalr	-180(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001c92:	00007797          	auipc	a5,0x7
    80001c96:	c4278793          	addi	a5,a5,-958 # 800088d4 <nextpid>
    80001c9a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c9c:	0014871b          	addiw	a4,s1,1
    80001ca0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ca2:	854a                	mv	a0,s2
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	fe6080e7          	jalr	-26(ra) # 80000c8a <release>
}
    80001cac:	8526                	mv	a0,s1
    80001cae:	60e2                	ld	ra,24(sp)
    80001cb0:	6442                	ld	s0,16(sp)
    80001cb2:	64a2                	ld	s1,8(sp)
    80001cb4:	6902                	ld	s2,0(sp)
    80001cb6:	6105                	addi	sp,sp,32
    80001cb8:	8082                	ret

0000000080001cba <proc_pagetable>:
{
    80001cba:	1101                	addi	sp,sp,-32
    80001cbc:	ec06                	sd	ra,24(sp)
    80001cbe:	e822                	sd	s0,16(sp)
    80001cc0:	e426                	sd	s1,8(sp)
    80001cc2:	e04a                	sd	s2,0(sp)
    80001cc4:	1000                	addi	s0,sp,32
    80001cc6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	660080e7          	jalr	1632(ra) # 80001328 <uvmcreate>
    80001cd0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001cd2:	c121                	beqz	a0,80001d12 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cd4:	4729                	li	a4,10
    80001cd6:	00005697          	auipc	a3,0x5
    80001cda:	32a68693          	addi	a3,a3,810 # 80007000 <_trampoline>
    80001cde:	6605                	lui	a2,0x1
    80001ce0:	040005b7          	lui	a1,0x4000
    80001ce4:	15fd                	addi	a1,a1,-1
    80001ce6:	05b2                	slli	a1,a1,0xc
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	3b6080e7          	jalr	950(ra) # 8000109e <mappages>
    80001cf0:	02054863          	bltz	a0,80001d20 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cf4:	4719                	li	a4,6
    80001cf6:	05893683          	ld	a3,88(s2)
    80001cfa:	6605                	lui	a2,0x1
    80001cfc:	020005b7          	lui	a1,0x2000
    80001d00:	15fd                	addi	a1,a1,-1
    80001d02:	05b6                	slli	a1,a1,0xd
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	398080e7          	jalr	920(ra) # 8000109e <mappages>
    80001d0e:	02054163          	bltz	a0,80001d30 <proc_pagetable+0x76>
}
    80001d12:	8526                	mv	a0,s1
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6902                	ld	s2,0(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret
    uvmfree(pagetable, 0);
    80001d20:	4581                	li	a1,0
    80001d22:	8526                	mv	a0,s1
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	808080e7          	jalr	-2040(ra) # 8000152c <uvmfree>
    return 0;
    80001d2c:	4481                	li	s1,0
    80001d2e:	b7d5                	j	80001d12 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d30:	4681                	li	a3,0
    80001d32:	4605                	li	a2,1
    80001d34:	040005b7          	lui	a1,0x4000
    80001d38:	15fd                	addi	a1,a1,-1
    80001d3a:	05b2                	slli	a1,a1,0xc
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	526080e7          	jalr	1318(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d46:	4581                	li	a1,0
    80001d48:	8526                	mv	a0,s1
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	7e2080e7          	jalr	2018(ra) # 8000152c <uvmfree>
    return 0;
    80001d52:	4481                	li	s1,0
    80001d54:	bf7d                	j	80001d12 <proc_pagetable+0x58>

0000000080001d56 <proc_freepagetable>:
{
    80001d56:	1101                	addi	sp,sp,-32
    80001d58:	ec06                	sd	ra,24(sp)
    80001d5a:	e822                	sd	s0,16(sp)
    80001d5c:	e426                	sd	s1,8(sp)
    80001d5e:	e04a                	sd	s2,0(sp)
    80001d60:	1000                	addi	s0,sp,32
    80001d62:	84aa                	mv	s1,a0
    80001d64:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d66:	4681                	li	a3,0
    80001d68:	4605                	li	a2,1
    80001d6a:	040005b7          	lui	a1,0x4000
    80001d6e:	15fd                	addi	a1,a1,-1
    80001d70:	05b2                	slli	a1,a1,0xc
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	4f2080e7          	jalr	1266(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d7a:	4681                	li	a3,0
    80001d7c:	4605                	li	a2,1
    80001d7e:	020005b7          	lui	a1,0x2000
    80001d82:	15fd                	addi	a1,a1,-1
    80001d84:	05b6                	slli	a1,a1,0xd
    80001d86:	8526                	mv	a0,s1
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	4dc080e7          	jalr	1244(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d90:	85ca                	mv	a1,s2
    80001d92:	8526                	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	798080e7          	jalr	1944(ra) # 8000152c <uvmfree>
}
    80001d9c:	60e2                	ld	ra,24(sp)
    80001d9e:	6442                	ld	s0,16(sp)
    80001da0:	64a2                	ld	s1,8(sp)
    80001da2:	6902                	ld	s2,0(sp)
    80001da4:	6105                	addi	sp,sp,32
    80001da6:	8082                	ret

0000000080001da8 <freeproc>:
{
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	1000                	addi	s0,sp,32
    80001db2:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001db4:	6d28                	ld	a0,88(a0)
    80001db6:	c509                	beqz	a0,80001dc0 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	c32080e7          	jalr	-974(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001dc0:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001dc4:	68a8                	ld	a0,80(s1)
    80001dc6:	c511                	beqz	a0,80001dd2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dc8:	64ac                	ld	a1,72(s1)
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	f8c080e7          	jalr	-116(ra) # 80001d56 <proc_freepagetable>
  p->pagetable = 0;
    80001dd2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001dd6:	0404b423          	sd	zero,72(s1)
  p->parent = 0;
    80001dda:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001dde:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001de2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001de6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dea:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001dee:	0004ac23          	sw	zero,24(s1)
}
    80001df2:	60e2                	ld	ra,24(sp)
    80001df4:	6442                	ld	s0,16(sp)
    80001df6:	64a2                	ld	s1,8(sp)
    80001df8:	6105                	addi	sp,sp,32
    80001dfa:	8082                	ret

0000000080001dfc <allocproc>:
{
    80001dfc:	7179                	addi	sp,sp,-48
    80001dfe:	f406                	sd	ra,40(sp)
    80001e00:	f022                	sd	s0,32(sp)
    80001e02:	ec26                	sd	s1,24(sp)
    80001e04:	e84a                	sd	s2,16(sp)
    80001e06:	e44e                	sd	s3,8(sp)
    80001e08:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001e0a:	0000f497          	auipc	s1,0xf
    80001e0e:	24e48493          	addi	s1,s1,590 # 80011058 <proc>
    80001e12:	0001c997          	auipc	s3,0x1c
    80001e16:	24698993          	addi	s3,s3,582 # 8001e058 <tickslock>
    acquire(&p->lock);
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	dba080e7          	jalr	-582(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001e24:	4c9c                	lw	a5,24(s1)
    80001e26:	cf81                	beqz	a5,80001e3e <allocproc+0x42>
      release(&p->lock);
    80001e28:	8526                	mv	a0,s1
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	e60080e7          	jalr	-416(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e32:	34048493          	addi	s1,s1,832
    80001e36:	ff3492e3          	bne	s1,s3,80001e1a <allocproc+0x1e>
  return 0;
    80001e3a:	4481                	li	s1,0
    80001e3c:	a845                	j	80001eec <allocproc+0xf0>
  p->pid = allocpid();
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	e36080e7          	jalr	-458(ra) # 80001c74 <allocpid>
    80001e46:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e48:	4785                	li	a5,1
    80001e4a:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	c9a080e7          	jalr	-870(ra) # 80000ae6 <kalloc>
    80001e54:	89aa                	mv	s3,a0
    80001e56:	eca8                	sd	a0,88(s1)
    80001e58:	c155                	beqz	a0,80001efc <allocproc+0x100>
  p->pagetable = proc_pagetable(p);
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	00000097          	auipc	ra,0x0
    80001e60:	e5e080e7          	jalr	-418(ra) # 80001cba <proc_pagetable>
    80001e64:	89aa                	mv	s3,a0
    80001e66:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001e68:	c555                	beqz	a0,80001f14 <allocproc+0x118>
  memset(&p->context, 0, sizeof(p->context));
    80001e6a:	07000613          	li	a2,112
    80001e6e:	4581                	li	a1,0
    80001e70:	06048513          	addi	a0,s1,96
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e5e080e7          	jalr	-418(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001e7c:	00000797          	auipc	a5,0x0
    80001e80:	db278793          	addi	a5,a5,-590 # 80001c2e <forkret>
    80001e84:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e86:	60bc                	ld	a5,64(s1)
    80001e88:	6705                	lui	a4,0x1
    80001e8a:	97ba                	add	a5,a5,a4
    80001e8c:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e8e:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e92:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e96:	00007797          	auipc	a5,0x7
    80001e9a:	abe7a783          	lw	a5,-1346(a5) # 80008954 <ticks>
    80001e9e:	16f4a623          	sw	a5,364(s1)
  for (int i = 0; i < MAX_SYSCALLS; i++)
    80001ea2:	17448793          	addi	a5,s1,372
    80001ea6:	1f448713          	addi	a4,s1,500
    p->syscall_count[i] = 0;
    80001eaa:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < MAX_SYSCALLS; i++)
    80001eae:	0791                	addi	a5,a5,4
    80001eb0:	fee79de3          	bne	a5,a4,80001eaa <allocproc+0xae>
  p->priority = 0;                          // Start at highest priority
    80001eb4:	3204a623          	sw	zero,812(s1)
  p->remaining_ticks = mlfq.time_slices[0]; // Set initial time slice
    80001eb8:	0000f917          	auipc	s2,0xf
    80001ebc:	d0890913          	addi	s2,s2,-760 # 80010bc0 <mlfq>
    80001ec0:	05892783          	lw	a5,88(s2)
    80001ec4:	32f4a823          	sw	a5,816(s1)
  p->next = 0;                              // Initialize next pointer for queue
    80001ec8:	3204bc23          	sd	zero,824(s1)
  acquire(&mlfq.lock);
    80001ecc:	854a                	mv	a0,s2
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	d08080e7          	jalr	-760(ra) # 80000bd6 <acquire>
  enqueue(p, 0);
    80001ed6:	4581                	li	a1,0
    80001ed8:	8526                	mv	a0,s1
    80001eda:	00000097          	auipc	ra,0x0
    80001ede:	9c6080e7          	jalr	-1594(ra) # 800018a0 <enqueue>
  release(&mlfq.lock);
    80001ee2:	854a                	mv	a0,s2
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	da6080e7          	jalr	-602(ra) # 80000c8a <release>
}
    80001eec:	8526                	mv	a0,s1
    80001eee:	70a2                	ld	ra,40(sp)
    80001ef0:	7402                	ld	s0,32(sp)
    80001ef2:	64e2                	ld	s1,24(sp)
    80001ef4:	6942                	ld	s2,16(sp)
    80001ef6:	69a2                	ld	s3,8(sp)
    80001ef8:	6145                	addi	sp,sp,48
    80001efa:	8082                	ret
    freeproc(p);
    80001efc:	8526                	mv	a0,s1
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	eaa080e7          	jalr	-342(ra) # 80001da8 <freeproc>
    release(&p->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d82080e7          	jalr	-638(ra) # 80000c8a <release>
    return 0;
    80001f10:	84ce                	mv	s1,s3
    80001f12:	bfe9                	j	80001eec <allocproc+0xf0>
    freeproc(p);
    80001f14:	8526                	mv	a0,s1
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	e92080e7          	jalr	-366(ra) # 80001da8 <freeproc>
    release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	d6a080e7          	jalr	-662(ra) # 80000c8a <release>
    return 0;
    80001f28:	84ce                	mv	s1,s3
    80001f2a:	b7c9                	j	80001eec <allocproc+0xf0>

0000000080001f2c <userinit>:
{
    80001f2c:	1101                	addi	sp,sp,-32
    80001f2e:	ec06                	sd	ra,24(sp)
    80001f30:	e822                	sd	s0,16(sp)
    80001f32:	e426                	sd	s1,8(sp)
    80001f34:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	ec6080e7          	jalr	-314(ra) # 80001dfc <allocproc>
    80001f3e:	84aa                	mv	s1,a0
  initproc = p;
    80001f40:	00007797          	auipc	a5,0x7
    80001f44:	a0a7b423          	sd	a0,-1528(a5) # 80008948 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f48:	03400613          	li	a2,52
    80001f4c:	00007597          	auipc	a1,0x7
    80001f50:	99458593          	addi	a1,a1,-1644 # 800088e0 <initcode>
    80001f54:	6928                	ld	a0,80(a0)
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	400080e7          	jalr	1024(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001f5e:	6785                	lui	a5,0x1
    80001f60:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001f62:	6cb8                	ld	a4,88(s1)
    80001f64:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001f68:	6cb8                	ld	a4,88(s1)
    80001f6a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f6c:	4641                	li	a2,16
    80001f6e:	00006597          	auipc	a1,0x6
    80001f72:	29a58593          	addi	a1,a1,666 # 80008208 <digits+0x1c8>
    80001f76:	15848513          	addi	a0,s1,344
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	ea2080e7          	jalr	-350(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001f82:	00006517          	auipc	a0,0x6
    80001f86:	29650513          	addi	a0,a0,662 # 80008218 <digits+0x1d8>
    80001f8a:	00002097          	auipc	ra,0x2
    80001f8e:	66c080e7          	jalr	1644(ra) # 800045f6 <namei>
    80001f92:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f96:	478d                	li	a5,3
    80001f98:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	cee080e7          	jalr	-786(ra) # 80000c8a <release>
}
    80001fa4:	60e2                	ld	ra,24(sp)
    80001fa6:	6442                	ld	s0,16(sp)
    80001fa8:	64a2                	ld	s1,8(sp)
    80001faa:	6105                	addi	sp,sp,32
    80001fac:	8082                	ret

0000000080001fae <growproc>:
{
    80001fae:	1101                	addi	sp,sp,-32
    80001fb0:	ec06                	sd	ra,24(sp)
    80001fb2:	e822                	sd	s0,16(sp)
    80001fb4:	e426                	sd	s1,8(sp)
    80001fb6:	e04a                	sd	s2,0(sp)
    80001fb8:	1000                	addi	s0,sp,32
    80001fba:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	c3a080e7          	jalr	-966(ra) # 80001bf6 <myproc>
    80001fc4:	84aa                	mv	s1,a0
  sz = p->sz;
    80001fc6:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001fc8:	01204c63          	bgtz	s2,80001fe0 <growproc+0x32>
  else if (n < 0)
    80001fcc:	02094663          	bltz	s2,80001ff8 <growproc+0x4a>
  p->sz = sz;
    80001fd0:	e4ac                	sd	a1,72(s1)
  return 0;
    80001fd2:	4501                	li	a0,0
}
    80001fd4:	60e2                	ld	ra,24(sp)
    80001fd6:	6442                	ld	s0,16(sp)
    80001fd8:	64a2                	ld	s1,8(sp)
    80001fda:	6902                	ld	s2,0(sp)
    80001fdc:	6105                	addi	sp,sp,32
    80001fde:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001fe0:	4691                	li	a3,4
    80001fe2:	00b90633          	add	a2,s2,a1
    80001fe6:	6928                	ld	a0,80(a0)
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	428080e7          	jalr	1064(ra) # 80001410 <uvmalloc>
    80001ff0:	85aa                	mv	a1,a0
    80001ff2:	fd79                	bnez	a0,80001fd0 <growproc+0x22>
      return -1;
    80001ff4:	557d                	li	a0,-1
    80001ff6:	bff9                	j	80001fd4 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ff8:	00b90633          	add	a2,s2,a1
    80001ffc:	6928                	ld	a0,80(a0)
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	3ca080e7          	jalr	970(ra) # 800013c8 <uvmdealloc>
    80002006:	85aa                	mv	a1,a0
    80002008:	b7e1                	j	80001fd0 <growproc+0x22>

000000008000200a <fork>:
{
    8000200a:	7139                	addi	sp,sp,-64
    8000200c:	fc06                	sd	ra,56(sp)
    8000200e:	f822                	sd	s0,48(sp)
    80002010:	f426                	sd	s1,40(sp)
    80002012:	f04a                	sd	s2,32(sp)
    80002014:	ec4e                	sd	s3,24(sp)
    80002016:	e852                	sd	s4,16(sp)
    80002018:	e456                	sd	s5,8(sp)
    8000201a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	bda080e7          	jalr	-1062(ra) # 80001bf6 <myproc>
    80002024:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	dd6080e7          	jalr	-554(ra) # 80001dfc <allocproc>
    8000202e:	14050563          	beqz	a0,80002178 <fork+0x16e>
    80002032:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002034:	048ab603          	ld	a2,72(s5)
    80002038:	692c                	ld	a1,80(a0)
    8000203a:	050ab503          	ld	a0,80(s5)
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	526080e7          	jalr	1318(ra) # 80001564 <uvmcopy>
    80002046:	04054863          	bltz	a0,80002096 <fork+0x8c>
  np->sz = p->sz;
    8000204a:	048ab783          	ld	a5,72(s5)
    8000204e:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002052:	058ab683          	ld	a3,88(s5)
    80002056:	87b6                	mv	a5,a3
    80002058:	0589b703          	ld	a4,88(s3)
    8000205c:	12068693          	addi	a3,a3,288
    80002060:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002064:	6788                	ld	a0,8(a5)
    80002066:	6b8c                	ld	a1,16(a5)
    80002068:	6f90                	ld	a2,24(a5)
    8000206a:	01073023          	sd	a6,0(a4)
    8000206e:	e708                	sd	a0,8(a4)
    80002070:	eb0c                	sd	a1,16(a4)
    80002072:	ef10                	sd	a2,24(a4)
    80002074:	02078793          	addi	a5,a5,32
    80002078:	02070713          	addi	a4,a4,32
    8000207c:	fed792e3          	bne	a5,a3,80002060 <fork+0x56>
  np->trapframe->a0 = 0;
    80002080:	0589b783          	ld	a5,88(s3)
    80002084:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80002088:	0d0a8493          	addi	s1,s5,208
    8000208c:	0d098913          	addi	s2,s3,208
    80002090:	150a8a13          	addi	s4,s5,336
    80002094:	a00d                	j	800020b6 <fork+0xac>
    freeproc(np);
    80002096:	854e                	mv	a0,s3
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	d10080e7          	jalr	-752(ra) # 80001da8 <freeproc>
    release(&np->lock);
    800020a0:	854e                	mv	a0,s3
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	be8080e7          	jalr	-1048(ra) # 80000c8a <release>
    return -1;
    800020aa:	5a7d                	li	s4,-1
    800020ac:	a865                	j	80002164 <fork+0x15a>
  for (i = 0; i < NOFILE; i++)
    800020ae:	04a1                	addi	s1,s1,8
    800020b0:	0921                	addi	s2,s2,8
    800020b2:	01448b63          	beq	s1,s4,800020c8 <fork+0xbe>
    if (p->ofile[i])
    800020b6:	6088                	ld	a0,0(s1)
    800020b8:	d97d                	beqz	a0,800020ae <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800020ba:	00003097          	auipc	ra,0x3
    800020be:	bd2080e7          	jalr	-1070(ra) # 80004c8c <filedup>
    800020c2:	00a93023          	sd	a0,0(s2)
    800020c6:	b7e5                	j	800020ae <fork+0xa4>
  np->cwd = idup(p->cwd);
    800020c8:	150ab503          	ld	a0,336(s5)
    800020cc:	00002097          	auipc	ra,0x2
    800020d0:	d46080e7          	jalr	-698(ra) # 80003e12 <idup>
    800020d4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020d8:	4641                	li	a2,16
    800020da:	158a8593          	addi	a1,s5,344
    800020de:	15898513          	addi	a0,s3,344
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	d3a080e7          	jalr	-710(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    800020ea:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020ee:	854e                	mv	a0,s3
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	b9a080e7          	jalr	-1126(ra) # 80000c8a <release>
  acquire(&wait_lock);
    800020f8:	0000f497          	auipc	s1,0xf
    800020fc:	ac848493          	addi	s1,s1,-1336 # 80010bc0 <mlfq>
    80002100:	0000f917          	auipc	s2,0xf
    80002104:	b4090913          	addi	s2,s2,-1216 # 80010c40 <wait_lock>
    80002108:	854a                	mv	a0,s2
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	acc080e7          	jalr	-1332(ra) # 80000bd6 <acquire>
  np->parent = p;
    80002112:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002116:	854a                	mv	a0,s2
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	b72080e7          	jalr	-1166(ra) # 80000c8a <release>
  acquire(&np->lock);
    80002120:	854e                	mv	a0,s3
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	ab4080e7          	jalr	-1356(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    8000212a:	478d                	li	a5,3
    8000212c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002130:	854e                	mv	a0,s3
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	b58080e7          	jalr	-1192(ra) # 80000c8a <release>
  np->priority = 0;
    8000213a:	3209a623          	sw	zero,812(s3)
  np->remaining_ticks = mlfq.time_slices[0];
    8000213e:	4cbc                	lw	a5,88(s1)
    80002140:	32f9a823          	sw	a5,816(s3)
  acquire(&mlfq.lock);
    80002144:	8526                	mv	a0,s1
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	a90080e7          	jalr	-1392(ra) # 80000bd6 <acquire>
  enqueue(np, 0);
    8000214e:	4581                	li	a1,0
    80002150:	854e                	mv	a0,s3
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	74e080e7          	jalr	1870(ra) # 800018a0 <enqueue>
  release(&mlfq.lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b2e080e7          	jalr	-1234(ra) # 80000c8a <release>
}
    80002164:	8552                	mv	a0,s4
    80002166:	70e2                	ld	ra,56(sp)
    80002168:	7442                	ld	s0,48(sp)
    8000216a:	74a2                	ld	s1,40(sp)
    8000216c:	7902                	ld	s2,32(sp)
    8000216e:	69e2                	ld	s3,24(sp)
    80002170:	6a42                	ld	s4,16(sp)
    80002172:	6aa2                	ld	s5,8(sp)
    80002174:	6121                	addi	sp,sp,64
    80002176:	8082                	ret
    return -1;
    80002178:	5a7d                	li	s4,-1
    8000217a:	b7ed                	j	80002164 <fork+0x15a>

000000008000217c <scheduler>:
{
    8000217c:	711d                	addi	sp,sp,-96
    8000217e:	ec86                	sd	ra,88(sp)
    80002180:	e8a2                	sd	s0,80(sp)
    80002182:	e4a6                	sd	s1,72(sp)
    80002184:	e0ca                	sd	s2,64(sp)
    80002186:	fc4e                	sd	s3,56(sp)
    80002188:	f852                	sd	s4,48(sp)
    8000218a:	f456                	sd	s5,40(sp)
    8000218c:	f05a                	sd	s6,32(sp)
    8000218e:	ec5e                	sd	s7,24(sp)
    80002190:	e862                	sd	s8,16(sp)
    80002192:	e466                	sd	s9,8(sp)
    80002194:	1080                	addi	s0,sp,96
    80002196:	8492                	mv	s1,tp
  int id = r_tp();
    80002198:	2481                	sext.w	s1,s1
  c->proc = 0;
    8000219a:	00749b93          	slli	s7,s1,0x7
    8000219e:	0000f797          	auipc	a5,0xf
    800021a2:	a2278793          	addi	a5,a5,-1502 # 80010bc0 <mlfq>
    800021a6:	97de                	add	a5,a5,s7
    800021a8:	0807bc23          	sd	zero,152(a5)
  printf("Scheduler: Multi-Level Feedback Queue (MLFQ) is active.\n");
    800021ac:	00006517          	auipc	a0,0x6
    800021b0:	07450513          	addi	a0,a0,116 # 80008220 <digits+0x1e0>
    800021b4:	ffffe097          	auipc	ra,0xffffe
    800021b8:	3d4080e7          	jalr	980(ra) # 80000588 <printf>
          swtch(&c->context, &p->context); // Context switch to the process
    800021bc:	0000f797          	auipc	a5,0xf
    800021c0:	aa478793          	addi	a5,a5,-1372 # 80010c60 <cpus+0x8>
    800021c4:	9bbe                	add	s7,s7,a5
    if (ticks >= next_boost)
    800021c6:	00006c97          	auipc	s9,0x6
    800021ca:	78ec8c93          	addi	s9,s9,1934 # 80008954 <ticks>
    acquire(&mlfq.lock); // Acquire MLFQ lock
    800021ce:	0000fa17          	auipc	s4,0xf
    800021d2:	9f2a0a13          	addi	s4,s4,-1550 # 80010bc0 <mlfq>
        if (p->state == RUNNABLE)
    800021d6:	498d                	li	s3,3
          c->proc = p;        // Set current process
    800021d8:	049e                	slli	s1,s1,0x7
    800021da:	009a0ab3          	add	s5,s4,s1
    800021de:	a875                	j	8000229a <scheduler+0x11e>
      priority_boosting(); // Ensure this function properly handles locks
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	756080e7          	jalr	1878(ra) # 80001936 <priority_boosting>
    800021e8:	a0f9                	j	800022b6 <scheduler+0x13a>
              p->remaining_ticks = mlfq.time_slices[p->priority]; // Reset remaining ticks
    800021ea:	32c4a783          	lw	a5,812(s1)
    800021ee:	07d1                	addi	a5,a5,20
    800021f0:	078a                	slli	a5,a5,0x2
    800021f2:	97d2                	add	a5,a5,s4
    800021f4:	479c                	lw	a5,8(a5)
    800021f6:	32f4a823          	sw	a5,816(s1)
            enqueue(p, p->priority); // Requeue based on new priority
    800021fa:	32c4a583          	lw	a1,812(s1)
    800021fe:	8526                	mv	a0,s1
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	6a0080e7          	jalr	1696(ra) # 800018a0 <enqueue>
        release(&p->lock); // Release the process lock
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a80080e7          	jalr	-1408(ra) # 80000c8a <release>
      while ((p = dequeue(q)) != 0)
    80002212:	854a                	mv	a0,s2
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	6dc080e7          	jalr	1756(ra) # 800018f0 <dequeue>
    8000221c:	84aa                	mv	s1,a0
    8000221e:	c525                	beqz	a0,80002286 <scheduler+0x10a>
        acquire(&p->lock); // Acquire the process lock
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	9b4080e7          	jalr	-1612(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE)
    8000222a:	4c9c                	lw	a5,24(s1)
    8000222c:	fd379ee3          	bne	a5,s3,80002208 <scheduler+0x8c>
          p->state = RUNNING; // Set state to RUNNING
    80002230:	0164ac23          	sw	s6,24(s1)
          c->proc = p;        // Set current process
    80002234:	089abc23          	sd	s1,152(s5)
          release(&mlfq.lock);             // Release MLFQ lock before switching
    80002238:	8552                	mv	a0,s4
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	a50080e7          	jalr	-1456(ra) # 80000c8a <release>
          swtch(&c->context, &p->context); // Context switch to the process
    80002242:	06048593          	addi	a1,s1,96
    80002246:	855e                	mv	a0,s7
    80002248:	00001097          	auipc	ra,0x1
    8000224c:	968080e7          	jalr	-1688(ra) # 80002bb0 <swtch>
          c->proc = 0;                     // Clear current process after returning
    80002250:	080abc23          	sd	zero,152(s5)
          acquire(&mlfq.lock);
    80002254:	8552                	mv	a0,s4
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	980080e7          	jalr	-1664(ra) # 80000bd6 <acquire>
          if (p->state == RUNNABLE)
    8000225e:	4c9c                	lw	a5,24(s1)
    80002260:	fb3794e3          	bne	a5,s3,80002208 <scheduler+0x8c>
            p->remaining_ticks--;
    80002264:	3304a783          	lw	a5,816(s1)
    80002268:	37fd                	addiw	a5,a5,-1
    8000226a:	0007871b          	sext.w	a4,a5
    8000226e:	32f4a823          	sw	a5,816(s1)
            if (p->remaining_ticks <= 0)
    80002272:	f8e044e3          	bgtz	a4,800021fa <scheduler+0x7e>
              if (p->priority < MLFQ_LEVELS - 1)
    80002276:	32c4a783          	lw	a5,812(s1)
    8000227a:	f6fc48e3          	blt	s8,a5,800021ea <scheduler+0x6e>
                p->priority++;
    8000227e:	2785                	addiw	a5,a5,1
    80002280:	32f4a623          	sw	a5,812(s1)
    80002284:	b79d                	j	800021ea <scheduler+0x6e>
    for (int q = 0; q < MLFQ_LEVELS; q++)
    80002286:	2905                	addiw	s2,s2,1
    80002288:	01690463          	beq	s2,s6,80002290 <scheduler+0x114>
              if (p->priority < MLFQ_LEVELS - 1)
    8000228c:	4c09                	li	s8,2
    8000228e:	b751                	j	80002212 <scheduler+0x96>
    release(&mlfq.lock); // Release MLFQ lock after processing all queues
    80002290:	8552                	mv	a0,s4
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	9f8080e7          	jalr	-1544(ra) # 80000c8a <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000229a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000229e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022a2:	10079073          	csrw	sstatus,a5
    if (ticks >= next_boost)
    800022a6:	000ca703          	lw	a4,0(s9)
    800022aa:	00006797          	auipc	a5,0x6
    800022ae:	6a67a783          	lw	a5,1702(a5) # 80008950 <next_boost>
    800022b2:	f2f777e3          	bgeu	a4,a5,800021e0 <scheduler+0x64>
    acquire(&mlfq.lock); // Acquire MLFQ lock
    800022b6:	8552                	mv	a0,s4
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	91e080e7          	jalr	-1762(ra) # 80000bd6 <acquire>
    for (int q = 0; q < MLFQ_LEVELS; q++)
    800022c0:	4901                	li	s2,0
          p->state = RUNNING; // Set state to RUNNING
    800022c2:	4b11                	li	s6,4
    800022c4:	b7e1                	j	8000228c <scheduler+0x110>

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
    800022d8:	922080e7          	jalr	-1758(ra) # 80001bf6 <myproc>
    800022dc:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	87e080e7          	jalr	-1922(ra) # 80000b5c <holding>
    800022e6:	c93d                	beqz	a0,8000235c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022e8:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022ea:	2781                	sext.w	a5,a5
    800022ec:	079e                	slli	a5,a5,0x7
    800022ee:	0000f717          	auipc	a4,0xf
    800022f2:	8d270713          	addi	a4,a4,-1838 # 80010bc0 <mlfq>
    800022f6:	97ba                	add	a5,a5,a4
    800022f8:	1107a703          	lw	a4,272(a5)
    800022fc:	4785                	li	a5,1
    800022fe:	06f71763          	bne	a4,a5,8000236c <sched+0xa6>
  if (p->state == RUNNING)
    80002302:	4c98                	lw	a4,24(s1)
    80002304:	4791                	li	a5,4
    80002306:	06f70b63          	beq	a4,a5,8000237c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000230a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000230e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002310:	efb5                	bnez	a5,8000238c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002312:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002314:	0000f917          	auipc	s2,0xf
    80002318:	8ac90913          	addi	s2,s2,-1876 # 80010bc0 <mlfq>
    8000231c:	2781                	sext.w	a5,a5
    8000231e:	079e                	slli	a5,a5,0x7
    80002320:	97ca                	add	a5,a5,s2
    80002322:	1147a983          	lw	s3,276(a5)
    80002326:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002328:	2781                	sext.w	a5,a5
    8000232a:	079e                	slli	a5,a5,0x7
    8000232c:	0000f597          	auipc	a1,0xf
    80002330:	93458593          	addi	a1,a1,-1740 # 80010c60 <cpus+0x8>
    80002334:	95be                	add	a1,a1,a5
    80002336:	06048513          	addi	a0,s1,96
    8000233a:	00001097          	auipc	ra,0x1
    8000233e:	876080e7          	jalr	-1930(ra) # 80002bb0 <swtch>
    80002342:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002344:	2781                	sext.w	a5,a5
    80002346:	079e                	slli	a5,a5,0x7
    80002348:	97ca                	add	a5,a5,s2
    8000234a:	1137aa23          	sw	s3,276(a5)
}
    8000234e:	70a2                	ld	ra,40(sp)
    80002350:	7402                	ld	s0,32(sp)
    80002352:	64e2                	ld	s1,24(sp)
    80002354:	6942                	ld	s2,16(sp)
    80002356:	69a2                	ld	s3,8(sp)
    80002358:	6145                	addi	sp,sp,48
    8000235a:	8082                	ret
    panic("sched p->lock");
    8000235c:	00006517          	auipc	a0,0x6
    80002360:	f0450513          	addi	a0,a0,-252 # 80008260 <digits+0x220>
    80002364:	ffffe097          	auipc	ra,0xffffe
    80002368:	1da080e7          	jalr	474(ra) # 8000053e <panic>
    panic("sched locks");
    8000236c:	00006517          	auipc	a0,0x6
    80002370:	f0450513          	addi	a0,a0,-252 # 80008270 <digits+0x230>
    80002374:	ffffe097          	auipc	ra,0xffffe
    80002378:	1ca080e7          	jalr	458(ra) # 8000053e <panic>
    panic("sched running");
    8000237c:	00006517          	auipc	a0,0x6
    80002380:	f0450513          	addi	a0,a0,-252 # 80008280 <digits+0x240>
    80002384:	ffffe097          	auipc	ra,0xffffe
    80002388:	1ba080e7          	jalr	442(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000238c:	00006517          	auipc	a0,0x6
    80002390:	f0450513          	addi	a0,a0,-252 # 80008290 <digits+0x250>
    80002394:	ffffe097          	auipc	ra,0xffffe
    80002398:	1aa080e7          	jalr	426(ra) # 8000053e <panic>

000000008000239c <yield>:
{
    8000239c:	1101                	addi	sp,sp,-32
    8000239e:	ec06                	sd	ra,24(sp)
    800023a0:	e822                	sd	s0,16(sp)
    800023a2:	e426                	sd	s1,8(sp)
    800023a4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023a6:	00000097          	auipc	ra,0x0
    800023aa:	850080e7          	jalr	-1968(ra) # 80001bf6 <myproc>
    800023ae:	84aa                	mv	s1,a0
  acquire(&mlfq.lock); // Acquire MLFQ lock
    800023b0:	0000f517          	auipc	a0,0xf
    800023b4:	81050513          	addi	a0,a0,-2032 # 80010bc0 <mlfq>
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	81e080e7          	jalr	-2018(ra) # 80000bd6 <acquire>
  acquire(&p->lock);   // Acquire the process lock
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	814080e7          	jalr	-2028(ra) # 80000bd6 <acquire>
  if (p->state == RUNNING)
    800023ca:	4c98                	lw	a4,24(s1)
    800023cc:	4791                	li	a5,4
    800023ce:	02f70863          	beq	a4,a5,800023fe <yield+0x62>
  release(&mlfq.lock); // Release MLFQ lock
    800023d2:	0000e517          	auipc	a0,0xe
    800023d6:	7ee50513          	addi	a0,a0,2030 # 80010bc0 <mlfq>
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	8b0080e7          	jalr	-1872(ra) # 80000c8a <release>
  sched(); // Call scheduler
    800023e2:	00000097          	auipc	ra,0x0
    800023e6:	ee4080e7          	jalr	-284(ra) # 800022c6 <sched>
  release(&p->lock);   // Release the process lock before switching
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	89e080e7          	jalr	-1890(ra) # 80000c8a <release>
}
    800023f4:	60e2                	ld	ra,24(sp)
    800023f6:	6442                	ld	s0,16(sp)
    800023f8:	64a2                	ld	s1,8(sp)
    800023fa:	6105                	addi	sp,sp,32
    800023fc:	8082                	ret
    p->state = RUNNABLE;  // Set to RUNNABLE
    800023fe:	478d                	li	a5,3
    80002400:	cc9c                	sw	a5,24(s1)
    p->remaining_ticks--; // Decrement remaining ticks
    80002402:	3304a783          	lw	a5,816(s1)
    80002406:	37fd                	addiw	a5,a5,-1
    80002408:	0007871b          	sext.w	a4,a5
    8000240c:	32f4a823          	sw	a5,816(s1)
    if (p->remaining_ticks <= 0)
    80002410:	00e05a63          	blez	a4,80002424 <yield+0x88>
    enqueue(p, p->priority); // Enqueue the process based on its priority
    80002414:	32c4a583          	lw	a1,812(s1)
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	486080e7          	jalr	1158(ra) # 800018a0 <enqueue>
    80002422:	bf45                	j	800023d2 <yield+0x36>
      if (p->priority < MLFQ_LEVELS - 1)
    80002424:	32c4a783          	lw	a5,812(s1)
    80002428:	4709                	li	a4,2
    8000242a:	00f74563          	blt	a4,a5,80002434 <yield+0x98>
        p->priority++;
    8000242e:	2785                	addiw	a5,a5,1
    80002430:	32f4a623          	sw	a5,812(s1)
      p->remaining_ticks = mlfq.time_slices[p->priority]; // Reset remaining ticks
    80002434:	32c4a783          	lw	a5,812(s1)
    80002438:	07d1                	addi	a5,a5,20
    8000243a:	078a                	slli	a5,a5,0x2
    8000243c:	0000e717          	auipc	a4,0xe
    80002440:	78470713          	addi	a4,a4,1924 # 80010bc0 <mlfq>
    80002444:	97ba                	add	a5,a5,a4
    80002446:	479c                	lw	a5,8(a5)
    80002448:	32f4a823          	sw	a5,816(s1)
    8000244c:	b7e1                	j	80002414 <yield+0x78>

000000008000244e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000244e:	7179                	addi	sp,sp,-48
    80002450:	f406                	sd	ra,40(sp)
    80002452:	f022                	sd	s0,32(sp)
    80002454:	ec26                	sd	s1,24(sp)
    80002456:	e84a                	sd	s2,16(sp)
    80002458:	e44e                	sd	s3,8(sp)
    8000245a:	1800                	addi	s0,sp,48
    8000245c:	89aa                	mv	s3,a0
    8000245e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	796080e7          	jalr	1942(ra) # 80001bf6 <myproc>
    80002468:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000246a:	ffffe097          	auipc	ra,0xffffe
    8000246e:	76c080e7          	jalr	1900(ra) # 80000bd6 <acquire>
  release(lk);
    80002472:	854a                	mv	a0,s2
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	816080e7          	jalr	-2026(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000247c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002480:	4789                	li	a5,2
    80002482:	cc9c                	sw	a5,24(s1)

#ifdef MLFQ
  // acquire(&mlfq.lock);
  mlfq_remove(p, p->priority);
    80002484:	32c4a583          	lw	a1,812(s1)
    80002488:	8526                	mv	a0,s1
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	546080e7          	jalr	1350(ra) # 800019d0 <mlfq_remove>
  // release(&mlfq.lock);
#endif

  sched();
    80002492:	00000097          	auipc	ra,0x0
    80002496:	e34080e7          	jalr	-460(ra) # 800022c6 <sched>

  // Tidy up.
  p->chan = 0;
    8000249a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7ea080e7          	jalr	2026(ra) # 80000c8a <release>
  acquire(lk);
    800024a8:	854a                	mv	a0,s2
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	72c080e7          	jalr	1836(ra) # 80000bd6 <acquire>
}
    800024b2:	70a2                	ld	ra,40(sp)
    800024b4:	7402                	ld	s0,32(sp)
    800024b6:	64e2                	ld	s1,24(sp)
    800024b8:	6942                	ld	s2,16(sp)
    800024ba:	69a2                	ld	s3,8(sp)
    800024bc:	6145                	addi	sp,sp,48
    800024be:	8082                	ret

00000000800024c0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800024c0:	7139                	addi	sp,sp,-64
    800024c2:	fc06                	sd	ra,56(sp)
    800024c4:	f822                	sd	s0,48(sp)
    800024c6:	f426                	sd	s1,40(sp)
    800024c8:	f04a                	sd	s2,32(sp)
    800024ca:	ec4e                	sd	s3,24(sp)
    800024cc:	e852                	sd	s4,16(sp)
    800024ce:	e456                	sd	s5,8(sp)
    800024d0:	e05a                	sd	s6,0(sp)
    800024d2:	0080                	addi	s0,sp,64
    800024d4:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800024d6:	0000f497          	auipc	s1,0xf
    800024da:	b8248493          	addi	s1,s1,-1150 # 80011058 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800024de:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800024e0:	4b0d                	li	s6,3
#ifdef MLFQ
        acquire(&mlfq.lock);
    800024e2:	0000ea97          	auipc	s5,0xe
    800024e6:	6dea8a93          	addi	s5,s5,1758 # 80010bc0 <mlfq>
  for (p = proc; p < &proc[NPROC]; p++)
    800024ea:	0001c917          	auipc	s2,0x1c
    800024ee:	b6e90913          	addi	s2,s2,-1170 # 8001e058 <tickslock>
    800024f2:	a811                	j	80002506 <wakeup+0x46>
        enqueue(p, p->priority);
        release(&mlfq.lock);
#endif
      }
      release(&p->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	794080e7          	jalr	1940(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800024fe:	34048493          	addi	s1,s1,832
    80002502:	05248763          	beq	s1,s2,80002550 <wakeup+0x90>
    if (p != myproc())
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	6f0080e7          	jalr	1776(ra) # 80001bf6 <myproc>
    8000250e:	fea488e3          	beq	s1,a0,800024fe <wakeup+0x3e>
      acquire(&p->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	6c2080e7          	jalr	1730(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000251c:	4c9c                	lw	a5,24(s1)
    8000251e:	fd379be3          	bne	a5,s3,800024f4 <wakeup+0x34>
    80002522:	709c                	ld	a5,32(s1)
    80002524:	fd4798e3          	bne	a5,s4,800024f4 <wakeup+0x34>
        p->state = RUNNABLE;
    80002528:	0164ac23          	sw	s6,24(s1)
        acquire(&mlfq.lock);
    8000252c:	8556                	mv	a0,s5
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	6a8080e7          	jalr	1704(ra) # 80000bd6 <acquire>
        enqueue(p, p->priority);
    80002536:	32c4a583          	lw	a1,812(s1)
    8000253a:	8526                	mv	a0,s1
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	364080e7          	jalr	868(ra) # 800018a0 <enqueue>
        release(&mlfq.lock);
    80002544:	8556                	mv	a0,s5
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	744080e7          	jalr	1860(ra) # 80000c8a <release>
    8000254e:	b75d                	j	800024f4 <wakeup+0x34>
    }
  }
}
    80002550:	70e2                	ld	ra,56(sp)
    80002552:	7442                	ld	s0,48(sp)
    80002554:	74a2                	ld	s1,40(sp)
    80002556:	7902                	ld	s2,32(sp)
    80002558:	69e2                	ld	s3,24(sp)
    8000255a:	6a42                	ld	s4,16(sp)
    8000255c:	6aa2                	ld	s5,8(sp)
    8000255e:	6b02                	ld	s6,0(sp)
    80002560:	6121                	addi	sp,sp,64
    80002562:	8082                	ret

0000000080002564 <reparent>:
{
    80002564:	7179                	addi	sp,sp,-48
    80002566:	f406                	sd	ra,40(sp)
    80002568:	f022                	sd	s0,32(sp)
    8000256a:	ec26                	sd	s1,24(sp)
    8000256c:	e84a                	sd	s2,16(sp)
    8000256e:	e44e                	sd	s3,8(sp)
    80002570:	e052                	sd	s4,0(sp)
    80002572:	1800                	addi	s0,sp,48
    80002574:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002576:	0000f497          	auipc	s1,0xf
    8000257a:	ae248493          	addi	s1,s1,-1310 # 80011058 <proc>
      pp->parent = initproc;
    8000257e:	00006a17          	auipc	s4,0x6
    80002582:	3caa0a13          	addi	s4,s4,970 # 80008948 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002586:	0001c997          	auipc	s3,0x1c
    8000258a:	ad298993          	addi	s3,s3,-1326 # 8001e058 <tickslock>
    8000258e:	a029                	j	80002598 <reparent+0x34>
    80002590:	34048493          	addi	s1,s1,832
    80002594:	01348d63          	beq	s1,s3,800025ae <reparent+0x4a>
    if (pp->parent == p)
    80002598:	7c9c                	ld	a5,56(s1)
    8000259a:	ff279be3          	bne	a5,s2,80002590 <reparent+0x2c>
      pp->parent = initproc;
    8000259e:	000a3503          	ld	a0,0(s4)
    800025a2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800025a4:	00000097          	auipc	ra,0x0
    800025a8:	f1c080e7          	jalr	-228(ra) # 800024c0 <wakeup>
    800025ac:	b7d5                	j	80002590 <reparent+0x2c>
}
    800025ae:	70a2                	ld	ra,40(sp)
    800025b0:	7402                	ld	s0,32(sp)
    800025b2:	64e2                	ld	s1,24(sp)
    800025b4:	6942                	ld	s2,16(sp)
    800025b6:	69a2                	ld	s3,8(sp)
    800025b8:	6a02                	ld	s4,0(sp)
    800025ba:	6145                	addi	sp,sp,48
    800025bc:	8082                	ret

00000000800025be <exit>:
{
    800025be:	7179                	addi	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	e052                	sd	s4,0(sp)
    800025cc:	1800                	addi	s0,sp,48
    800025ce:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025d0:	fffff097          	auipc	ra,0xfffff
    800025d4:	626080e7          	jalr	1574(ra) # 80001bf6 <myproc>
    800025d8:	89aa                	mv	s3,a0
  if (p == initproc)
    800025da:	00006797          	auipc	a5,0x6
    800025de:	36e7b783          	ld	a5,878(a5) # 80008948 <initproc>
    800025e2:	0d050493          	addi	s1,a0,208
    800025e6:	15050913          	addi	s2,a0,336
    800025ea:	02a79363          	bne	a5,a0,80002610 <exit+0x52>
    panic("init exiting");
    800025ee:	00006517          	auipc	a0,0x6
    800025f2:	cba50513          	addi	a0,a0,-838 # 800082a8 <digits+0x268>
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      fileclose(f);
    800025fe:	00002097          	auipc	ra,0x2
    80002602:	6e0080e7          	jalr	1760(ra) # 80004cde <fileclose>
      p->ofile[fd] = 0;
    80002606:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000260a:	04a1                	addi	s1,s1,8
    8000260c:	01248563          	beq	s1,s2,80002616 <exit+0x58>
    if (p->ofile[fd])
    80002610:	6088                	ld	a0,0(s1)
    80002612:	f575                	bnez	a0,800025fe <exit+0x40>
    80002614:	bfdd                	j	8000260a <exit+0x4c>
  begin_op();
    80002616:	00002097          	auipc	ra,0x2
    8000261a:	1fc080e7          	jalr	508(ra) # 80004812 <begin_op>
  iput(p->cwd);
    8000261e:	1509b503          	ld	a0,336(s3)
    80002622:	00002097          	auipc	ra,0x2
    80002626:	9e8080e7          	jalr	-1560(ra) # 8000400a <iput>
  end_op();
    8000262a:	00002097          	auipc	ra,0x2
    8000262e:	268080e7          	jalr	616(ra) # 80004892 <end_op>
  p->cwd = 0;
    80002632:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002636:	0000e497          	auipc	s1,0xe
    8000263a:	60a48493          	addi	s1,s1,1546 # 80010c40 <wait_lock>
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	596080e7          	jalr	1430(ra) # 80000bd6 <acquire>
  reparent(p);
    80002648:	854e                	mv	a0,s3
    8000264a:	00000097          	auipc	ra,0x0
    8000264e:	f1a080e7          	jalr	-230(ra) # 80002564 <reparent>
  wakeup(p->parent);
    80002652:	0389b503          	ld	a0,56(s3)
    80002656:	00000097          	auipc	ra,0x0
    8000265a:	e6a080e7          	jalr	-406(ra) # 800024c0 <wakeup>
  acquire(&p->lock);
    8000265e:	854e                	mv	a0,s3
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	576080e7          	jalr	1398(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002668:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000266c:	4795                	li	a5,5
    8000266e:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002672:	00006797          	auipc	a5,0x6
    80002676:	2e27a783          	lw	a5,738(a5) # 80008954 <ticks>
    8000267a:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000267e:	8526                	mv	a0,s1
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	60a080e7          	jalr	1546(ra) # 80000c8a <release>
  sched();
    80002688:	00000097          	auipc	ra,0x0
    8000268c:	c3e080e7          	jalr	-962(ra) # 800022c6 <sched>
  panic("zombie exit");
    80002690:	00006517          	auipc	a0,0x6
    80002694:	c2850513          	addi	a0,a0,-984 # 800082b8 <digits+0x278>
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	ea6080e7          	jalr	-346(ra) # 8000053e <panic>

00000000800026a0 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026a0:	7179                	addi	sp,sp,-48
    800026a2:	f406                	sd	ra,40(sp)
    800026a4:	f022                	sd	s0,32(sp)
    800026a6:	ec26                	sd	s1,24(sp)
    800026a8:	e84a                	sd	s2,16(sp)
    800026aa:	e44e                	sd	s3,8(sp)
    800026ac:	1800                	addi	s0,sp,48
    800026ae:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800026b0:	0000f497          	auipc	s1,0xf
    800026b4:	9a848493          	addi	s1,s1,-1624 # 80011058 <proc>
    800026b8:	0001c997          	auipc	s3,0x1c
    800026bc:	9a098993          	addi	s3,s3,-1632 # 8001e058 <tickslock>
  {
    acquire(&p->lock);
    800026c0:	8526                	mv	a0,s1
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	514080e7          	jalr	1300(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800026ca:	589c                	lw	a5,48(s1)
    800026cc:	01278d63          	beq	a5,s2,800026e6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026d0:	8526                	mv	a0,s1
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	5b8080e7          	jalr	1464(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026da:	34048493          	addi	s1,s1,832
    800026de:	ff3491e3          	bne	s1,s3,800026c0 <kill+0x20>
  }
  return -1;
    800026e2:	557d                	li	a0,-1
    800026e4:	a829                	j	800026fe <kill+0x5e>
      p->killed = 1;
    800026e6:	4785                	li	a5,1
    800026e8:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800026ea:	4c98                	lw	a4,24(s1)
    800026ec:	4789                	li	a5,2
    800026ee:	00f70f63          	beq	a4,a5,8000270c <kill+0x6c>
      release(&p->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	596080e7          	jalr	1430(ra) # 80000c8a <release>
      return 0;
    800026fc:	4501                	li	a0,0
}
    800026fe:	70a2                	ld	ra,40(sp)
    80002700:	7402                	ld	s0,32(sp)
    80002702:	64e2                	ld	s1,24(sp)
    80002704:	6942                	ld	s2,16(sp)
    80002706:	69a2                	ld	s3,8(sp)
    80002708:	6145                	addi	sp,sp,48
    8000270a:	8082                	ret
        p->state = RUNNABLE;
    8000270c:	478d                	li	a5,3
    8000270e:	cc9c                	sw	a5,24(s1)
    80002710:	b7cd                	j	800026f2 <kill+0x52>

0000000080002712 <setkilled>:

void setkilled(struct proc *p)
{
    80002712:	1101                	addi	sp,sp,-32
    80002714:	ec06                	sd	ra,24(sp)
    80002716:	e822                	sd	s0,16(sp)
    80002718:	e426                	sd	s1,8(sp)
    8000271a:	1000                	addi	s0,sp,32
    8000271c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	4b8080e7          	jalr	1208(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002726:	4785                	li	a5,1
    80002728:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	55e080e7          	jalr	1374(ra) # 80000c8a <release>
}
    80002734:	60e2                	ld	ra,24(sp)
    80002736:	6442                	ld	s0,16(sp)
    80002738:	64a2                	ld	s1,8(sp)
    8000273a:	6105                	addi	sp,sp,32
    8000273c:	8082                	ret

000000008000273e <killed>:

int killed(struct proc *p)
{
    8000273e:	1101                	addi	sp,sp,-32
    80002740:	ec06                	sd	ra,24(sp)
    80002742:	e822                	sd	s0,16(sp)
    80002744:	e426                	sd	s1,8(sp)
    80002746:	e04a                	sd	s2,0(sp)
    80002748:	1000                	addi	s0,sp,32
    8000274a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	48a080e7          	jalr	1162(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002754:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	530080e7          	jalr	1328(ra) # 80000c8a <release>
  return k;
}
    80002762:	854a                	mv	a0,s2
    80002764:	60e2                	ld	ra,24(sp)
    80002766:	6442                	ld	s0,16(sp)
    80002768:	64a2                	ld	s1,8(sp)
    8000276a:	6902                	ld	s2,0(sp)
    8000276c:	6105                	addi	sp,sp,32
    8000276e:	8082                	ret

0000000080002770 <wait>:
{
    80002770:	715d                	addi	sp,sp,-80
    80002772:	e486                	sd	ra,72(sp)
    80002774:	e0a2                	sd	s0,64(sp)
    80002776:	fc26                	sd	s1,56(sp)
    80002778:	f84a                	sd	s2,48(sp)
    8000277a:	f44e                	sd	s3,40(sp)
    8000277c:	f052                	sd	s4,32(sp)
    8000277e:	ec56                	sd	s5,24(sp)
    80002780:	e85a                	sd	s6,16(sp)
    80002782:	e45e                	sd	s7,8(sp)
    80002784:	e062                	sd	s8,0(sp)
    80002786:	0880                	addi	s0,sp,80
    80002788:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000278a:	fffff097          	auipc	ra,0xfffff
    8000278e:	46c080e7          	jalr	1132(ra) # 80001bf6 <myproc>
    80002792:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002794:	0000e517          	auipc	a0,0xe
    80002798:	4ac50513          	addi	a0,a0,1196 # 80010c40 <wait_lock>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	43a080e7          	jalr	1082(ra) # 80000bd6 <acquire>
    havekids = 0;
    800027a4:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800027a6:	4a15                	li	s4,5
        havekids = 1;
    800027a8:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800027aa:	0001c997          	auipc	s3,0x1c
    800027ae:	8ae98993          	addi	s3,s3,-1874 # 8001e058 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027b2:	0000ec17          	auipc	s8,0xe
    800027b6:	48ec0c13          	addi	s8,s8,1166 # 80010c40 <wait_lock>
    havekids = 0;
    800027ba:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800027bc:	0000f497          	auipc	s1,0xf
    800027c0:	89c48493          	addi	s1,s1,-1892 # 80011058 <proc>
    800027c4:	a069                	j	8000284e <wait+0xde>
          pid = pp->pid;
    800027c6:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800027ca:	040b1363          	bnez	s6,80002810 <wait+0xa0>
          for (int i = 0; i < NELEM(pp->syscall_count); i++)
    800027ce:	17490793          	addi	a5,s2,372
    800027d2:	17448693          	addi	a3,s1,372
    800027d6:	1f490913          	addi	s2,s2,500
            p->syscall_count[i] += pp->syscall_count[i];
    800027da:	4398                	lw	a4,0(a5)
    800027dc:	4290                	lw	a2,0(a3)
    800027de:	9f31                	addw	a4,a4,a2
    800027e0:	c398                	sw	a4,0(a5)
          for (int i = 0; i < NELEM(pp->syscall_count); i++)
    800027e2:	0791                	addi	a5,a5,4
    800027e4:	0691                	addi	a3,a3,4
    800027e6:	ff279ae3          	bne	a5,s2,800027da <wait+0x6a>
          freeproc(pp);
    800027ea:	8526                	mv	a0,s1
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	5bc080e7          	jalr	1468(ra) # 80001da8 <freeproc>
          release(&pp->lock);
    800027f4:	8526                	mv	a0,s1
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	494080e7          	jalr	1172(ra) # 80000c8a <release>
          release(&wait_lock);
    800027fe:	0000e517          	auipc	a0,0xe
    80002802:	44250513          	addi	a0,a0,1090 # 80010c40 <wait_lock>
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	484080e7          	jalr	1156(ra) # 80000c8a <release>
          return pid;
    8000280e:	a051                	j	80002892 <wait+0x122>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002810:	4691                	li	a3,4
    80002812:	02c48613          	addi	a2,s1,44
    80002816:	85da                	mv	a1,s6
    80002818:	05093503          	ld	a0,80(s2)
    8000281c:	fffff097          	auipc	ra,0xfffff
    80002820:	e4c080e7          	jalr	-436(ra) # 80001668 <copyout>
    80002824:	fa0555e3          	bgez	a0,800027ce <wait+0x5e>
            release(&pp->lock);
    80002828:	8526                	mv	a0,s1
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	460080e7          	jalr	1120(ra) # 80000c8a <release>
            release(&wait_lock);
    80002832:	0000e517          	auipc	a0,0xe
    80002836:	40e50513          	addi	a0,a0,1038 # 80010c40 <wait_lock>
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	450080e7          	jalr	1104(ra) # 80000c8a <release>
            return -1;
    80002842:	59fd                	li	s3,-1
    80002844:	a0b9                	j	80002892 <wait+0x122>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002846:	34048493          	addi	s1,s1,832
    8000284a:	03348463          	beq	s1,s3,80002872 <wait+0x102>
      if (pp->parent == p)
    8000284e:	7c9c                	ld	a5,56(s1)
    80002850:	ff279be3          	bne	a5,s2,80002846 <wait+0xd6>
        acquire(&pp->lock);
    80002854:	8526                	mv	a0,s1
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	380080e7          	jalr	896(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    8000285e:	4c9c                	lw	a5,24(s1)
    80002860:	f74783e3          	beq	a5,s4,800027c6 <wait+0x56>
        release(&pp->lock);
    80002864:	8526                	mv	a0,s1
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	424080e7          	jalr	1060(ra) # 80000c8a <release>
        havekids = 1;
    8000286e:	8756                	mv	a4,s5
    80002870:	bfd9                	j	80002846 <wait+0xd6>
    if (!havekids || killed(p))
    80002872:	c719                	beqz	a4,80002880 <wait+0x110>
    80002874:	854a                	mv	a0,s2
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	ec8080e7          	jalr	-312(ra) # 8000273e <killed>
    8000287e:	c51d                	beqz	a0,800028ac <wait+0x13c>
      release(&wait_lock);
    80002880:	0000e517          	auipc	a0,0xe
    80002884:	3c050513          	addi	a0,a0,960 # 80010c40 <wait_lock>
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	402080e7          	jalr	1026(ra) # 80000c8a <release>
      return -1;
    80002890:	59fd                	li	s3,-1
}
    80002892:	854e                	mv	a0,s3
    80002894:	60a6                	ld	ra,72(sp)
    80002896:	6406                	ld	s0,64(sp)
    80002898:	74e2                	ld	s1,56(sp)
    8000289a:	7942                	ld	s2,48(sp)
    8000289c:	79a2                	ld	s3,40(sp)
    8000289e:	7a02                	ld	s4,32(sp)
    800028a0:	6ae2                	ld	s5,24(sp)
    800028a2:	6b42                	ld	s6,16(sp)
    800028a4:	6ba2                	ld	s7,8(sp)
    800028a6:	6c02                	ld	s8,0(sp)
    800028a8:	6161                	addi	sp,sp,80
    800028aa:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028ac:	85e2                	mv	a1,s8
    800028ae:	854a                	mv	a0,s2
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	b9e080e7          	jalr	-1122(ra) # 8000244e <sleep>
    havekids = 0;
    800028b8:	b709                	j	800027ba <wait+0x4a>

00000000800028ba <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800028ba:	7179                	addi	sp,sp,-48
    800028bc:	f406                	sd	ra,40(sp)
    800028be:	f022                	sd	s0,32(sp)
    800028c0:	ec26                	sd	s1,24(sp)
    800028c2:	e84a                	sd	s2,16(sp)
    800028c4:	e44e                	sd	s3,8(sp)
    800028c6:	e052                	sd	s4,0(sp)
    800028c8:	1800                	addi	s0,sp,48
    800028ca:	84aa                	mv	s1,a0
    800028cc:	892e                	mv	s2,a1
    800028ce:	89b2                	mv	s3,a2
    800028d0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028d2:	fffff097          	auipc	ra,0xfffff
    800028d6:	324080e7          	jalr	804(ra) # 80001bf6 <myproc>
  if (user_dst)
    800028da:	c08d                	beqz	s1,800028fc <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800028dc:	86d2                	mv	a3,s4
    800028de:	864e                	mv	a2,s3
    800028e0:	85ca                	mv	a1,s2
    800028e2:	6928                	ld	a0,80(a0)
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	d84080e7          	jalr	-636(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800028ec:	70a2                	ld	ra,40(sp)
    800028ee:	7402                	ld	s0,32(sp)
    800028f0:	64e2                	ld	s1,24(sp)
    800028f2:	6942                	ld	s2,16(sp)
    800028f4:	69a2                	ld	s3,8(sp)
    800028f6:	6a02                	ld	s4,0(sp)
    800028f8:	6145                	addi	sp,sp,48
    800028fa:	8082                	ret
    memmove((char *)dst, src, len);
    800028fc:	000a061b          	sext.w	a2,s4
    80002900:	85ce                	mv	a1,s3
    80002902:	854a                	mv	a0,s2
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	42a080e7          	jalr	1066(ra) # 80000d2e <memmove>
    return 0;
    8000290c:	8526                	mv	a0,s1
    8000290e:	bff9                	j	800028ec <either_copyout+0x32>

0000000080002910 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002910:	7179                	addi	sp,sp,-48
    80002912:	f406                	sd	ra,40(sp)
    80002914:	f022                	sd	s0,32(sp)
    80002916:	ec26                	sd	s1,24(sp)
    80002918:	e84a                	sd	s2,16(sp)
    8000291a:	e44e                	sd	s3,8(sp)
    8000291c:	e052                	sd	s4,0(sp)
    8000291e:	1800                	addi	s0,sp,48
    80002920:	892a                	mv	s2,a0
    80002922:	84ae                	mv	s1,a1
    80002924:	89b2                	mv	s3,a2
    80002926:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002928:	fffff097          	auipc	ra,0xfffff
    8000292c:	2ce080e7          	jalr	718(ra) # 80001bf6 <myproc>
  if (user_src)
    80002930:	c08d                	beqz	s1,80002952 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002932:	86d2                	mv	a3,s4
    80002934:	864e                	mv	a2,s3
    80002936:	85ca                	mv	a1,s2
    80002938:	6928                	ld	a0,80(a0)
    8000293a:	fffff097          	auipc	ra,0xfffff
    8000293e:	dba080e7          	jalr	-582(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002942:	70a2                	ld	ra,40(sp)
    80002944:	7402                	ld	s0,32(sp)
    80002946:	64e2                	ld	s1,24(sp)
    80002948:	6942                	ld	s2,16(sp)
    8000294a:	69a2                	ld	s3,8(sp)
    8000294c:	6a02                	ld	s4,0(sp)
    8000294e:	6145                	addi	sp,sp,48
    80002950:	8082                	ret
    memmove(dst, (char *)src, len);
    80002952:	000a061b          	sext.w	a2,s4
    80002956:	85ce                	mv	a1,s3
    80002958:	854a                	mv	a0,s2
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	3d4080e7          	jalr	980(ra) # 80000d2e <memmove>
    return 0;
    80002962:	8526                	mv	a0,s1
    80002964:	bff9                	j	80002942 <either_copyin+0x32>

0000000080002966 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002966:	7139                	addi	sp,sp,-64
    80002968:	fc06                	sd	ra,56(sp)
    8000296a:	f822                	sd	s0,48(sp)
    8000296c:	f426                	sd	s1,40(sp)
    8000296e:	f04a                	sd	s2,32(sp)
    80002970:	ec4e                	sd	s3,24(sp)
    80002972:	e852                	sd	s4,16(sp)
    80002974:	e456                	sd	s5,8(sp)
    80002976:	e05a                	sd	s6,0(sp)
    80002978:	0080                	addi	s0,sp,64
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000297a:	00005517          	auipc	a0,0x5
    8000297e:	74e50513          	addi	a0,a0,1870 # 800080c8 <digits+0x88>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c06080e7          	jalr	-1018(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000298a:	0000f497          	auipc	s1,0xf
    8000298e:	82648493          	addi	s1,s1,-2010 # 800111b0 <proc+0x158>
    80002992:	0001c917          	auipc	s2,0x1c
    80002996:	81e90913          	addi	s2,s2,-2018 # 8001e1b0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000299a:	4a95                	li	s5,5
      state = states[p->state];
    else
      state = "???";
    8000299c:	00006997          	auipc	s3,0x6
    800029a0:	92c98993          	addi	s3,s3,-1748 # 800082c8 <digits+0x288>
    printf("%d %s %s priority: %d remaining_ticks: %d\n", p->pid, state, p->name, p->priority, p->remaining_ticks);
    800029a4:	00006a17          	auipc	s4,0x6
    800029a8:	92ca0a13          	addi	s4,s4,-1748 # 800082d0 <digits+0x290>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029ac:	00006b17          	auipc	s6,0x6
    800029b0:	984b0b13          	addi	s6,s6,-1660 # 80008330 <states.0>
    800029b4:	a005                	j	800029d4 <procdump+0x6e>
    printf("%d %s %s priority: %d remaining_ticks: %d\n", p->pid, state, p->name, p->priority, p->remaining_ticks);
    800029b6:	1d86a783          	lw	a5,472(a3)
    800029ba:	1d46a703          	lw	a4,468(a3)
    800029be:	ed86a583          	lw	a1,-296(a3)
    800029c2:	8552                	mv	a0,s4
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bc4080e7          	jalr	-1084(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800029cc:	34048493          	addi	s1,s1,832
    800029d0:	03248163          	beq	s1,s2,800029f2 <procdump+0x8c>
    if (p->state == UNUSED)
    800029d4:	86a6                	mv	a3,s1
    800029d6:	ec04a783          	lw	a5,-320(s1)
    800029da:	dbed                	beqz	a5,800029cc <procdump+0x66>
      state = "???";
    800029dc:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029de:	fcfaece3          	bltu	s5,a5,800029b6 <procdump+0x50>
    800029e2:	1782                	slli	a5,a5,0x20
    800029e4:	9381                	srli	a5,a5,0x20
    800029e6:	078e                	slli	a5,a5,0x3
    800029e8:	97da                	add	a5,a5,s6
    800029ea:	6390                	ld	a2,0(a5)
    800029ec:	f669                	bnez	a2,800029b6 <procdump+0x50>
      state = "???";
    800029ee:	864e                	mv	a2,s3
    800029f0:	b7d9                	j	800029b6 <procdump+0x50>
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
#endif
}
    800029f2:	70e2                	ld	ra,56(sp)
    800029f4:	7442                	ld	s0,48(sp)
    800029f6:	74a2                	ld	s1,40(sp)
    800029f8:	7902                	ld	s2,32(sp)
    800029fa:	69e2                	ld	s3,24(sp)
    800029fc:	6a42                	ld	s4,16(sp)
    800029fe:	6aa2                	ld	s5,8(sp)
    80002a00:	6b02                	ld	s6,0(sp)
    80002a02:	6121                	addi	sp,sp,64
    80002a04:	8082                	ret

0000000080002a06 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002a06:	711d                	addi	sp,sp,-96
    80002a08:	ec86                	sd	ra,88(sp)
    80002a0a:	e8a2                	sd	s0,80(sp)
    80002a0c:	e4a6                	sd	s1,72(sp)
    80002a0e:	e0ca                	sd	s2,64(sp)
    80002a10:	fc4e                	sd	s3,56(sp)
    80002a12:	f852                	sd	s4,48(sp)
    80002a14:	f456                	sd	s5,40(sp)
    80002a16:	f05a                	sd	s6,32(sp)
    80002a18:	ec5e                	sd	s7,24(sp)
    80002a1a:	e862                	sd	s8,16(sp)
    80002a1c:	e466                	sd	s9,8(sp)
    80002a1e:	e06a                	sd	s10,0(sp)
    80002a20:	1080                	addi	s0,sp,96
    80002a22:	8b2a                	mv	s6,a0
    80002a24:	8bae                	mv	s7,a1
    80002a26:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	1ce080e7          	jalr	462(ra) # 80001bf6 <myproc>
    80002a30:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002a32:	0000e517          	auipc	a0,0xe
    80002a36:	20e50513          	addi	a0,a0,526 # 80010c40 <wait_lock>
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	19c080e7          	jalr	412(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002a42:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002a44:	4a15                	li	s4,5
        havekids = 1;
    80002a46:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002a48:	0001b997          	auipc	s3,0x1b
    80002a4c:	61098993          	addi	s3,s3,1552 # 8001e058 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a50:	0000ed17          	auipc	s10,0xe
    80002a54:	1f0d0d13          	addi	s10,s10,496 # 80010c40 <wait_lock>
    havekids = 0;
    80002a58:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002a5a:	0000e497          	auipc	s1,0xe
    80002a5e:	5fe48493          	addi	s1,s1,1534 # 80011058 <proc>
    80002a62:	a059                	j	80002ae8 <waitx+0xe2>
          pid = np->pid;
    80002a64:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002a68:	1684a703          	lw	a4,360(s1)
    80002a6c:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002a70:	16c4a783          	lw	a5,364(s1)
    80002a74:	9f3d                	addw	a4,a4,a5
    80002a76:	1704a783          	lw	a5,368(s1)
    80002a7a:	9f99                	subw	a5,a5,a4
    80002a7c:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffd5bc8>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002a80:	000b0e63          	beqz	s6,80002a9c <waitx+0x96>
    80002a84:	4691                	li	a3,4
    80002a86:	02c48613          	addi	a2,s1,44
    80002a8a:	85da                	mv	a1,s6
    80002a8c:	05093503          	ld	a0,80(s2)
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	bd8080e7          	jalr	-1064(ra) # 80001668 <copyout>
    80002a98:	02054563          	bltz	a0,80002ac2 <waitx+0xbc>
          freeproc(np);
    80002a9c:	8526                	mv	a0,s1
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	30a080e7          	jalr	778(ra) # 80001da8 <freeproc>
          release(&np->lock);
    80002aa6:	8526                	mv	a0,s1
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	1e2080e7          	jalr	482(ra) # 80000c8a <release>
          release(&wait_lock);
    80002ab0:	0000e517          	auipc	a0,0xe
    80002ab4:	19050513          	addi	a0,a0,400 # 80010c40 <wait_lock>
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	1d2080e7          	jalr	466(ra) # 80000c8a <release>
          return pid;
    80002ac0:	a09d                	j	80002b26 <waitx+0x120>
            release(&np->lock);
    80002ac2:	8526                	mv	a0,s1
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	1c6080e7          	jalr	454(ra) # 80000c8a <release>
            release(&wait_lock);
    80002acc:	0000e517          	auipc	a0,0xe
    80002ad0:	17450513          	addi	a0,a0,372 # 80010c40 <wait_lock>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	1b6080e7          	jalr	438(ra) # 80000c8a <release>
            return -1;
    80002adc:	59fd                	li	s3,-1
    80002ade:	a0a1                	j	80002b26 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002ae0:	34048493          	addi	s1,s1,832
    80002ae4:	03348463          	beq	s1,s3,80002b0c <waitx+0x106>
      if (np->parent == p)
    80002ae8:	7c9c                	ld	a5,56(s1)
    80002aea:	ff279be3          	bne	a5,s2,80002ae0 <waitx+0xda>
        acquire(&np->lock);
    80002aee:	8526                	mv	a0,s1
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	0e6080e7          	jalr	230(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002af8:	4c9c                	lw	a5,24(s1)
    80002afa:	f74785e3          	beq	a5,s4,80002a64 <waitx+0x5e>
        release(&np->lock);
    80002afe:	8526                	mv	a0,s1
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	18a080e7          	jalr	394(ra) # 80000c8a <release>
        havekids = 1;
    80002b08:	8756                	mv	a4,s5
    80002b0a:	bfd9                	j	80002ae0 <waitx+0xda>
    if (!havekids || p->killed)
    80002b0c:	c701                	beqz	a4,80002b14 <waitx+0x10e>
    80002b0e:	02892783          	lw	a5,40(s2)
    80002b12:	cb8d                	beqz	a5,80002b44 <waitx+0x13e>
      release(&wait_lock);
    80002b14:	0000e517          	auipc	a0,0xe
    80002b18:	12c50513          	addi	a0,a0,300 # 80010c40 <wait_lock>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	16e080e7          	jalr	366(ra) # 80000c8a <release>
      return -1;
    80002b24:	59fd                	li	s3,-1
  }
}
    80002b26:	854e                	mv	a0,s3
    80002b28:	60e6                	ld	ra,88(sp)
    80002b2a:	6446                	ld	s0,80(sp)
    80002b2c:	64a6                	ld	s1,72(sp)
    80002b2e:	6906                	ld	s2,64(sp)
    80002b30:	79e2                	ld	s3,56(sp)
    80002b32:	7a42                	ld	s4,48(sp)
    80002b34:	7aa2                	ld	s5,40(sp)
    80002b36:	7b02                	ld	s6,32(sp)
    80002b38:	6be2                	ld	s7,24(sp)
    80002b3a:	6c42                	ld	s8,16(sp)
    80002b3c:	6ca2                	ld	s9,8(sp)
    80002b3e:	6d02                	ld	s10,0(sp)
    80002b40:	6125                	addi	sp,sp,96
    80002b42:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b44:	85ea                	mv	a1,s10
    80002b46:	854a                	mv	a0,s2
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	906080e7          	jalr	-1786(ra) # 8000244e <sleep>
    havekids = 0;
    80002b50:	b721                	j	80002a58 <waitx+0x52>

0000000080002b52 <update_time>:

void update_time()
{
    80002b52:	7179                	addi	sp,sp,-48
    80002b54:	f406                	sd	ra,40(sp)
    80002b56:	f022                	sd	s0,32(sp)
    80002b58:	ec26                	sd	s1,24(sp)
    80002b5a:	e84a                	sd	s2,16(sp)
    80002b5c:	e44e                	sd	s3,8(sp)
    80002b5e:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002b60:	0000e497          	auipc	s1,0xe
    80002b64:	4f848493          	addi	s1,s1,1272 # 80011058 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002b68:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002b6a:	0001b917          	auipc	s2,0x1b
    80002b6e:	4ee90913          	addi	s2,s2,1262 # 8001e058 <tickslock>
    80002b72:	a811                	j	80002b86 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002b74:	8526                	mv	a0,s1
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	114080e7          	jalr	276(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b7e:	34048493          	addi	s1,s1,832
    80002b82:	03248063          	beq	s1,s2,80002ba2 <update_time+0x50>
    acquire(&p->lock);
    80002b86:	8526                	mv	a0,s1
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	04e080e7          	jalr	78(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002b90:	4c9c                	lw	a5,24(s1)
    80002b92:	ff3791e3          	bne	a5,s3,80002b74 <update_time+0x22>
      p->rtime++;
    80002b96:	1684a783          	lw	a5,360(s1)
    80002b9a:	2785                	addiw	a5,a5,1
    80002b9c:	16f4a423          	sw	a5,360(s1)
    80002ba0:	bfd1                	j	80002b74 <update_time+0x22>
  }
    80002ba2:	70a2                	ld	ra,40(sp)
    80002ba4:	7402                	ld	s0,32(sp)
    80002ba6:	64e2                	ld	s1,24(sp)
    80002ba8:	6942                	ld	s2,16(sp)
    80002baa:	69a2                	ld	s3,8(sp)
    80002bac:	6145                	addi	sp,sp,48
    80002bae:	8082                	ret

0000000080002bb0 <swtch>:
    80002bb0:	00153023          	sd	ra,0(a0)
    80002bb4:	00253423          	sd	sp,8(a0)
    80002bb8:	e900                	sd	s0,16(a0)
    80002bba:	ed04                	sd	s1,24(a0)
    80002bbc:	03253023          	sd	s2,32(a0)
    80002bc0:	03353423          	sd	s3,40(a0)
    80002bc4:	03453823          	sd	s4,48(a0)
    80002bc8:	03553c23          	sd	s5,56(a0)
    80002bcc:	05653023          	sd	s6,64(a0)
    80002bd0:	05753423          	sd	s7,72(a0)
    80002bd4:	05853823          	sd	s8,80(a0)
    80002bd8:	05953c23          	sd	s9,88(a0)
    80002bdc:	07a53023          	sd	s10,96(a0)
    80002be0:	07b53423          	sd	s11,104(a0)
    80002be4:	0005b083          	ld	ra,0(a1)
    80002be8:	0085b103          	ld	sp,8(a1)
    80002bec:	6980                	ld	s0,16(a1)
    80002bee:	6d84                	ld	s1,24(a1)
    80002bf0:	0205b903          	ld	s2,32(a1)
    80002bf4:	0285b983          	ld	s3,40(a1)
    80002bf8:	0305ba03          	ld	s4,48(a1)
    80002bfc:	0385ba83          	ld	s5,56(a1)
    80002c00:	0405bb03          	ld	s6,64(a1)
    80002c04:	0485bb83          	ld	s7,72(a1)
    80002c08:	0505bc03          	ld	s8,80(a1)
    80002c0c:	0585bc83          	ld	s9,88(a1)
    80002c10:	0605bd03          	ld	s10,96(a1)
    80002c14:	0685bd83          	ld	s11,104(a1)
    80002c18:	8082                	ret

0000000080002c1a <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002c1a:	1141                	addi	sp,sp,-16
    80002c1c:	e406                	sd	ra,8(sp)
    80002c1e:	e022                	sd	s0,0(sp)
    80002c20:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c22:	00005597          	auipc	a1,0x5
    80002c26:	73e58593          	addi	a1,a1,1854 # 80008360 <states.0+0x30>
    80002c2a:	0001b517          	auipc	a0,0x1b
    80002c2e:	42e50513          	addi	a0,a0,1070 # 8001e058 <tickslock>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	f14080e7          	jalr	-236(ra) # 80000b46 <initlock>
}
    80002c3a:	60a2                	ld	ra,8(sp)
    80002c3c:	6402                	ld	s0,0(sp)
    80002c3e:	0141                	addi	sp,sp,16
    80002c40:	8082                	ret

0000000080002c42 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002c42:	1141                	addi	sp,sp,-16
    80002c44:	e422                	sd	s0,8(sp)
    80002c46:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c48:	00003797          	auipc	a5,0x3
    80002c4c:	6e878793          	addi	a5,a5,1768 # 80006330 <kernelvec>
    80002c50:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c54:	6422                	ld	s0,8(sp)
    80002c56:	0141                	addi	sp,sp,16
    80002c58:	8082                	ret

0000000080002c5a <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002c5a:	1141                	addi	sp,sp,-16
    80002c5c:	e406                	sd	ra,8(sp)
    80002c5e:	e022                	sd	s0,0(sp)
    80002c60:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	f94080e7          	jalr	-108(ra) # 80001bf6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c6e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c70:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c74:	00004617          	auipc	a2,0x4
    80002c78:	38c60613          	addi	a2,a2,908 # 80007000 <_trampoline>
    80002c7c:	00004697          	auipc	a3,0x4
    80002c80:	38468693          	addi	a3,a3,900 # 80007000 <_trampoline>
    80002c84:	8e91                	sub	a3,a3,a2
    80002c86:	040007b7          	lui	a5,0x4000
    80002c8a:	17fd                	addi	a5,a5,-1
    80002c8c:	07b2                	slli	a5,a5,0xc
    80002c8e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c90:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c94:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c96:	180026f3          	csrr	a3,satp
    80002c9a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c9c:	6d38                	ld	a4,88(a0)
    80002c9e:	6134                	ld	a3,64(a0)
    80002ca0:	6585                	lui	a1,0x1
    80002ca2:	96ae                	add	a3,a3,a1
    80002ca4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ca6:	6d38                	ld	a4,88(a0)
    80002ca8:	00000697          	auipc	a3,0x0
    80002cac:	13e68693          	addi	a3,a3,318 # 80002de6 <usertrap>
    80002cb0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002cb2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cb4:	8692                	mv	a3,tp
    80002cb6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cbc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cc0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cc4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cc8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cca:	6f18                	ld	a4,24(a4)
    80002ccc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cd0:	6928                	ld	a0,80(a0)
    80002cd2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002cd4:	00004717          	auipc	a4,0x4
    80002cd8:	3c870713          	addi	a4,a4,968 # 8000709c <userret>
    80002cdc:	8f11                	sub	a4,a4,a2
    80002cde:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002ce0:	577d                	li	a4,-1
    80002ce2:	177e                	slli	a4,a4,0x3f
    80002ce4:	8d59                	or	a0,a0,a4
    80002ce6:	9782                	jalr	a5
}
    80002ce8:	60a2                	ld	ra,8(sp)
    80002cea:	6402                	ld	s0,0(sp)
    80002cec:	0141                	addi	sp,sp,16
    80002cee:	8082                	ret

0000000080002cf0 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002cf0:	1101                	addi	sp,sp,-32
    80002cf2:	ec06                	sd	ra,24(sp)
    80002cf4:	e822                	sd	s0,16(sp)
    80002cf6:	e426                	sd	s1,8(sp)
    80002cf8:	e04a                	sd	s2,0(sp)
    80002cfa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cfc:	0001b917          	auipc	s2,0x1b
    80002d00:	35c90913          	addi	s2,s2,860 # 8001e058 <tickslock>
    80002d04:	854a                	mv	a0,s2
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	ed0080e7          	jalr	-304(ra) # 80000bd6 <acquire>
  ticks++;
    80002d0e:	00006497          	auipc	s1,0x6
    80002d12:	c4648493          	addi	s1,s1,-954 # 80008954 <ticks>
    80002d16:	409c                	lw	a5,0(s1)
    80002d18:	2785                	addiw	a5,a5,1
    80002d1a:	c09c                	sw	a5,0(s1)
  update_time();
    80002d1c:	00000097          	auipc	ra,0x0
    80002d20:	e36080e7          	jalr	-458(ra) # 80002b52 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002d24:	8526                	mv	a0,s1
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	79a080e7          	jalr	1946(ra) # 800024c0 <wakeup>
  release(&tickslock);
    80002d2e:	854a                	mv	a0,s2
    80002d30:	ffffe097          	auipc	ra,0xffffe
    80002d34:	f5a080e7          	jalr	-166(ra) # 80000c8a <release>
}
    80002d38:	60e2                	ld	ra,24(sp)
    80002d3a:	6442                	ld	s0,16(sp)
    80002d3c:	64a2                	ld	s1,8(sp)
    80002d3e:	6902                	ld	s2,0(sp)
    80002d40:	6105                	addi	sp,sp,32
    80002d42:	8082                	ret

0000000080002d44 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002d44:	1101                	addi	sp,sp,-32
    80002d46:	ec06                	sd	ra,24(sp)
    80002d48:	e822                	sd	s0,16(sp)
    80002d4a:	e426                	sd	s1,8(sp)
    80002d4c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d4e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002d52:	00074d63          	bltz	a4,80002d6c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002d56:	57fd                	li	a5,-1
    80002d58:	17fe                	slli	a5,a5,0x3f
    80002d5a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002d5c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002d5e:	06f70363          	beq	a4,a5,80002dc4 <devintr+0x80>
  }
}
    80002d62:	60e2                	ld	ra,24(sp)
    80002d64:	6442                	ld	s0,16(sp)
    80002d66:	64a2                	ld	s1,8(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret
      (scause & 0xff) == 9)
    80002d6c:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002d70:	46a5                	li	a3,9
    80002d72:	fed792e3          	bne	a5,a3,80002d56 <devintr+0x12>
    int irq = plic_claim();
    80002d76:	00003097          	auipc	ra,0x3
    80002d7a:	6c2080e7          	jalr	1730(ra) # 80006438 <plic_claim>
    80002d7e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002d80:	47a9                	li	a5,10
    80002d82:	02f50763          	beq	a0,a5,80002db0 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002d86:	4785                	li	a5,1
    80002d88:	02f50963          	beq	a0,a5,80002dba <devintr+0x76>
    return 1;
    80002d8c:	4505                	li	a0,1
    else if (irq)
    80002d8e:	d8f1                	beqz	s1,80002d62 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d90:	85a6                	mv	a1,s1
    80002d92:	00005517          	auipc	a0,0x5
    80002d96:	5d650513          	addi	a0,a0,1494 # 80008368 <states.0+0x38>
    80002d9a:	ffffd097          	auipc	ra,0xffffd
    80002d9e:	7ee080e7          	jalr	2030(ra) # 80000588 <printf>
      plic_complete(irq);
    80002da2:	8526                	mv	a0,s1
    80002da4:	00003097          	auipc	ra,0x3
    80002da8:	6b8080e7          	jalr	1720(ra) # 8000645c <plic_complete>
    return 1;
    80002dac:	4505                	li	a0,1
    80002dae:	bf55                	j	80002d62 <devintr+0x1e>
      uartintr();
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	bea080e7          	jalr	-1046(ra) # 8000099a <uartintr>
    80002db8:	b7ed                	j	80002da2 <devintr+0x5e>
      virtio_disk_intr();
    80002dba:	00004097          	auipc	ra,0x4
    80002dbe:	b6e080e7          	jalr	-1170(ra) # 80006928 <virtio_disk_intr>
    80002dc2:	b7c5                	j	80002da2 <devintr+0x5e>
    if (cpuid() == 0)
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	e06080e7          	jalr	-506(ra) # 80001bca <cpuid>
    80002dcc:	c901                	beqz	a0,80002ddc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dce:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dd2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dd4:	14479073          	csrw	sip,a5
    return 2;
    80002dd8:	4509                	li	a0,2
    80002dda:	b761                	j	80002d62 <devintr+0x1e>
      clockintr();
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	f14080e7          	jalr	-236(ra) # 80002cf0 <clockintr>
    80002de4:	b7ed                	j	80002dce <devintr+0x8a>

0000000080002de6 <usertrap>:
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	e426                	sd	s1,8(sp)
    80002dee:	e04a                	sd	s2,0(sp)
    80002df0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002df6:	1007f793          	andi	a5,a5,256
    80002dfa:	e3b1                	bnez	a5,80002e3e <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dfc:	00003797          	auipc	a5,0x3
    80002e00:	53478793          	addi	a5,a5,1332 # 80006330 <kernelvec>
    80002e04:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	dee080e7          	jalr	-530(ra) # 80001bf6 <myproc>
    80002e10:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e12:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e14:	14102773          	csrr	a4,sepc
    80002e18:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e1a:	14202773          	csrr	a4,scause
  if (r_scause() == 8) // System call
    80002e1e:	47a1                	li	a5,8
    80002e20:	02f70763          	beq	a4,a5,80002e4e <usertrap+0x68>
  else if ((which_dev = devintr()) != 0) // Device interrupt
    80002e24:	00000097          	auipc	ra,0x0
    80002e28:	f20080e7          	jalr	-224(ra) # 80002d44 <devintr>
    80002e2c:	892a                	mv	s2,a0
    80002e2e:	c92d                	beqz	a0,80002ea0 <usertrap+0xba>
  if (killed(p))
    80002e30:	8526                	mv	a0,s1
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	90c080e7          	jalr	-1780(ra) # 8000273e <killed>
    80002e3a:	c555                	beqz	a0,80002ee6 <usertrap+0x100>
    80002e3c:	a045                	j	80002edc <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002e3e:	00005517          	auipc	a0,0x5
    80002e42:	54a50513          	addi	a0,a0,1354 # 80008388 <states.0+0x58>
    80002e46:	ffffd097          	auipc	ra,0xffffd
    80002e4a:	6f8080e7          	jalr	1784(ra) # 8000053e <panic>
    if (killed(p))
    80002e4e:	00000097          	auipc	ra,0x0
    80002e52:	8f0080e7          	jalr	-1808(ra) # 8000273e <killed>
    80002e56:	ed1d                	bnez	a0,80002e94 <usertrap+0xae>
    p->trapframe->epc += 4;
    80002e58:	6cb8                	ld	a4,88(s1)
    80002e5a:	6f1c                	ld	a5,24(a4)
    80002e5c:	0791                	addi	a5,a5,4
    80002e5e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e64:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e68:	10079073          	csrw	sstatus,a5
    syscall();
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	2ee080e7          	jalr	750(ra) # 8000315a <syscall>
  if (killed(p))
    80002e74:	8526                	mv	a0,s1
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	8c8080e7          	jalr	-1848(ra) # 8000273e <killed>
    80002e7e:	ed31                	bnez	a0,80002eda <usertrap+0xf4>
  usertrapret();
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	dda080e7          	jalr	-550(ra) # 80002c5a <usertrapret>
}
    80002e88:	60e2                	ld	ra,24(sp)
    80002e8a:	6442                	ld	s0,16(sp)
    80002e8c:	64a2                	ld	s1,8(sp)
    80002e8e:	6902                	ld	s2,0(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret
      exit(-1);
    80002e94:	557d                	li	a0,-1
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	728080e7          	jalr	1832(ra) # 800025be <exit>
    80002e9e:	bf6d                	j	80002e58 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ea0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ea4:	5890                	lw	a2,48(s1)
    80002ea6:	00005517          	auipc	a0,0x5
    80002eaa:	50250513          	addi	a0,a0,1282 # 800083a8 <states.0+0x78>
    80002eae:	ffffd097          	auipc	ra,0xffffd
    80002eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eb6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eba:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ebe:	00005517          	auipc	a0,0x5
    80002ec2:	51a50513          	addi	a0,a0,1306 # 800083d8 <states.0+0xa8>
    80002ec6:	ffffd097          	auipc	ra,0xffffd
    80002eca:	6c2080e7          	jalr	1730(ra) # 80000588 <printf>
    setkilled(p);
    80002ece:	8526                	mv	a0,s1
    80002ed0:	00000097          	auipc	ra,0x0
    80002ed4:	842080e7          	jalr	-1982(ra) # 80002712 <setkilled>
    80002ed8:	bf71                	j	80002e74 <usertrap+0x8e>
  if (killed(p))
    80002eda:	4901                	li	s2,0
    exit(-1);
    80002edc:	557d                	li	a0,-1
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	6e0080e7          	jalr	1760(ra) # 800025be <exit>
  if (which_dev == 2) // Timer interrupt
    80002ee6:	4789                	li	a5,2
    80002ee8:	f8f91ce3          	bne	s2,a5,80002e80 <usertrap+0x9a>
    if (p->state == RUNNING)
    80002eec:	4c98                	lw	a4,24(s1)
    80002eee:	4791                	li	a5,4
    80002ef0:	f8f718e3          	bne	a4,a5,80002e80 <usertrap+0x9a>
      p->remaining_ticks--;
    80002ef4:	3304a783          	lw	a5,816(s1)
    80002ef8:	37fd                	addiw	a5,a5,-1
    80002efa:	0007871b          	sext.w	a4,a5
    80002efe:	32f4a823          	sw	a5,816(s1)
      if (p->remaining_ticks <= 0)
    80002f02:	f6e04fe3          	bgtz	a4,80002e80 <usertrap+0x9a>
        yield();
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	496080e7          	jalr	1174(ra) # 8000239c <yield>
    80002f0e:	bf8d                	j	80002e80 <usertrap+0x9a>

0000000080002f10 <kerneltrap>:
{
    80002f10:	7179                	addi	sp,sp,-48
    80002f12:	f406                	sd	ra,40(sp)
    80002f14:	f022                	sd	s0,32(sp)
    80002f16:	ec26                	sd	s1,24(sp)
    80002f18:	e84a                	sd	s2,16(sp)
    80002f1a:	e44e                	sd	s3,8(sp)
    80002f1c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f1e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f22:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f26:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002f2a:	1004f793          	andi	a5,s1,256
    80002f2e:	cb85                	beqz	a5,80002f5e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f30:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f34:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002f36:	ef85                	bnez	a5,80002f6e <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002f38:	00000097          	auipc	ra,0x0
    80002f3c:	e0c080e7          	jalr	-500(ra) # 80002d44 <devintr>
    80002f40:	cd1d                	beqz	a0,80002f7e <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f42:	4789                	li	a5,2
    80002f44:	06f50a63          	beq	a0,a5,80002fb8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f48:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f4c:	10049073          	csrw	sstatus,s1
}
    80002f50:	70a2                	ld	ra,40(sp)
    80002f52:	7402                	ld	s0,32(sp)
    80002f54:	64e2                	ld	s1,24(sp)
    80002f56:	6942                	ld	s2,16(sp)
    80002f58:	69a2                	ld	s3,8(sp)
    80002f5a:	6145                	addi	sp,sp,48
    80002f5c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f5e:	00005517          	auipc	a0,0x5
    80002f62:	49a50513          	addi	a0,a0,1178 # 800083f8 <states.0+0xc8>
    80002f66:	ffffd097          	auipc	ra,0xffffd
    80002f6a:	5d8080e7          	jalr	1496(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f6e:	00005517          	auipc	a0,0x5
    80002f72:	4b250513          	addi	a0,a0,1202 # 80008420 <states.0+0xf0>
    80002f76:	ffffd097          	auipc	ra,0xffffd
    80002f7a:	5c8080e7          	jalr	1480(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f7e:	85ce                	mv	a1,s3
    80002f80:	00005517          	auipc	a0,0x5
    80002f84:	4c050513          	addi	a0,a0,1216 # 80008440 <states.0+0x110>
    80002f88:	ffffd097          	auipc	ra,0xffffd
    80002f8c:	600080e7          	jalr	1536(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f94:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	4b850513          	addi	a0,a0,1208 # 80008450 <states.0+0x120>
    80002fa0:	ffffd097          	auipc	ra,0xffffd
    80002fa4:	5e8080e7          	jalr	1512(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	4c050513          	addi	a0,a0,1216 # 80008468 <states.0+0x138>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	58e080e7          	jalr	1422(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	c3e080e7          	jalr	-962(ra) # 80001bf6 <myproc>
    80002fc0:	d541                	beqz	a0,80002f48 <kerneltrap+0x38>
    80002fc2:	fffff097          	auipc	ra,0xfffff
    80002fc6:	c34080e7          	jalr	-972(ra) # 80001bf6 <myproc>
    80002fca:	4d18                	lw	a4,24(a0)
    80002fcc:	4791                	li	a5,4
    80002fce:	f6f71de3          	bne	a4,a5,80002f48 <kerneltrap+0x38>
    yield();
    80002fd2:	fffff097          	auipc	ra,0xfffff
    80002fd6:	3ca080e7          	jalr	970(ra) # 8000239c <yield>
    80002fda:	b7bd                	j	80002f48 <kerneltrap+0x38>

0000000080002fdc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fdc:	1101                	addi	sp,sp,-32
    80002fde:	ec06                	sd	ra,24(sp)
    80002fe0:	e822                	sd	s0,16(sp)
    80002fe2:	e426                	sd	s1,8(sp)
    80002fe4:	1000                	addi	s0,sp,32
    80002fe6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fe8:	fffff097          	auipc	ra,0xfffff
    80002fec:	c0e080e7          	jalr	-1010(ra) # 80001bf6 <myproc>
  switch (n) {
    80002ff0:	4795                	li	a5,5
    80002ff2:	0497e163          	bltu	a5,s1,80003034 <argraw+0x58>
    80002ff6:	048a                	slli	s1,s1,0x2
    80002ff8:	00005717          	auipc	a4,0x5
    80002ffc:	4a870713          	addi	a4,a4,1192 # 800084a0 <states.0+0x170>
    80003000:	94ba                	add	s1,s1,a4
    80003002:	409c                	lw	a5,0(s1)
    80003004:	97ba                	add	a5,a5,a4
    80003006:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003008:	6d3c                	ld	a5,88(a0)
    8000300a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret
    return p->trapframe->a1;
    80003016:	6d3c                	ld	a5,88(a0)
    80003018:	7fa8                	ld	a0,120(a5)
    8000301a:	bfcd                	j	8000300c <argraw+0x30>
    return p->trapframe->a2;
    8000301c:	6d3c                	ld	a5,88(a0)
    8000301e:	63c8                	ld	a0,128(a5)
    80003020:	b7f5                	j	8000300c <argraw+0x30>
    return p->trapframe->a3;
    80003022:	6d3c                	ld	a5,88(a0)
    80003024:	67c8                	ld	a0,136(a5)
    80003026:	b7dd                	j	8000300c <argraw+0x30>
    return p->trapframe->a4;
    80003028:	6d3c                	ld	a5,88(a0)
    8000302a:	6bc8                	ld	a0,144(a5)
    8000302c:	b7c5                	j	8000300c <argraw+0x30>
    return p->trapframe->a5;
    8000302e:	6d3c                	ld	a5,88(a0)
    80003030:	6fc8                	ld	a0,152(a5)
    80003032:	bfe9                	j	8000300c <argraw+0x30>
  panic("argraw");
    80003034:	00005517          	auipc	a0,0x5
    80003038:	44450513          	addi	a0,a0,1092 # 80008478 <states.0+0x148>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	502080e7          	jalr	1282(ra) # 8000053e <panic>

0000000080003044 <fetchaddr>:
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	e426                	sd	s1,8(sp)
    8000304c:	e04a                	sd	s2,0(sp)
    8000304e:	1000                	addi	s0,sp,32
    80003050:	84aa                	mv	s1,a0
    80003052:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003054:	fffff097          	auipc	ra,0xfffff
    80003058:	ba2080e7          	jalr	-1118(ra) # 80001bf6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000305c:	653c                	ld	a5,72(a0)
    8000305e:	02f4f863          	bgeu	s1,a5,8000308e <fetchaddr+0x4a>
    80003062:	00848713          	addi	a4,s1,8
    80003066:	02e7e663          	bltu	a5,a4,80003092 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000306a:	46a1                	li	a3,8
    8000306c:	8626                	mv	a2,s1
    8000306e:	85ca                	mv	a1,s2
    80003070:	6928                	ld	a0,80(a0)
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	682080e7          	jalr	1666(ra) # 800016f4 <copyin>
    8000307a:	00a03533          	snez	a0,a0
    8000307e:	40a00533          	neg	a0,a0
}
    80003082:	60e2                	ld	ra,24(sp)
    80003084:	6442                	ld	s0,16(sp)
    80003086:	64a2                	ld	s1,8(sp)
    80003088:	6902                	ld	s2,0(sp)
    8000308a:	6105                	addi	sp,sp,32
    8000308c:	8082                	ret
    return -1;
    8000308e:	557d                	li	a0,-1
    80003090:	bfcd                	j	80003082 <fetchaddr+0x3e>
    80003092:	557d                	li	a0,-1
    80003094:	b7fd                	j	80003082 <fetchaddr+0x3e>

0000000080003096 <fetchstr>:
{
    80003096:	7179                	addi	sp,sp,-48
    80003098:	f406                	sd	ra,40(sp)
    8000309a:	f022                	sd	s0,32(sp)
    8000309c:	ec26                	sd	s1,24(sp)
    8000309e:	e84a                	sd	s2,16(sp)
    800030a0:	e44e                	sd	s3,8(sp)
    800030a2:	1800                	addi	s0,sp,48
    800030a4:	892a                	mv	s2,a0
    800030a6:	84ae                	mv	s1,a1
    800030a8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	b4c080e7          	jalr	-1204(ra) # 80001bf6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800030b2:	86ce                	mv	a3,s3
    800030b4:	864a                	mv	a2,s2
    800030b6:	85a6                	mv	a1,s1
    800030b8:	6928                	ld	a0,80(a0)
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	6c8080e7          	jalr	1736(ra) # 80001782 <copyinstr>
    800030c2:	00054e63          	bltz	a0,800030de <fetchstr+0x48>
  return strlen(buf);
    800030c6:	8526                	mv	a0,s1
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	d86080e7          	jalr	-634(ra) # 80000e4e <strlen>
}
    800030d0:	70a2                	ld	ra,40(sp)
    800030d2:	7402                	ld	s0,32(sp)
    800030d4:	64e2                	ld	s1,24(sp)
    800030d6:	6942                	ld	s2,16(sp)
    800030d8:	69a2                	ld	s3,8(sp)
    800030da:	6145                	addi	sp,sp,48
    800030dc:	8082                	ret
    return -1;
    800030de:	557d                	li	a0,-1
    800030e0:	bfc5                	j	800030d0 <fetchstr+0x3a>

00000000800030e2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	e426                	sd	s1,8(sp)
    800030ea:	1000                	addi	s0,sp,32
    800030ec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030ee:	00000097          	auipc	ra,0x0
    800030f2:	eee080e7          	jalr	-274(ra) # 80002fdc <argraw>
    800030f6:	c088                	sw	a0,0(s1)
}
    800030f8:	60e2                	ld	ra,24(sp)
    800030fa:	6442                	ld	s0,16(sp)
    800030fc:	64a2                	ld	s1,8(sp)
    800030fe:	6105                	addi	sp,sp,32
    80003100:	8082                	ret

0000000080003102 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003102:	1101                	addi	sp,sp,-32
    80003104:	ec06                	sd	ra,24(sp)
    80003106:	e822                	sd	s0,16(sp)
    80003108:	e426                	sd	s1,8(sp)
    8000310a:	1000                	addi	s0,sp,32
    8000310c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000310e:	00000097          	auipc	ra,0x0
    80003112:	ece080e7          	jalr	-306(ra) # 80002fdc <argraw>
    80003116:	e088                	sd	a0,0(s1)
}
    80003118:	60e2                	ld	ra,24(sp)
    8000311a:	6442                	ld	s0,16(sp)
    8000311c:	64a2                	ld	s1,8(sp)
    8000311e:	6105                	addi	sp,sp,32
    80003120:	8082                	ret

0000000080003122 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003122:	7179                	addi	sp,sp,-48
    80003124:	f406                	sd	ra,40(sp)
    80003126:	f022                	sd	s0,32(sp)
    80003128:	ec26                	sd	s1,24(sp)
    8000312a:	e84a                	sd	s2,16(sp)
    8000312c:	1800                	addi	s0,sp,48
    8000312e:	84ae                	mv	s1,a1
    80003130:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003132:	fd840593          	addi	a1,s0,-40
    80003136:	00000097          	auipc	ra,0x0
    8000313a:	fcc080e7          	jalr	-52(ra) # 80003102 <argaddr>
  return fetchstr(addr, buf, max);
    8000313e:	864a                	mv	a2,s2
    80003140:	85a6                	mv	a1,s1
    80003142:	fd843503          	ld	a0,-40(s0)
    80003146:	00000097          	auipc	ra,0x0
    8000314a:	f50080e7          	jalr	-176(ra) # 80003096 <fetchstr>
}
    8000314e:	70a2                	ld	ra,40(sp)
    80003150:	7402                	ld	s0,32(sp)
    80003152:	64e2                	ld	s1,24(sp)
    80003154:	6942                	ld	s2,16(sp)
    80003156:	6145                	addi	sp,sp,48
    80003158:	8082                	ret

000000008000315a <syscall>:
//   }


void
syscall(void)
{
    8000315a:	7179                	addi	sp,sp,-48
    8000315c:	f406                	sd	ra,40(sp)
    8000315e:	f022                	sd	s0,32(sp)
    80003160:	ec26                	sd	s1,24(sp)
    80003162:	e84a                	sd	s2,16(sp)
    80003164:	e44e                	sd	s3,8(sp)
    80003166:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	a8e080e7          	jalr	-1394(ra) # 80001bf6 <myproc>
    80003170:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003172:	05853983          	ld	s3,88(a0)
    80003176:	0a89b783          	ld	a5,168(s3)
    8000317a:	0007891b          	sext.w	s2,a5

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000317e:	37fd                	addiw	a5,a5,-1
    80003180:	4765                	li	a4,25
    80003182:	02f76663          	bltu	a4,a5,800031ae <syscall+0x54>
    80003186:	00391713          	slli	a4,s2,0x3
    8000318a:	00005797          	auipc	a5,0x5
    8000318e:	32e78793          	addi	a5,a5,814 # 800084b8 <syscalls>
    80003192:	97ba                	add	a5,a5,a4
    80003194:	639c                	ld	a5,0(a5)
    80003196:	cf81                	beqz	a5,800031ae <syscall+0x54>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003198:	9782                	jalr	a5
    8000319a:	06a9b823          	sd	a0,112(s3)

    p->syscall_count[num]++; // Increment the count for this syscall // change
    8000319e:	090a                	slli	s2,s2,0x2
    800031a0:	94ca                	add	s1,s1,s2
    800031a2:	1744a783          	lw	a5,372(s1)
    800031a6:	2785                	addiw	a5,a5,1
    800031a8:	16f4aa23          	sw	a5,372(s1)
    800031ac:	a005                	j	800031cc <syscall+0x72>
    // printf("PID %d: syscall %d called, count now %d\n", p->pid, num, p->syscall_count[num]);
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031ae:	86ca                	mv	a3,s2
    800031b0:	15848613          	addi	a2,s1,344
    800031b4:	588c                	lw	a1,48(s1)
    800031b6:	00005517          	auipc	a0,0x5
    800031ba:	2ca50513          	addi	a0,a0,714 # 80008480 <states.0+0x150>
    800031be:	ffffd097          	auipc	ra,0xffffd
    800031c2:	3ca080e7          	jalr	970(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031c6:	6cbc                	ld	a5,88(s1)
    800031c8:	577d                	li	a4,-1
    800031ca:	fbb8                	sd	a4,112(a5)
  }
}
    800031cc:	70a2                	ld	ra,40(sp)
    800031ce:	7402                	ld	s0,32(sp)
    800031d0:	64e2                	ld	s1,24(sp)
    800031d2:	6942                	ld	s2,16(sp)
    800031d4:	69a2                	ld	s3,8(sp)
    800031d6:	6145                	addi	sp,sp,48
    800031d8:	8082                	ret

00000000800031da <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031da:	1101                	addi	sp,sp,-32
    800031dc:	ec06                	sd	ra,24(sp)
    800031de:	e822                	sd	s0,16(sp)
    800031e0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800031e2:	fec40593          	addi	a1,s0,-20
    800031e6:	4501                	li	a0,0
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	efa080e7          	jalr	-262(ra) # 800030e2 <argint>
  exit(n);
    800031f0:	fec42503          	lw	a0,-20(s0)
    800031f4:	fffff097          	auipc	ra,0xfffff
    800031f8:	3ca080e7          	jalr	970(ra) # 800025be <exit>
  return 0; // not reached
}
    800031fc:	4501                	li	a0,0
    800031fe:	60e2                	ld	ra,24(sp)
    80003200:	6442                	ld	s0,16(sp)
    80003202:	6105                	addi	sp,sp,32
    80003204:	8082                	ret

0000000080003206 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003206:	1141                	addi	sp,sp,-16
    80003208:	e406                	sd	ra,8(sp)
    8000320a:	e022                	sd	s0,0(sp)
    8000320c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000320e:	fffff097          	auipc	ra,0xfffff
    80003212:	9e8080e7          	jalr	-1560(ra) # 80001bf6 <myproc>
}
    80003216:	5908                	lw	a0,48(a0)
    80003218:	60a2                	ld	ra,8(sp)
    8000321a:	6402                	ld	s0,0(sp)
    8000321c:	0141                	addi	sp,sp,16
    8000321e:	8082                	ret

0000000080003220 <sys_fork>:

uint64
sys_fork(void)
{
    80003220:	1141                	addi	sp,sp,-16
    80003222:	e406                	sd	ra,8(sp)
    80003224:	e022                	sd	s0,0(sp)
    80003226:	0800                	addi	s0,sp,16
  return fork();
    80003228:	fffff097          	auipc	ra,0xfffff
    8000322c:	de2080e7          	jalr	-542(ra) # 8000200a <fork>
}
    80003230:	60a2                	ld	ra,8(sp)
    80003232:	6402                	ld	s0,0(sp)
    80003234:	0141                	addi	sp,sp,16
    80003236:	8082                	ret

0000000080003238 <sys_wait>:

uint64
sys_wait(void)
{
    80003238:	1101                	addi	sp,sp,-32
    8000323a:	ec06                	sd	ra,24(sp)
    8000323c:	e822                	sd	s0,16(sp)
    8000323e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003240:	fe840593          	addi	a1,s0,-24
    80003244:	4501                	li	a0,0
    80003246:	00000097          	auipc	ra,0x0
    8000324a:	ebc080e7          	jalr	-324(ra) # 80003102 <argaddr>
  return wait(p);
    8000324e:	fe843503          	ld	a0,-24(s0)
    80003252:	fffff097          	auipc	ra,0xfffff
    80003256:	51e080e7          	jalr	1310(ra) # 80002770 <wait>
}
    8000325a:	60e2                	ld	ra,24(sp)
    8000325c:	6442                	ld	s0,16(sp)
    8000325e:	6105                	addi	sp,sp,32
    80003260:	8082                	ret

0000000080003262 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003262:	7179                	addi	sp,sp,-48
    80003264:	f406                	sd	ra,40(sp)
    80003266:	f022                	sd	s0,32(sp)
    80003268:	ec26                	sd	s1,24(sp)
    8000326a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000326c:	fdc40593          	addi	a1,s0,-36
    80003270:	4501                	li	a0,0
    80003272:	00000097          	auipc	ra,0x0
    80003276:	e70080e7          	jalr	-400(ra) # 800030e2 <argint>
  addr = myproc()->sz;
    8000327a:	fffff097          	auipc	ra,0xfffff
    8000327e:	97c080e7          	jalr	-1668(ra) # 80001bf6 <myproc>
    80003282:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003284:	fdc42503          	lw	a0,-36(s0)
    80003288:	fffff097          	auipc	ra,0xfffff
    8000328c:	d26080e7          	jalr	-730(ra) # 80001fae <growproc>
    80003290:	00054863          	bltz	a0,800032a0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003294:	8526                	mv	a0,s1
    80003296:	70a2                	ld	ra,40(sp)
    80003298:	7402                	ld	s0,32(sp)
    8000329a:	64e2                	ld	s1,24(sp)
    8000329c:	6145                	addi	sp,sp,48
    8000329e:	8082                	ret
    return -1;
    800032a0:	54fd                	li	s1,-1
    800032a2:	bfcd                	j	80003294 <sys_sbrk+0x32>

00000000800032a4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032a4:	7139                	addi	sp,sp,-64
    800032a6:	fc06                	sd	ra,56(sp)
    800032a8:	f822                	sd	s0,48(sp)
    800032aa:	f426                	sd	s1,40(sp)
    800032ac:	f04a                	sd	s2,32(sp)
    800032ae:	ec4e                	sd	s3,24(sp)
    800032b0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800032b2:	fcc40593          	addi	a1,s0,-52
    800032b6:	4501                	li	a0,0
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	e2a080e7          	jalr	-470(ra) # 800030e2 <argint>
  acquire(&tickslock);
    800032c0:	0001b517          	auipc	a0,0x1b
    800032c4:	d9850513          	addi	a0,a0,-616 # 8001e058 <tickslock>
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	90e080e7          	jalr	-1778(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800032d0:	00005917          	auipc	s2,0x5
    800032d4:	68492903          	lw	s2,1668(s2) # 80008954 <ticks>
  while (ticks - ticks0 < n)
    800032d8:	fcc42783          	lw	a5,-52(s0)
    800032dc:	cf9d                	beqz	a5,8000331a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032de:	0001b997          	auipc	s3,0x1b
    800032e2:	d7a98993          	addi	s3,s3,-646 # 8001e058 <tickslock>
    800032e6:	00005497          	auipc	s1,0x5
    800032ea:	66e48493          	addi	s1,s1,1646 # 80008954 <ticks>
    if (killed(myproc()))
    800032ee:	fffff097          	auipc	ra,0xfffff
    800032f2:	908080e7          	jalr	-1784(ra) # 80001bf6 <myproc>
    800032f6:	fffff097          	auipc	ra,0xfffff
    800032fa:	448080e7          	jalr	1096(ra) # 8000273e <killed>
    800032fe:	ed15                	bnez	a0,8000333a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003300:	85ce                	mv	a1,s3
    80003302:	8526                	mv	a0,s1
    80003304:	fffff097          	auipc	ra,0xfffff
    80003308:	14a080e7          	jalr	330(ra) # 8000244e <sleep>
  while (ticks - ticks0 < n)
    8000330c:	409c                	lw	a5,0(s1)
    8000330e:	412787bb          	subw	a5,a5,s2
    80003312:	fcc42703          	lw	a4,-52(s0)
    80003316:	fce7ece3          	bltu	a5,a4,800032ee <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000331a:	0001b517          	auipc	a0,0x1b
    8000331e:	d3e50513          	addi	a0,a0,-706 # 8001e058 <tickslock>
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	968080e7          	jalr	-1688(ra) # 80000c8a <release>
  return 0;
    8000332a:	4501                	li	a0,0
}
    8000332c:	70e2                	ld	ra,56(sp)
    8000332e:	7442                	ld	s0,48(sp)
    80003330:	74a2                	ld	s1,40(sp)
    80003332:	7902                	ld	s2,32(sp)
    80003334:	69e2                	ld	s3,24(sp)
    80003336:	6121                	addi	sp,sp,64
    80003338:	8082                	ret
      release(&tickslock);
    8000333a:	0001b517          	auipc	a0,0x1b
    8000333e:	d1e50513          	addi	a0,a0,-738 # 8001e058 <tickslock>
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	948080e7          	jalr	-1720(ra) # 80000c8a <release>
      return -1;
    8000334a:	557d                	li	a0,-1
    8000334c:	b7c5                	j	8000332c <sys_sleep+0x88>

000000008000334e <sys_kill>:

uint64
sys_kill(void)
{
    8000334e:	1101                	addi	sp,sp,-32
    80003350:	ec06                	sd	ra,24(sp)
    80003352:	e822                	sd	s0,16(sp)
    80003354:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003356:	fec40593          	addi	a1,s0,-20
    8000335a:	4501                	li	a0,0
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	d86080e7          	jalr	-634(ra) # 800030e2 <argint>
  return kill(pid);
    80003364:	fec42503          	lw	a0,-20(s0)
    80003368:	fffff097          	auipc	ra,0xfffff
    8000336c:	338080e7          	jalr	824(ra) # 800026a0 <kill>
}
    80003370:	60e2                	ld	ra,24(sp)
    80003372:	6442                	ld	s0,16(sp)
    80003374:	6105                	addi	sp,sp,32
    80003376:	8082                	ret

0000000080003378 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003378:	1101                	addi	sp,sp,-32
    8000337a:	ec06                	sd	ra,24(sp)
    8000337c:	e822                	sd	s0,16(sp)
    8000337e:	e426                	sd	s1,8(sp)
    80003380:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003382:	0001b517          	auipc	a0,0x1b
    80003386:	cd650513          	addi	a0,a0,-810 # 8001e058 <tickslock>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	84c080e7          	jalr	-1972(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003392:	00005497          	auipc	s1,0x5
    80003396:	5c24a483          	lw	s1,1474(s1) # 80008954 <ticks>
  release(&tickslock);
    8000339a:	0001b517          	auipc	a0,0x1b
    8000339e:	cbe50513          	addi	a0,a0,-834 # 8001e058 <tickslock>
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	8e8080e7          	jalr	-1816(ra) # 80000c8a <release>
  return xticks;
}
    800033aa:	02049513          	slli	a0,s1,0x20
    800033ae:	9101                	srli	a0,a0,0x20
    800033b0:	60e2                	ld	ra,24(sp)
    800033b2:	6442                	ld	s0,16(sp)
    800033b4:	64a2                	ld	s1,8(sp)
    800033b6:	6105                	addi	sp,sp,32
    800033b8:	8082                	ret

00000000800033ba <sys_waitx>:

uint64
sys_waitx(void)
{
    800033ba:	7139                	addi	sp,sp,-64
    800033bc:	fc06                	sd	ra,56(sp)
    800033be:	f822                	sd	s0,48(sp)
    800033c0:	f426                	sd	s1,40(sp)
    800033c2:	f04a                	sd	s2,32(sp)
    800033c4:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800033c6:	fd840593          	addi	a1,s0,-40
    800033ca:	4501                	li	a0,0
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	d36080e7          	jalr	-714(ra) # 80003102 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800033d4:	fd040593          	addi	a1,s0,-48
    800033d8:	4505                	li	a0,1
    800033da:	00000097          	auipc	ra,0x0
    800033de:	d28080e7          	jalr	-728(ra) # 80003102 <argaddr>
  argaddr(2, &addr2);
    800033e2:	fc840593          	addi	a1,s0,-56
    800033e6:	4509                	li	a0,2
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	d1a080e7          	jalr	-742(ra) # 80003102 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800033f0:	fc040613          	addi	a2,s0,-64
    800033f4:	fc440593          	addi	a1,s0,-60
    800033f8:	fd843503          	ld	a0,-40(s0)
    800033fc:	fffff097          	auipc	ra,0xfffff
    80003400:	60a080e7          	jalr	1546(ra) # 80002a06 <waitx>
    80003404:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003406:	ffffe097          	auipc	ra,0xffffe
    8000340a:	7f0080e7          	jalr	2032(ra) # 80001bf6 <myproc>
    8000340e:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003410:	4691                	li	a3,4
    80003412:	fc440613          	addi	a2,s0,-60
    80003416:	fd043583          	ld	a1,-48(s0)
    8000341a:	6928                	ld	a0,80(a0)
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	24c080e7          	jalr	588(ra) # 80001668 <copyout>
    return -1;
    80003424:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003426:	00054f63          	bltz	a0,80003444 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000342a:	4691                	li	a3,4
    8000342c:	fc040613          	addi	a2,s0,-64
    80003430:	fc843583          	ld	a1,-56(s0)
    80003434:	68a8                	ld	a0,80(s1)
    80003436:	ffffe097          	auipc	ra,0xffffe
    8000343a:	232080e7          	jalr	562(ra) # 80001668 <copyout>
    8000343e:	00054a63          	bltz	a0,80003452 <sys_waitx+0x98>
    return -1;
  return ret;
    80003442:	87ca                	mv	a5,s2
}
    80003444:	853e                	mv	a0,a5
    80003446:	70e2                	ld	ra,56(sp)
    80003448:	7442                	ld	s0,48(sp)
    8000344a:	74a2                	ld	s1,40(sp)
    8000344c:	7902                	ld	s2,32(sp)
    8000344e:	6121                	addi	sp,sp,64
    80003450:	8082                	ret
    return -1;
    80003452:	57fd                	li	a5,-1
    80003454:	bfc5                	j	80003444 <sys_waitx+0x8a>

0000000080003456 <sum_syscall_counts>:

// Function to recursively sum syscall counts from a process and its children
int sum_syscall_counts(struct proc *p, int mask)
{
    80003456:	7139                	addi	sp,sp,-64
    80003458:	fc06                	sd	ra,56(sp)
    8000345a:	f822                	sd	s0,48(sp)
    8000345c:	f426                	sd	s1,40(sp)
    8000345e:	f04a                	sd	s2,32(sp)
    80003460:	ec4e                	sd	s3,24(sp)
    80003462:	e852                	sd	s4,16(sp)
    80003464:	e456                	sd	s5,8(sp)
    80003466:	0080                	addi	s0,sp,64
  if (p == 0)
    80003468:	c921                	beqz	a0,800034b8 <sum_syscall_counts+0x62>
    8000346a:	892a                	mv	s2,a0
    8000346c:	89ae                	mv	s3,a1
    return 0;

  int total = 0;

  // Add the syscall count for the current process
  if (mask < MAX_SYSCALLS)
    8000346e:	47fd                	li	a5,31
  int total = 0;
    80003470:	4a81                	li	s5,0
  if (mask < MAX_SYSCALLS)
    80003472:	00b7c863          	blt	a5,a1,80003482 <sum_syscall_counts+0x2c>
    total += p->syscall_count[mask];
    80003476:	05c58793          	addi	a5,a1,92 # 105c <_entry-0x7fffefa4>
    8000347a:	078a                	slli	a5,a5,0x2
    8000347c:	97aa                	add	a5,a5,a0
    8000347e:	0047aa83          	lw	s5,4(a5)
  int total = 0;
    80003482:	0000e497          	auipc	s1,0xe
    80003486:	bd648493          	addi	s1,s1,-1066 # 80011058 <proc>

  // Recursively sum syscall counts for child processes
  struct proc *child;
  for (child = proc; child < &proc[NPROC]; child++)
    8000348a:	0001ba17          	auipc	s4,0x1b
    8000348e:	bcea0a13          	addi	s4,s4,-1074 # 8001e058 <tickslock>
    80003492:	a029                	j	8000349c <sum_syscall_counts+0x46>
    80003494:	34048493          	addi	s1,s1,832
    80003498:	03448163          	beq	s1,s4,800034ba <sum_syscall_counts+0x64>
  {
    if (child->parent == p && child->state != UNUSED)
    8000349c:	7c9c                	ld	a5,56(s1)
    8000349e:	ff279be3          	bne	a5,s2,80003494 <sum_syscall_counts+0x3e>
    800034a2:	4c9c                	lw	a5,24(s1)
    800034a4:	dbe5                	beqz	a5,80003494 <sum_syscall_counts+0x3e>
    {
      total += sum_syscall_counts(child, mask); // Recursive call for child process
    800034a6:	85ce                	mv	a1,s3
    800034a8:	8526                	mv	a0,s1
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	fac080e7          	jalr	-84(ra) # 80003456 <sum_syscall_counts>
    800034b2:	01550abb          	addw	s5,a0,s5
    800034b6:	bff9                	j	80003494 <sum_syscall_counts+0x3e>
    return 0;
    800034b8:	4a81                	li	s5,0
    }
  }

  return total;
}
    800034ba:	8556                	mv	a0,s5
    800034bc:	70e2                	ld	ra,56(sp)
    800034be:	7442                	ld	s0,48(sp)
    800034c0:	74a2                	ld	s1,40(sp)
    800034c2:	7902                	ld	s2,32(sp)
    800034c4:	69e2                	ld	s3,24(sp)
    800034c6:	6a42                	ld	s4,16(sp)
    800034c8:	6aa2                	ld	s5,8(sp)
    800034ca:	6121                	addi	sp,sp,64
    800034cc:	8082                	ret

00000000800034ce <sys_getSysCount>:

//   return total;
// }

uint64 sys_getSysCount(void)
{
    800034ce:	1101                	addi	sp,sp,-32
    800034d0:	ec06                	sd	ra,24(sp)
    800034d2:	e822                	sd	s0,16(sp)
    800034d4:	1000                	addi	s0,sp,32

  int syscall_num;

  argint(0, &syscall_num);
    800034d6:	fec40593          	addi	a1,s0,-20
    800034da:	4501                	li	a0,0
    800034dc:	00000097          	auipc	ra,0x0
    800034e0:	c06080e7          	jalr	-1018(ra) # 800030e2 <argint>

  // printf("%d", syscall_num);

  // Validate that syscall_num is within the correct range
  if (syscall_num < 0 || syscall_num >= MAX_SYSCALLS)
    800034e4:	fec42703          	lw	a4,-20(s0)
    800034e8:	47fd                	li	a5,31
  {
    return -1; // Invalid syscall number
    800034ea:	557d                	li	a0,-1
  if (syscall_num < 0 || syscall_num >= MAX_SYSCALLS)
    800034ec:	00e7ed63          	bltu	a5,a4,80003506 <sys_getSysCount+0x38>
  }

  // Get the current process
  struct proc *p = myproc();
    800034f0:	ffffe097          	auipc	ra,0xffffe
    800034f4:	706080e7          	jalr	1798(ra) # 80001bf6 <myproc>

  // Sum syscall counts from this process and all its children
  int total = p->syscall_count[syscall_num];
    800034f8:	fec42783          	lw	a5,-20(s0)
    800034fc:	05c78793          	addi	a5,a5,92
    80003500:	078a                	slli	a5,a5,0x2
    80003502:	97aa                	add	a5,a5,a0

  return total;
    80003504:	43c8                	lw	a0,4(a5)
}
    80003506:	60e2                	ld	ra,24(sp)
    80003508:	6442                	ld	s0,16(sp)
    8000350a:	6105                	addi	sp,sp,32
    8000350c:	8082                	ret

000000008000350e <sys_sigalarm>:
//     }

//     return 0; // Success
// }

int sys_sigalarm(void) {
    8000350e:	1101                	addi	sp,sp,-32
    80003510:	ec06                	sd	ra,24(sp)
    80003512:	e822                	sd	s0,16(sp)
    80003514:	1000                	addi	s0,sp,32
  int ticks;
  uint64 handler;
  argint(0, &ticks);
    80003516:	fec40593          	addi	a1,s0,-20
    8000351a:	4501                	li	a0,0
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	bc6080e7          	jalr	-1082(ra) # 800030e2 <argint>
  argaddr(1, &handler);
    80003524:	fe040593          	addi	a1,s0,-32
    80003528:	4505                	li	a0,1
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	bd8080e7          	jalr	-1064(ra) # 80003102 <argaddr>
  
  struct proc *p = myproc();
    80003532:	ffffe097          	auipc	ra,0xffffe
    80003536:	6c4080e7          	jalr	1732(ra) # 80001bf6 <myproc>
  p->alarmticks = ticks;
    8000353a:	fec42783          	lw	a5,-20(s0)
    8000353e:	1ef52a23          	sw	a5,500(a0)
  p->alarmhandler = handler;
    80003542:	fe043783          	ld	a5,-32(s0)
    80003546:	20f53023          	sd	a5,512(a0)
  p->ticks = 0;
    8000354a:	1e052c23          	sw	zero,504(a0)
  // Reset the in_alarm_handler flag when setting a new alarm
  p->in_alarm_handler = 0;
    8000354e:	32052423          	sw	zero,808(a0)
  
  return 0;
}
    80003552:	4501                	li	a0,0
    80003554:	60e2                	ld	ra,24(sp)
    80003556:	6442                	ld	s0,16(sp)
    80003558:	6105                	addi	sp,sp,32
    8000355a:	8082                	ret

000000008000355c <sys_sigreturn>:
//         p->in_alarm_handler = 0;
//     }
//     return 0;
// }

int sys_sigreturn(void) {
    8000355c:	1101                	addi	sp,sp,-32
    8000355e:	ec06                	sd	ra,24(sp)
    80003560:	e822                	sd	s0,16(sp)
    80003562:	e426                	sd	s1,8(sp)
    80003564:	e04a                	sd	s2,0(sp)
    80003566:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003568:	ffffe097          	auipc	ra,0xffffe
    8000356c:	68e080e7          	jalr	1678(ra) # 80001bf6 <myproc>
  if (p->in_alarm_handler) {
    80003570:	32852783          	lw	a5,808(a0)
    80003574:	eb81                	bnez	a5,80003584 <sys_sigreturn+0x28>
    
    // Reset the alarm handler flag
    p->in_alarm_handler = 0;
  }
  return 0;
}
    80003576:	4501                	li	a0,0
    80003578:	60e2                	ld	ra,24(sp)
    8000357a:	6442                	ld	s0,16(sp)
    8000357c:	64a2                	ld	s1,8(sp)
    8000357e:	6902                	ld	s2,0(sp)
    80003580:	6105                	addi	sp,sp,32
    80003582:	8082                	ret
    80003584:	84aa                	mv	s1,a0
    uint64 current_a0 = p->trapframe->a0;
    80003586:	6d28                	ld	a0,88(a0)
    80003588:	07053903          	ld	s2,112(a0)
    memmove(p->trapframe, &p->alarmtrapframe, sizeof(struct trapframe));
    8000358c:	12000613          	li	a2,288
    80003590:	20848593          	addi	a1,s1,520
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	79a080e7          	jalr	1946(ra) # 80000d2e <memmove>
    p->trapframe->a0 = current_a0;
    8000359c:	6cbc                	ld	a5,88(s1)
    8000359e:	0727b823          	sd	s2,112(a5)
    p->in_alarm_handler = 0;
    800035a2:	3204a423          	sw	zero,808(s1)
    800035a6:	bfc1                	j	80003576 <sys_sigreturn+0x1a>

00000000800035a8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035a8:	7179                	addi	sp,sp,-48
    800035aa:	f406                	sd	ra,40(sp)
    800035ac:	f022                	sd	s0,32(sp)
    800035ae:	ec26                	sd	s1,24(sp)
    800035b0:	e84a                	sd	s2,16(sp)
    800035b2:	e44e                	sd	s3,8(sp)
    800035b4:	e052                	sd	s4,0(sp)
    800035b6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035b8:	00005597          	auipc	a1,0x5
    800035bc:	fd858593          	addi	a1,a1,-40 # 80008590 <syscalls+0xd8>
    800035c0:	0001b517          	auipc	a0,0x1b
    800035c4:	ab050513          	addi	a0,a0,-1360 # 8001e070 <bcache>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	57e080e7          	jalr	1406(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035d0:	00023797          	auipc	a5,0x23
    800035d4:	aa078793          	addi	a5,a5,-1376 # 80026070 <bcache+0x8000>
    800035d8:	00023717          	auipc	a4,0x23
    800035dc:	d0070713          	addi	a4,a4,-768 # 800262d8 <bcache+0x8268>
    800035e0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035e4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035e8:	0001b497          	auipc	s1,0x1b
    800035ec:	aa048493          	addi	s1,s1,-1376 # 8001e088 <bcache+0x18>
    b->next = bcache.head.next;
    800035f0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035f2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035f4:	00005a17          	auipc	s4,0x5
    800035f8:	fa4a0a13          	addi	s4,s4,-92 # 80008598 <syscalls+0xe0>
    b->next = bcache.head.next;
    800035fc:	2b893783          	ld	a5,696(s2)
    80003600:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003602:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003606:	85d2                	mv	a1,s4
    80003608:	01048513          	addi	a0,s1,16
    8000360c:	00001097          	auipc	ra,0x1
    80003610:	4c4080e7          	jalr	1220(ra) # 80004ad0 <initsleeplock>
    bcache.head.next->prev = b;
    80003614:	2b893783          	ld	a5,696(s2)
    80003618:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000361a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000361e:	45848493          	addi	s1,s1,1112
    80003622:	fd349de3          	bne	s1,s3,800035fc <binit+0x54>
  }
}
    80003626:	70a2                	ld	ra,40(sp)
    80003628:	7402                	ld	s0,32(sp)
    8000362a:	64e2                	ld	s1,24(sp)
    8000362c:	6942                	ld	s2,16(sp)
    8000362e:	69a2                	ld	s3,8(sp)
    80003630:	6a02                	ld	s4,0(sp)
    80003632:	6145                	addi	sp,sp,48
    80003634:	8082                	ret

0000000080003636 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003636:	7179                	addi	sp,sp,-48
    80003638:	f406                	sd	ra,40(sp)
    8000363a:	f022                	sd	s0,32(sp)
    8000363c:	ec26                	sd	s1,24(sp)
    8000363e:	e84a                	sd	s2,16(sp)
    80003640:	e44e                	sd	s3,8(sp)
    80003642:	1800                	addi	s0,sp,48
    80003644:	892a                	mv	s2,a0
    80003646:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003648:	0001b517          	auipc	a0,0x1b
    8000364c:	a2850513          	addi	a0,a0,-1496 # 8001e070 <bcache>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	586080e7          	jalr	1414(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003658:	00023497          	auipc	s1,0x23
    8000365c:	cd04b483          	ld	s1,-816(s1) # 80026328 <bcache+0x82b8>
    80003660:	00023797          	auipc	a5,0x23
    80003664:	c7878793          	addi	a5,a5,-904 # 800262d8 <bcache+0x8268>
    80003668:	02f48f63          	beq	s1,a5,800036a6 <bread+0x70>
    8000366c:	873e                	mv	a4,a5
    8000366e:	a021                	j	80003676 <bread+0x40>
    80003670:	68a4                	ld	s1,80(s1)
    80003672:	02e48a63          	beq	s1,a4,800036a6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003676:	449c                	lw	a5,8(s1)
    80003678:	ff279ce3          	bne	a5,s2,80003670 <bread+0x3a>
    8000367c:	44dc                	lw	a5,12(s1)
    8000367e:	ff3799e3          	bne	a5,s3,80003670 <bread+0x3a>
      b->refcnt++;
    80003682:	40bc                	lw	a5,64(s1)
    80003684:	2785                	addiw	a5,a5,1
    80003686:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003688:	0001b517          	auipc	a0,0x1b
    8000368c:	9e850513          	addi	a0,a0,-1560 # 8001e070 <bcache>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	5fa080e7          	jalr	1530(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003698:	01048513          	addi	a0,s1,16
    8000369c:	00001097          	auipc	ra,0x1
    800036a0:	46e080e7          	jalr	1134(ra) # 80004b0a <acquiresleep>
      return b;
    800036a4:	a8b9                	j	80003702 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036a6:	00023497          	auipc	s1,0x23
    800036aa:	c7a4b483          	ld	s1,-902(s1) # 80026320 <bcache+0x82b0>
    800036ae:	00023797          	auipc	a5,0x23
    800036b2:	c2a78793          	addi	a5,a5,-982 # 800262d8 <bcache+0x8268>
    800036b6:	00f48863          	beq	s1,a5,800036c6 <bread+0x90>
    800036ba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036bc:	40bc                	lw	a5,64(s1)
    800036be:	cf81                	beqz	a5,800036d6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036c0:	64a4                	ld	s1,72(s1)
    800036c2:	fee49de3          	bne	s1,a4,800036bc <bread+0x86>
  panic("bget: no buffers");
    800036c6:	00005517          	auipc	a0,0x5
    800036ca:	eda50513          	addi	a0,a0,-294 # 800085a0 <syscalls+0xe8>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	e70080e7          	jalr	-400(ra) # 8000053e <panic>
      b->dev = dev;
    800036d6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800036da:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800036de:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036e2:	4785                	li	a5,1
    800036e4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036e6:	0001b517          	auipc	a0,0x1b
    800036ea:	98a50513          	addi	a0,a0,-1654 # 8001e070 <bcache>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	59c080e7          	jalr	1436(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800036f6:	01048513          	addi	a0,s1,16
    800036fa:	00001097          	auipc	ra,0x1
    800036fe:	410080e7          	jalr	1040(ra) # 80004b0a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003702:	409c                	lw	a5,0(s1)
    80003704:	cb89                	beqz	a5,80003716 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003706:	8526                	mv	a0,s1
    80003708:	70a2                	ld	ra,40(sp)
    8000370a:	7402                	ld	s0,32(sp)
    8000370c:	64e2                	ld	s1,24(sp)
    8000370e:	6942                	ld	s2,16(sp)
    80003710:	69a2                	ld	s3,8(sp)
    80003712:	6145                	addi	sp,sp,48
    80003714:	8082                	ret
    virtio_disk_rw(b, 0);
    80003716:	4581                	li	a1,0
    80003718:	8526                	mv	a0,s1
    8000371a:	00003097          	auipc	ra,0x3
    8000371e:	fda080e7          	jalr	-38(ra) # 800066f4 <virtio_disk_rw>
    b->valid = 1;
    80003722:	4785                	li	a5,1
    80003724:	c09c                	sw	a5,0(s1)
  return b;
    80003726:	b7c5                	j	80003706 <bread+0xd0>

0000000080003728 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003728:	1101                	addi	sp,sp,-32
    8000372a:	ec06                	sd	ra,24(sp)
    8000372c:	e822                	sd	s0,16(sp)
    8000372e:	e426                	sd	s1,8(sp)
    80003730:	1000                	addi	s0,sp,32
    80003732:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003734:	0541                	addi	a0,a0,16
    80003736:	00001097          	auipc	ra,0x1
    8000373a:	46e080e7          	jalr	1134(ra) # 80004ba4 <holdingsleep>
    8000373e:	cd01                	beqz	a0,80003756 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003740:	4585                	li	a1,1
    80003742:	8526                	mv	a0,s1
    80003744:	00003097          	auipc	ra,0x3
    80003748:	fb0080e7          	jalr	-80(ra) # 800066f4 <virtio_disk_rw>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6105                	addi	sp,sp,32
    80003754:	8082                	ret
    panic("bwrite");
    80003756:	00005517          	auipc	a0,0x5
    8000375a:	e6250513          	addi	a0,a0,-414 # 800085b8 <syscalls+0x100>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	de0080e7          	jalr	-544(ra) # 8000053e <panic>

0000000080003766 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003766:	1101                	addi	sp,sp,-32
    80003768:	ec06                	sd	ra,24(sp)
    8000376a:	e822                	sd	s0,16(sp)
    8000376c:	e426                	sd	s1,8(sp)
    8000376e:	e04a                	sd	s2,0(sp)
    80003770:	1000                	addi	s0,sp,32
    80003772:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003774:	01050913          	addi	s2,a0,16
    80003778:	854a                	mv	a0,s2
    8000377a:	00001097          	auipc	ra,0x1
    8000377e:	42a080e7          	jalr	1066(ra) # 80004ba4 <holdingsleep>
    80003782:	c92d                	beqz	a0,800037f4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003784:	854a                	mv	a0,s2
    80003786:	00001097          	auipc	ra,0x1
    8000378a:	3da080e7          	jalr	986(ra) # 80004b60 <releasesleep>

  acquire(&bcache.lock);
    8000378e:	0001b517          	auipc	a0,0x1b
    80003792:	8e250513          	addi	a0,a0,-1822 # 8001e070 <bcache>
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	440080e7          	jalr	1088(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000379e:	40bc                	lw	a5,64(s1)
    800037a0:	37fd                	addiw	a5,a5,-1
    800037a2:	0007871b          	sext.w	a4,a5
    800037a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037a8:	eb05                	bnez	a4,800037d8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037aa:	68bc                	ld	a5,80(s1)
    800037ac:	64b8                	ld	a4,72(s1)
    800037ae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037b0:	64bc                	ld	a5,72(s1)
    800037b2:	68b8                	ld	a4,80(s1)
    800037b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037b6:	00023797          	auipc	a5,0x23
    800037ba:	8ba78793          	addi	a5,a5,-1862 # 80026070 <bcache+0x8000>
    800037be:	2b87b703          	ld	a4,696(a5)
    800037c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037c4:	00023717          	auipc	a4,0x23
    800037c8:	b1470713          	addi	a4,a4,-1260 # 800262d8 <bcache+0x8268>
    800037cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037ce:	2b87b703          	ld	a4,696(a5)
    800037d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037d8:	0001b517          	auipc	a0,0x1b
    800037dc:	89850513          	addi	a0,a0,-1896 # 8001e070 <bcache>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	4aa080e7          	jalr	1194(ra) # 80000c8a <release>
}
    800037e8:	60e2                	ld	ra,24(sp)
    800037ea:	6442                	ld	s0,16(sp)
    800037ec:	64a2                	ld	s1,8(sp)
    800037ee:	6902                	ld	s2,0(sp)
    800037f0:	6105                	addi	sp,sp,32
    800037f2:	8082                	ret
    panic("brelse");
    800037f4:	00005517          	auipc	a0,0x5
    800037f8:	dcc50513          	addi	a0,a0,-564 # 800085c0 <syscalls+0x108>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	d42080e7          	jalr	-702(ra) # 8000053e <panic>

0000000080003804 <bpin>:

void
bpin(struct buf *b) {
    80003804:	1101                	addi	sp,sp,-32
    80003806:	ec06                	sd	ra,24(sp)
    80003808:	e822                	sd	s0,16(sp)
    8000380a:	e426                	sd	s1,8(sp)
    8000380c:	1000                	addi	s0,sp,32
    8000380e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003810:	0001b517          	auipc	a0,0x1b
    80003814:	86050513          	addi	a0,a0,-1952 # 8001e070 <bcache>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	3be080e7          	jalr	958(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003820:	40bc                	lw	a5,64(s1)
    80003822:	2785                	addiw	a5,a5,1
    80003824:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003826:	0001b517          	auipc	a0,0x1b
    8000382a:	84a50513          	addi	a0,a0,-1974 # 8001e070 <bcache>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	45c080e7          	jalr	1116(ra) # 80000c8a <release>
}
    80003836:	60e2                	ld	ra,24(sp)
    80003838:	6442                	ld	s0,16(sp)
    8000383a:	64a2                	ld	s1,8(sp)
    8000383c:	6105                	addi	sp,sp,32
    8000383e:	8082                	ret

0000000080003840 <bunpin>:

void
bunpin(struct buf *b) {
    80003840:	1101                	addi	sp,sp,-32
    80003842:	ec06                	sd	ra,24(sp)
    80003844:	e822                	sd	s0,16(sp)
    80003846:	e426                	sd	s1,8(sp)
    80003848:	1000                	addi	s0,sp,32
    8000384a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000384c:	0001b517          	auipc	a0,0x1b
    80003850:	82450513          	addi	a0,a0,-2012 # 8001e070 <bcache>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	382080e7          	jalr	898(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000385c:	40bc                	lw	a5,64(s1)
    8000385e:	37fd                	addiw	a5,a5,-1
    80003860:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003862:	0001b517          	auipc	a0,0x1b
    80003866:	80e50513          	addi	a0,a0,-2034 # 8001e070 <bcache>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	420080e7          	jalr	1056(ra) # 80000c8a <release>
}
    80003872:	60e2                	ld	ra,24(sp)
    80003874:	6442                	ld	s0,16(sp)
    80003876:	64a2                	ld	s1,8(sp)
    80003878:	6105                	addi	sp,sp,32
    8000387a:	8082                	ret

000000008000387c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000387c:	1101                	addi	sp,sp,-32
    8000387e:	ec06                	sd	ra,24(sp)
    80003880:	e822                	sd	s0,16(sp)
    80003882:	e426                	sd	s1,8(sp)
    80003884:	e04a                	sd	s2,0(sp)
    80003886:	1000                	addi	s0,sp,32
    80003888:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000388a:	00d5d59b          	srliw	a1,a1,0xd
    8000388e:	00023797          	auipc	a5,0x23
    80003892:	ebe7a783          	lw	a5,-322(a5) # 8002674c <sb+0x1c>
    80003896:	9dbd                	addw	a1,a1,a5
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	d9e080e7          	jalr	-610(ra) # 80003636 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800038a0:	0074f713          	andi	a4,s1,7
    800038a4:	4785                	li	a5,1
    800038a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038aa:	14ce                	slli	s1,s1,0x33
    800038ac:	90d9                	srli	s1,s1,0x36
    800038ae:	00950733          	add	a4,a0,s1
    800038b2:	05874703          	lbu	a4,88(a4)
    800038b6:	00e7f6b3          	and	a3,a5,a4
    800038ba:	c69d                	beqz	a3,800038e8 <bfree+0x6c>
    800038bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038be:	94aa                	add	s1,s1,a0
    800038c0:	fff7c793          	not	a5,a5
    800038c4:	8ff9                	and	a5,a5,a4
    800038c6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038ca:	00001097          	auipc	ra,0x1
    800038ce:	120080e7          	jalr	288(ra) # 800049ea <log_write>
  brelse(bp);
    800038d2:	854a                	mv	a0,s2
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	e92080e7          	jalr	-366(ra) # 80003766 <brelse>
}
    800038dc:	60e2                	ld	ra,24(sp)
    800038de:	6442                	ld	s0,16(sp)
    800038e0:	64a2                	ld	s1,8(sp)
    800038e2:	6902                	ld	s2,0(sp)
    800038e4:	6105                	addi	sp,sp,32
    800038e6:	8082                	ret
    panic("freeing free block");
    800038e8:	00005517          	auipc	a0,0x5
    800038ec:	ce050513          	addi	a0,a0,-800 # 800085c8 <syscalls+0x110>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	c4e080e7          	jalr	-946(ra) # 8000053e <panic>

00000000800038f8 <balloc>:
{
    800038f8:	711d                	addi	sp,sp,-96
    800038fa:	ec86                	sd	ra,88(sp)
    800038fc:	e8a2                	sd	s0,80(sp)
    800038fe:	e4a6                	sd	s1,72(sp)
    80003900:	e0ca                	sd	s2,64(sp)
    80003902:	fc4e                	sd	s3,56(sp)
    80003904:	f852                	sd	s4,48(sp)
    80003906:	f456                	sd	s5,40(sp)
    80003908:	f05a                	sd	s6,32(sp)
    8000390a:	ec5e                	sd	s7,24(sp)
    8000390c:	e862                	sd	s8,16(sp)
    8000390e:	e466                	sd	s9,8(sp)
    80003910:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003912:	00023797          	auipc	a5,0x23
    80003916:	e227a783          	lw	a5,-478(a5) # 80026734 <sb+0x4>
    8000391a:	10078163          	beqz	a5,80003a1c <balloc+0x124>
    8000391e:	8baa                	mv	s7,a0
    80003920:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003922:	00023b17          	auipc	s6,0x23
    80003926:	e0eb0b13          	addi	s6,s6,-498 # 80026730 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000392a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000392c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000392e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003930:	6c89                	lui	s9,0x2
    80003932:	a061                	j	800039ba <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003934:	974a                	add	a4,a4,s2
    80003936:	8fd5                	or	a5,a5,a3
    80003938:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000393c:	854a                	mv	a0,s2
    8000393e:	00001097          	auipc	ra,0x1
    80003942:	0ac080e7          	jalr	172(ra) # 800049ea <log_write>
        brelse(bp);
    80003946:	854a                	mv	a0,s2
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	e1e080e7          	jalr	-482(ra) # 80003766 <brelse>
  bp = bread(dev, bno);
    80003950:	85a6                	mv	a1,s1
    80003952:	855e                	mv	a0,s7
    80003954:	00000097          	auipc	ra,0x0
    80003958:	ce2080e7          	jalr	-798(ra) # 80003636 <bread>
    8000395c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000395e:	40000613          	li	a2,1024
    80003962:	4581                	li	a1,0
    80003964:	05850513          	addi	a0,a0,88
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	36a080e7          	jalr	874(ra) # 80000cd2 <memset>
  log_write(bp);
    80003970:	854a                	mv	a0,s2
    80003972:	00001097          	auipc	ra,0x1
    80003976:	078080e7          	jalr	120(ra) # 800049ea <log_write>
  brelse(bp);
    8000397a:	854a                	mv	a0,s2
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	dea080e7          	jalr	-534(ra) # 80003766 <brelse>
}
    80003984:	8526                	mv	a0,s1
    80003986:	60e6                	ld	ra,88(sp)
    80003988:	6446                	ld	s0,80(sp)
    8000398a:	64a6                	ld	s1,72(sp)
    8000398c:	6906                	ld	s2,64(sp)
    8000398e:	79e2                	ld	s3,56(sp)
    80003990:	7a42                	ld	s4,48(sp)
    80003992:	7aa2                	ld	s5,40(sp)
    80003994:	7b02                	ld	s6,32(sp)
    80003996:	6be2                	ld	s7,24(sp)
    80003998:	6c42                	ld	s8,16(sp)
    8000399a:	6ca2                	ld	s9,8(sp)
    8000399c:	6125                	addi	sp,sp,96
    8000399e:	8082                	ret
    brelse(bp);
    800039a0:	854a                	mv	a0,s2
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	dc4080e7          	jalr	-572(ra) # 80003766 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039aa:	015c87bb          	addw	a5,s9,s5
    800039ae:	00078a9b          	sext.w	s5,a5
    800039b2:	004b2703          	lw	a4,4(s6)
    800039b6:	06eaf363          	bgeu	s5,a4,80003a1c <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800039ba:	41fad79b          	sraiw	a5,s5,0x1f
    800039be:	0137d79b          	srliw	a5,a5,0x13
    800039c2:	015787bb          	addw	a5,a5,s5
    800039c6:	40d7d79b          	sraiw	a5,a5,0xd
    800039ca:	01cb2583          	lw	a1,28(s6)
    800039ce:	9dbd                	addw	a1,a1,a5
    800039d0:	855e                	mv	a0,s7
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	c64080e7          	jalr	-924(ra) # 80003636 <bread>
    800039da:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039dc:	004b2503          	lw	a0,4(s6)
    800039e0:	000a849b          	sext.w	s1,s5
    800039e4:	8662                	mv	a2,s8
    800039e6:	faa4fde3          	bgeu	s1,a0,800039a0 <balloc+0xa8>
      m = 1 << (bi % 8);
    800039ea:	41f6579b          	sraiw	a5,a2,0x1f
    800039ee:	01d7d69b          	srliw	a3,a5,0x1d
    800039f2:	00c6873b          	addw	a4,a3,a2
    800039f6:	00777793          	andi	a5,a4,7
    800039fa:	9f95                	subw	a5,a5,a3
    800039fc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a00:	4037571b          	sraiw	a4,a4,0x3
    80003a04:	00e906b3          	add	a3,s2,a4
    80003a08:	0586c683          	lbu	a3,88(a3)
    80003a0c:	00d7f5b3          	and	a1,a5,a3
    80003a10:	d195                	beqz	a1,80003934 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a12:	2605                	addiw	a2,a2,1
    80003a14:	2485                	addiw	s1,s1,1
    80003a16:	fd4618e3          	bne	a2,s4,800039e6 <balloc+0xee>
    80003a1a:	b759                	j	800039a0 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003a1c:	00005517          	auipc	a0,0x5
    80003a20:	bc450513          	addi	a0,a0,-1084 # 800085e0 <syscalls+0x128>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	b64080e7          	jalr	-1180(ra) # 80000588 <printf>
  return 0;
    80003a2c:	4481                	li	s1,0
    80003a2e:	bf99                	j	80003984 <balloc+0x8c>

0000000080003a30 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a30:	7179                	addi	sp,sp,-48
    80003a32:	f406                	sd	ra,40(sp)
    80003a34:	f022                	sd	s0,32(sp)
    80003a36:	ec26                	sd	s1,24(sp)
    80003a38:	e84a                	sd	s2,16(sp)
    80003a3a:	e44e                	sd	s3,8(sp)
    80003a3c:	e052                	sd	s4,0(sp)
    80003a3e:	1800                	addi	s0,sp,48
    80003a40:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a42:	47ad                	li	a5,11
    80003a44:	02b7e763          	bltu	a5,a1,80003a72 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003a48:	02059493          	slli	s1,a1,0x20
    80003a4c:	9081                	srli	s1,s1,0x20
    80003a4e:	048a                	slli	s1,s1,0x2
    80003a50:	94aa                	add	s1,s1,a0
    80003a52:	0504a903          	lw	s2,80(s1)
    80003a56:	06091e63          	bnez	s2,80003ad2 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003a5a:	4108                	lw	a0,0(a0)
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	e9c080e7          	jalr	-356(ra) # 800038f8 <balloc>
    80003a64:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a68:	06090563          	beqz	s2,80003ad2 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003a6c:	0524a823          	sw	s2,80(s1)
    80003a70:	a08d                	j	80003ad2 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003a72:	ff45849b          	addiw	s1,a1,-12
    80003a76:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a7a:	0ff00793          	li	a5,255
    80003a7e:	08e7e563          	bltu	a5,a4,80003b08 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003a82:	08052903          	lw	s2,128(a0)
    80003a86:	00091d63          	bnez	s2,80003aa0 <bmap+0x70>
      addr = balloc(ip->dev);
    80003a8a:	4108                	lw	a0,0(a0)
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	e6c080e7          	jalr	-404(ra) # 800038f8 <balloc>
    80003a94:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a98:	02090d63          	beqz	s2,80003ad2 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a9c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003aa0:	85ca                	mv	a1,s2
    80003aa2:	0009a503          	lw	a0,0(s3)
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	b90080e7          	jalr	-1136(ra) # 80003636 <bread>
    80003aae:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ab0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ab4:	02049593          	slli	a1,s1,0x20
    80003ab8:	9181                	srli	a1,a1,0x20
    80003aba:	058a                	slli	a1,a1,0x2
    80003abc:	00b784b3          	add	s1,a5,a1
    80003ac0:	0004a903          	lw	s2,0(s1)
    80003ac4:	02090063          	beqz	s2,80003ae4 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003ac8:	8552                	mv	a0,s4
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	c9c080e7          	jalr	-868(ra) # 80003766 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ad2:	854a                	mv	a0,s2
    80003ad4:	70a2                	ld	ra,40(sp)
    80003ad6:	7402                	ld	s0,32(sp)
    80003ad8:	64e2                	ld	s1,24(sp)
    80003ada:	6942                	ld	s2,16(sp)
    80003adc:	69a2                	ld	s3,8(sp)
    80003ade:	6a02                	ld	s4,0(sp)
    80003ae0:	6145                	addi	sp,sp,48
    80003ae2:	8082                	ret
      addr = balloc(ip->dev);
    80003ae4:	0009a503          	lw	a0,0(s3)
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	e10080e7          	jalr	-496(ra) # 800038f8 <balloc>
    80003af0:	0005091b          	sext.w	s2,a0
      if(addr){
    80003af4:	fc090ae3          	beqz	s2,80003ac8 <bmap+0x98>
        a[bn] = addr;
    80003af8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003afc:	8552                	mv	a0,s4
    80003afe:	00001097          	auipc	ra,0x1
    80003b02:	eec080e7          	jalr	-276(ra) # 800049ea <log_write>
    80003b06:	b7c9                	j	80003ac8 <bmap+0x98>
  panic("bmap: out of range");
    80003b08:	00005517          	auipc	a0,0x5
    80003b0c:	af050513          	addi	a0,a0,-1296 # 800085f8 <syscalls+0x140>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	a2e080e7          	jalr	-1490(ra) # 8000053e <panic>

0000000080003b18 <iget>:
{
    80003b18:	7179                	addi	sp,sp,-48
    80003b1a:	f406                	sd	ra,40(sp)
    80003b1c:	f022                	sd	s0,32(sp)
    80003b1e:	ec26                	sd	s1,24(sp)
    80003b20:	e84a                	sd	s2,16(sp)
    80003b22:	e44e                	sd	s3,8(sp)
    80003b24:	e052                	sd	s4,0(sp)
    80003b26:	1800                	addi	s0,sp,48
    80003b28:	89aa                	mv	s3,a0
    80003b2a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b2c:	00023517          	auipc	a0,0x23
    80003b30:	c2450513          	addi	a0,a0,-988 # 80026750 <itable>
    80003b34:	ffffd097          	auipc	ra,0xffffd
    80003b38:	0a2080e7          	jalr	162(ra) # 80000bd6 <acquire>
  empty = 0;
    80003b3c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b3e:	00023497          	auipc	s1,0x23
    80003b42:	c2a48493          	addi	s1,s1,-982 # 80026768 <itable+0x18>
    80003b46:	00024697          	auipc	a3,0x24
    80003b4a:	6b268693          	addi	a3,a3,1714 # 800281f8 <log>
    80003b4e:	a039                	j	80003b5c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b50:	02090b63          	beqz	s2,80003b86 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b54:	08848493          	addi	s1,s1,136
    80003b58:	02d48a63          	beq	s1,a3,80003b8c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b5c:	449c                	lw	a5,8(s1)
    80003b5e:	fef059e3          	blez	a5,80003b50 <iget+0x38>
    80003b62:	4098                	lw	a4,0(s1)
    80003b64:	ff3716e3          	bne	a4,s3,80003b50 <iget+0x38>
    80003b68:	40d8                	lw	a4,4(s1)
    80003b6a:	ff4713e3          	bne	a4,s4,80003b50 <iget+0x38>
      ip->ref++;
    80003b6e:	2785                	addiw	a5,a5,1
    80003b70:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b72:	00023517          	auipc	a0,0x23
    80003b76:	bde50513          	addi	a0,a0,-1058 # 80026750 <itable>
    80003b7a:	ffffd097          	auipc	ra,0xffffd
    80003b7e:	110080e7          	jalr	272(ra) # 80000c8a <release>
      return ip;
    80003b82:	8926                	mv	s2,s1
    80003b84:	a03d                	j	80003bb2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b86:	f7f9                	bnez	a5,80003b54 <iget+0x3c>
    80003b88:	8926                	mv	s2,s1
    80003b8a:	b7e9                	j	80003b54 <iget+0x3c>
  if(empty == 0)
    80003b8c:	02090c63          	beqz	s2,80003bc4 <iget+0xac>
  ip->dev = dev;
    80003b90:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b94:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b98:	4785                	li	a5,1
    80003b9a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b9e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ba2:	00023517          	auipc	a0,0x23
    80003ba6:	bae50513          	addi	a0,a0,-1106 # 80026750 <itable>
    80003baa:	ffffd097          	auipc	ra,0xffffd
    80003bae:	0e0080e7          	jalr	224(ra) # 80000c8a <release>
}
    80003bb2:	854a                	mv	a0,s2
    80003bb4:	70a2                	ld	ra,40(sp)
    80003bb6:	7402                	ld	s0,32(sp)
    80003bb8:	64e2                	ld	s1,24(sp)
    80003bba:	6942                	ld	s2,16(sp)
    80003bbc:	69a2                	ld	s3,8(sp)
    80003bbe:	6a02                	ld	s4,0(sp)
    80003bc0:	6145                	addi	sp,sp,48
    80003bc2:	8082                	ret
    panic("iget: no inodes");
    80003bc4:	00005517          	auipc	a0,0x5
    80003bc8:	a4c50513          	addi	a0,a0,-1460 # 80008610 <syscalls+0x158>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	972080e7          	jalr	-1678(ra) # 8000053e <panic>

0000000080003bd4 <fsinit>:
fsinit(int dev) {
    80003bd4:	7179                	addi	sp,sp,-48
    80003bd6:	f406                	sd	ra,40(sp)
    80003bd8:	f022                	sd	s0,32(sp)
    80003bda:	ec26                	sd	s1,24(sp)
    80003bdc:	e84a                	sd	s2,16(sp)
    80003bde:	e44e                	sd	s3,8(sp)
    80003be0:	1800                	addi	s0,sp,48
    80003be2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003be4:	4585                	li	a1,1
    80003be6:	00000097          	auipc	ra,0x0
    80003bea:	a50080e7          	jalr	-1456(ra) # 80003636 <bread>
    80003bee:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bf0:	00023997          	auipc	s3,0x23
    80003bf4:	b4098993          	addi	s3,s3,-1216 # 80026730 <sb>
    80003bf8:	02000613          	li	a2,32
    80003bfc:	05850593          	addi	a1,a0,88
    80003c00:	854e                	mv	a0,s3
    80003c02:	ffffd097          	auipc	ra,0xffffd
    80003c06:	12c080e7          	jalr	300(ra) # 80000d2e <memmove>
  brelse(bp);
    80003c0a:	8526                	mv	a0,s1
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	b5a080e7          	jalr	-1190(ra) # 80003766 <brelse>
  if(sb.magic != FSMAGIC)
    80003c14:	0009a703          	lw	a4,0(s3)
    80003c18:	102037b7          	lui	a5,0x10203
    80003c1c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c20:	02f71263          	bne	a4,a5,80003c44 <fsinit+0x70>
  initlog(dev, &sb);
    80003c24:	00023597          	auipc	a1,0x23
    80003c28:	b0c58593          	addi	a1,a1,-1268 # 80026730 <sb>
    80003c2c:	854a                	mv	a0,s2
    80003c2e:	00001097          	auipc	ra,0x1
    80003c32:	b40080e7          	jalr	-1216(ra) # 8000476e <initlog>
}
    80003c36:	70a2                	ld	ra,40(sp)
    80003c38:	7402                	ld	s0,32(sp)
    80003c3a:	64e2                	ld	s1,24(sp)
    80003c3c:	6942                	ld	s2,16(sp)
    80003c3e:	69a2                	ld	s3,8(sp)
    80003c40:	6145                	addi	sp,sp,48
    80003c42:	8082                	ret
    panic("invalid file system");
    80003c44:	00005517          	auipc	a0,0x5
    80003c48:	9dc50513          	addi	a0,a0,-1572 # 80008620 <syscalls+0x168>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	8f2080e7          	jalr	-1806(ra) # 8000053e <panic>

0000000080003c54 <iinit>:
{
    80003c54:	7179                	addi	sp,sp,-48
    80003c56:	f406                	sd	ra,40(sp)
    80003c58:	f022                	sd	s0,32(sp)
    80003c5a:	ec26                	sd	s1,24(sp)
    80003c5c:	e84a                	sd	s2,16(sp)
    80003c5e:	e44e                	sd	s3,8(sp)
    80003c60:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c62:	00005597          	auipc	a1,0x5
    80003c66:	9d658593          	addi	a1,a1,-1578 # 80008638 <syscalls+0x180>
    80003c6a:	00023517          	auipc	a0,0x23
    80003c6e:	ae650513          	addi	a0,a0,-1306 # 80026750 <itable>
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	ed4080e7          	jalr	-300(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c7a:	00023497          	auipc	s1,0x23
    80003c7e:	afe48493          	addi	s1,s1,-1282 # 80026778 <itable+0x28>
    80003c82:	00024997          	auipc	s3,0x24
    80003c86:	58698993          	addi	s3,s3,1414 # 80028208 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c8a:	00005917          	auipc	s2,0x5
    80003c8e:	9b690913          	addi	s2,s2,-1610 # 80008640 <syscalls+0x188>
    80003c92:	85ca                	mv	a1,s2
    80003c94:	8526                	mv	a0,s1
    80003c96:	00001097          	auipc	ra,0x1
    80003c9a:	e3a080e7          	jalr	-454(ra) # 80004ad0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c9e:	08848493          	addi	s1,s1,136
    80003ca2:	ff3498e3          	bne	s1,s3,80003c92 <iinit+0x3e>
}
    80003ca6:	70a2                	ld	ra,40(sp)
    80003ca8:	7402                	ld	s0,32(sp)
    80003caa:	64e2                	ld	s1,24(sp)
    80003cac:	6942                	ld	s2,16(sp)
    80003cae:	69a2                	ld	s3,8(sp)
    80003cb0:	6145                	addi	sp,sp,48
    80003cb2:	8082                	ret

0000000080003cb4 <ialloc>:
{
    80003cb4:	715d                	addi	sp,sp,-80
    80003cb6:	e486                	sd	ra,72(sp)
    80003cb8:	e0a2                	sd	s0,64(sp)
    80003cba:	fc26                	sd	s1,56(sp)
    80003cbc:	f84a                	sd	s2,48(sp)
    80003cbe:	f44e                	sd	s3,40(sp)
    80003cc0:	f052                	sd	s4,32(sp)
    80003cc2:	ec56                	sd	s5,24(sp)
    80003cc4:	e85a                	sd	s6,16(sp)
    80003cc6:	e45e                	sd	s7,8(sp)
    80003cc8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cca:	00023717          	auipc	a4,0x23
    80003cce:	a7272703          	lw	a4,-1422(a4) # 8002673c <sb+0xc>
    80003cd2:	4785                	li	a5,1
    80003cd4:	04e7fa63          	bgeu	a5,a4,80003d28 <ialloc+0x74>
    80003cd8:	8aaa                	mv	s5,a0
    80003cda:	8bae                	mv	s7,a1
    80003cdc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003cde:	00023a17          	auipc	s4,0x23
    80003ce2:	a52a0a13          	addi	s4,s4,-1454 # 80026730 <sb>
    80003ce6:	00048b1b          	sext.w	s6,s1
    80003cea:	0044d793          	srli	a5,s1,0x4
    80003cee:	018a2583          	lw	a1,24(s4)
    80003cf2:	9dbd                	addw	a1,a1,a5
    80003cf4:	8556                	mv	a0,s5
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	940080e7          	jalr	-1728(ra) # 80003636 <bread>
    80003cfe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d00:	05850993          	addi	s3,a0,88
    80003d04:	00f4f793          	andi	a5,s1,15
    80003d08:	079a                	slli	a5,a5,0x6
    80003d0a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d0c:	00099783          	lh	a5,0(s3)
    80003d10:	c3a1                	beqz	a5,80003d50 <ialloc+0x9c>
    brelse(bp);
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	a54080e7          	jalr	-1452(ra) # 80003766 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d1a:	0485                	addi	s1,s1,1
    80003d1c:	00ca2703          	lw	a4,12(s4)
    80003d20:	0004879b          	sext.w	a5,s1
    80003d24:	fce7e1e3          	bltu	a5,a4,80003ce6 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003d28:	00005517          	auipc	a0,0x5
    80003d2c:	92050513          	addi	a0,a0,-1760 # 80008648 <syscalls+0x190>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	858080e7          	jalr	-1960(ra) # 80000588 <printf>
  return 0;
    80003d38:	4501                	li	a0,0
}
    80003d3a:	60a6                	ld	ra,72(sp)
    80003d3c:	6406                	ld	s0,64(sp)
    80003d3e:	74e2                	ld	s1,56(sp)
    80003d40:	7942                	ld	s2,48(sp)
    80003d42:	79a2                	ld	s3,40(sp)
    80003d44:	7a02                	ld	s4,32(sp)
    80003d46:	6ae2                	ld	s5,24(sp)
    80003d48:	6b42                	ld	s6,16(sp)
    80003d4a:	6ba2                	ld	s7,8(sp)
    80003d4c:	6161                	addi	sp,sp,80
    80003d4e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003d50:	04000613          	li	a2,64
    80003d54:	4581                	li	a1,0
    80003d56:	854e                	mv	a0,s3
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	f7a080e7          	jalr	-134(ra) # 80000cd2 <memset>
      dip->type = type;
    80003d60:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d64:	854a                	mv	a0,s2
    80003d66:	00001097          	auipc	ra,0x1
    80003d6a:	c84080e7          	jalr	-892(ra) # 800049ea <log_write>
      brelse(bp);
    80003d6e:	854a                	mv	a0,s2
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	9f6080e7          	jalr	-1546(ra) # 80003766 <brelse>
      return iget(dev, inum);
    80003d78:	85da                	mv	a1,s6
    80003d7a:	8556                	mv	a0,s5
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	d9c080e7          	jalr	-612(ra) # 80003b18 <iget>
    80003d84:	bf5d                	j	80003d3a <ialloc+0x86>

0000000080003d86 <iupdate>:
{
    80003d86:	1101                	addi	sp,sp,-32
    80003d88:	ec06                	sd	ra,24(sp)
    80003d8a:	e822                	sd	s0,16(sp)
    80003d8c:	e426                	sd	s1,8(sp)
    80003d8e:	e04a                	sd	s2,0(sp)
    80003d90:	1000                	addi	s0,sp,32
    80003d92:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d94:	415c                	lw	a5,4(a0)
    80003d96:	0047d79b          	srliw	a5,a5,0x4
    80003d9a:	00023597          	auipc	a1,0x23
    80003d9e:	9ae5a583          	lw	a1,-1618(a1) # 80026748 <sb+0x18>
    80003da2:	9dbd                	addw	a1,a1,a5
    80003da4:	4108                	lw	a0,0(a0)
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	890080e7          	jalr	-1904(ra) # 80003636 <bread>
    80003dae:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003db0:	05850793          	addi	a5,a0,88
    80003db4:	40c8                	lw	a0,4(s1)
    80003db6:	893d                	andi	a0,a0,15
    80003db8:	051a                	slli	a0,a0,0x6
    80003dba:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003dbc:	04449703          	lh	a4,68(s1)
    80003dc0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003dc4:	04649703          	lh	a4,70(s1)
    80003dc8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003dcc:	04849703          	lh	a4,72(s1)
    80003dd0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003dd4:	04a49703          	lh	a4,74(s1)
    80003dd8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ddc:	44f8                	lw	a4,76(s1)
    80003dde:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003de0:	03400613          	li	a2,52
    80003de4:	05048593          	addi	a1,s1,80
    80003de8:	0531                	addi	a0,a0,12
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	f44080e7          	jalr	-188(ra) # 80000d2e <memmove>
  log_write(bp);
    80003df2:	854a                	mv	a0,s2
    80003df4:	00001097          	auipc	ra,0x1
    80003df8:	bf6080e7          	jalr	-1034(ra) # 800049ea <log_write>
  brelse(bp);
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	968080e7          	jalr	-1688(ra) # 80003766 <brelse>
}
    80003e06:	60e2                	ld	ra,24(sp)
    80003e08:	6442                	ld	s0,16(sp)
    80003e0a:	64a2                	ld	s1,8(sp)
    80003e0c:	6902                	ld	s2,0(sp)
    80003e0e:	6105                	addi	sp,sp,32
    80003e10:	8082                	ret

0000000080003e12 <idup>:
{
    80003e12:	1101                	addi	sp,sp,-32
    80003e14:	ec06                	sd	ra,24(sp)
    80003e16:	e822                	sd	s0,16(sp)
    80003e18:	e426                	sd	s1,8(sp)
    80003e1a:	1000                	addi	s0,sp,32
    80003e1c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e1e:	00023517          	auipc	a0,0x23
    80003e22:	93250513          	addi	a0,a0,-1742 # 80026750 <itable>
    80003e26:	ffffd097          	auipc	ra,0xffffd
    80003e2a:	db0080e7          	jalr	-592(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003e2e:	449c                	lw	a5,8(s1)
    80003e30:	2785                	addiw	a5,a5,1
    80003e32:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e34:	00023517          	auipc	a0,0x23
    80003e38:	91c50513          	addi	a0,a0,-1764 # 80026750 <itable>
    80003e3c:	ffffd097          	auipc	ra,0xffffd
    80003e40:	e4e080e7          	jalr	-434(ra) # 80000c8a <release>
}
    80003e44:	8526                	mv	a0,s1
    80003e46:	60e2                	ld	ra,24(sp)
    80003e48:	6442                	ld	s0,16(sp)
    80003e4a:	64a2                	ld	s1,8(sp)
    80003e4c:	6105                	addi	sp,sp,32
    80003e4e:	8082                	ret

0000000080003e50 <ilock>:
{
    80003e50:	1101                	addi	sp,sp,-32
    80003e52:	ec06                	sd	ra,24(sp)
    80003e54:	e822                	sd	s0,16(sp)
    80003e56:	e426                	sd	s1,8(sp)
    80003e58:	e04a                	sd	s2,0(sp)
    80003e5a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e5c:	c115                	beqz	a0,80003e80 <ilock+0x30>
    80003e5e:	84aa                	mv	s1,a0
    80003e60:	451c                	lw	a5,8(a0)
    80003e62:	00f05f63          	blez	a5,80003e80 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e66:	0541                	addi	a0,a0,16
    80003e68:	00001097          	auipc	ra,0x1
    80003e6c:	ca2080e7          	jalr	-862(ra) # 80004b0a <acquiresleep>
  if(ip->valid == 0){
    80003e70:	40bc                	lw	a5,64(s1)
    80003e72:	cf99                	beqz	a5,80003e90 <ilock+0x40>
}
    80003e74:	60e2                	ld	ra,24(sp)
    80003e76:	6442                	ld	s0,16(sp)
    80003e78:	64a2                	ld	s1,8(sp)
    80003e7a:	6902                	ld	s2,0(sp)
    80003e7c:	6105                	addi	sp,sp,32
    80003e7e:	8082                	ret
    panic("ilock");
    80003e80:	00004517          	auipc	a0,0x4
    80003e84:	7e050513          	addi	a0,a0,2016 # 80008660 <syscalls+0x1a8>
    80003e88:	ffffc097          	auipc	ra,0xffffc
    80003e8c:	6b6080e7          	jalr	1718(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e90:	40dc                	lw	a5,4(s1)
    80003e92:	0047d79b          	srliw	a5,a5,0x4
    80003e96:	00023597          	auipc	a1,0x23
    80003e9a:	8b25a583          	lw	a1,-1870(a1) # 80026748 <sb+0x18>
    80003e9e:	9dbd                	addw	a1,a1,a5
    80003ea0:	4088                	lw	a0,0(s1)
    80003ea2:	fffff097          	auipc	ra,0xfffff
    80003ea6:	794080e7          	jalr	1940(ra) # 80003636 <bread>
    80003eaa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003eac:	05850593          	addi	a1,a0,88
    80003eb0:	40dc                	lw	a5,4(s1)
    80003eb2:	8bbd                	andi	a5,a5,15
    80003eb4:	079a                	slli	a5,a5,0x6
    80003eb6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003eb8:	00059783          	lh	a5,0(a1)
    80003ebc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ec0:	00259783          	lh	a5,2(a1)
    80003ec4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ec8:	00459783          	lh	a5,4(a1)
    80003ecc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ed0:	00659783          	lh	a5,6(a1)
    80003ed4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ed8:	459c                	lw	a5,8(a1)
    80003eda:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003edc:	03400613          	li	a2,52
    80003ee0:	05b1                	addi	a1,a1,12
    80003ee2:	05048513          	addi	a0,s1,80
    80003ee6:	ffffd097          	auipc	ra,0xffffd
    80003eea:	e48080e7          	jalr	-440(ra) # 80000d2e <memmove>
    brelse(bp);
    80003eee:	854a                	mv	a0,s2
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	876080e7          	jalr	-1930(ra) # 80003766 <brelse>
    ip->valid = 1;
    80003ef8:	4785                	li	a5,1
    80003efa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003efc:	04449783          	lh	a5,68(s1)
    80003f00:	fbb5                	bnez	a5,80003e74 <ilock+0x24>
      panic("ilock: no type");
    80003f02:	00004517          	auipc	a0,0x4
    80003f06:	76650513          	addi	a0,a0,1894 # 80008668 <syscalls+0x1b0>
    80003f0a:	ffffc097          	auipc	ra,0xffffc
    80003f0e:	634080e7          	jalr	1588(ra) # 8000053e <panic>

0000000080003f12 <iunlock>:
{
    80003f12:	1101                	addi	sp,sp,-32
    80003f14:	ec06                	sd	ra,24(sp)
    80003f16:	e822                	sd	s0,16(sp)
    80003f18:	e426                	sd	s1,8(sp)
    80003f1a:	e04a                	sd	s2,0(sp)
    80003f1c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f1e:	c905                	beqz	a0,80003f4e <iunlock+0x3c>
    80003f20:	84aa                	mv	s1,a0
    80003f22:	01050913          	addi	s2,a0,16
    80003f26:	854a                	mv	a0,s2
    80003f28:	00001097          	auipc	ra,0x1
    80003f2c:	c7c080e7          	jalr	-900(ra) # 80004ba4 <holdingsleep>
    80003f30:	cd19                	beqz	a0,80003f4e <iunlock+0x3c>
    80003f32:	449c                	lw	a5,8(s1)
    80003f34:	00f05d63          	blez	a5,80003f4e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f38:	854a                	mv	a0,s2
    80003f3a:	00001097          	auipc	ra,0x1
    80003f3e:	c26080e7          	jalr	-986(ra) # 80004b60 <releasesleep>
}
    80003f42:	60e2                	ld	ra,24(sp)
    80003f44:	6442                	ld	s0,16(sp)
    80003f46:	64a2                	ld	s1,8(sp)
    80003f48:	6902                	ld	s2,0(sp)
    80003f4a:	6105                	addi	sp,sp,32
    80003f4c:	8082                	ret
    panic("iunlock");
    80003f4e:	00004517          	auipc	a0,0x4
    80003f52:	72a50513          	addi	a0,a0,1834 # 80008678 <syscalls+0x1c0>
    80003f56:	ffffc097          	auipc	ra,0xffffc
    80003f5a:	5e8080e7          	jalr	1512(ra) # 8000053e <panic>

0000000080003f5e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f5e:	7179                	addi	sp,sp,-48
    80003f60:	f406                	sd	ra,40(sp)
    80003f62:	f022                	sd	s0,32(sp)
    80003f64:	ec26                	sd	s1,24(sp)
    80003f66:	e84a                	sd	s2,16(sp)
    80003f68:	e44e                	sd	s3,8(sp)
    80003f6a:	e052                	sd	s4,0(sp)
    80003f6c:	1800                	addi	s0,sp,48
    80003f6e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f70:	05050493          	addi	s1,a0,80
    80003f74:	08050913          	addi	s2,a0,128
    80003f78:	a021                	j	80003f80 <itrunc+0x22>
    80003f7a:	0491                	addi	s1,s1,4
    80003f7c:	01248d63          	beq	s1,s2,80003f96 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f80:	408c                	lw	a1,0(s1)
    80003f82:	dde5                	beqz	a1,80003f7a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f84:	0009a503          	lw	a0,0(s3)
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	8f4080e7          	jalr	-1804(ra) # 8000387c <bfree>
      ip->addrs[i] = 0;
    80003f90:	0004a023          	sw	zero,0(s1)
    80003f94:	b7dd                	j	80003f7a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f96:	0809a583          	lw	a1,128(s3)
    80003f9a:	e185                	bnez	a1,80003fba <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f9c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003fa0:	854e                	mv	a0,s3
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	de4080e7          	jalr	-540(ra) # 80003d86 <iupdate>
}
    80003faa:	70a2                	ld	ra,40(sp)
    80003fac:	7402                	ld	s0,32(sp)
    80003fae:	64e2                	ld	s1,24(sp)
    80003fb0:	6942                	ld	s2,16(sp)
    80003fb2:	69a2                	ld	s3,8(sp)
    80003fb4:	6a02                	ld	s4,0(sp)
    80003fb6:	6145                	addi	sp,sp,48
    80003fb8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fba:	0009a503          	lw	a0,0(s3)
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	678080e7          	jalr	1656(ra) # 80003636 <bread>
    80003fc6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fc8:	05850493          	addi	s1,a0,88
    80003fcc:	45850913          	addi	s2,a0,1112
    80003fd0:	a021                	j	80003fd8 <itrunc+0x7a>
    80003fd2:	0491                	addi	s1,s1,4
    80003fd4:	01248b63          	beq	s1,s2,80003fea <itrunc+0x8c>
      if(a[j])
    80003fd8:	408c                	lw	a1,0(s1)
    80003fda:	dde5                	beqz	a1,80003fd2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003fdc:	0009a503          	lw	a0,0(s3)
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	89c080e7          	jalr	-1892(ra) # 8000387c <bfree>
    80003fe8:	b7ed                	j	80003fd2 <itrunc+0x74>
    brelse(bp);
    80003fea:	8552                	mv	a0,s4
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	77a080e7          	jalr	1914(ra) # 80003766 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ff4:	0809a583          	lw	a1,128(s3)
    80003ff8:	0009a503          	lw	a0,0(s3)
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	880080e7          	jalr	-1920(ra) # 8000387c <bfree>
    ip->addrs[NDIRECT] = 0;
    80004004:	0809a023          	sw	zero,128(s3)
    80004008:	bf51                	j	80003f9c <itrunc+0x3e>

000000008000400a <iput>:
{
    8000400a:	1101                	addi	sp,sp,-32
    8000400c:	ec06                	sd	ra,24(sp)
    8000400e:	e822                	sd	s0,16(sp)
    80004010:	e426                	sd	s1,8(sp)
    80004012:	e04a                	sd	s2,0(sp)
    80004014:	1000                	addi	s0,sp,32
    80004016:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004018:	00022517          	auipc	a0,0x22
    8000401c:	73850513          	addi	a0,a0,1848 # 80026750 <itable>
    80004020:	ffffd097          	auipc	ra,0xffffd
    80004024:	bb6080e7          	jalr	-1098(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004028:	4498                	lw	a4,8(s1)
    8000402a:	4785                	li	a5,1
    8000402c:	02f70363          	beq	a4,a5,80004052 <iput+0x48>
  ip->ref--;
    80004030:	449c                	lw	a5,8(s1)
    80004032:	37fd                	addiw	a5,a5,-1
    80004034:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004036:	00022517          	auipc	a0,0x22
    8000403a:	71a50513          	addi	a0,a0,1818 # 80026750 <itable>
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	c4c080e7          	jalr	-948(ra) # 80000c8a <release>
}
    80004046:	60e2                	ld	ra,24(sp)
    80004048:	6442                	ld	s0,16(sp)
    8000404a:	64a2                	ld	s1,8(sp)
    8000404c:	6902                	ld	s2,0(sp)
    8000404e:	6105                	addi	sp,sp,32
    80004050:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004052:	40bc                	lw	a5,64(s1)
    80004054:	dff1                	beqz	a5,80004030 <iput+0x26>
    80004056:	04a49783          	lh	a5,74(s1)
    8000405a:	fbf9                	bnez	a5,80004030 <iput+0x26>
    acquiresleep(&ip->lock);
    8000405c:	01048913          	addi	s2,s1,16
    80004060:	854a                	mv	a0,s2
    80004062:	00001097          	auipc	ra,0x1
    80004066:	aa8080e7          	jalr	-1368(ra) # 80004b0a <acquiresleep>
    release(&itable.lock);
    8000406a:	00022517          	auipc	a0,0x22
    8000406e:	6e650513          	addi	a0,a0,1766 # 80026750 <itable>
    80004072:	ffffd097          	auipc	ra,0xffffd
    80004076:	c18080e7          	jalr	-1000(ra) # 80000c8a <release>
    itrunc(ip);
    8000407a:	8526                	mv	a0,s1
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	ee2080e7          	jalr	-286(ra) # 80003f5e <itrunc>
    ip->type = 0;
    80004084:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004088:	8526                	mv	a0,s1
    8000408a:	00000097          	auipc	ra,0x0
    8000408e:	cfc080e7          	jalr	-772(ra) # 80003d86 <iupdate>
    ip->valid = 0;
    80004092:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004096:	854a                	mv	a0,s2
    80004098:	00001097          	auipc	ra,0x1
    8000409c:	ac8080e7          	jalr	-1336(ra) # 80004b60 <releasesleep>
    acquire(&itable.lock);
    800040a0:	00022517          	auipc	a0,0x22
    800040a4:	6b050513          	addi	a0,a0,1712 # 80026750 <itable>
    800040a8:	ffffd097          	auipc	ra,0xffffd
    800040ac:	b2e080e7          	jalr	-1234(ra) # 80000bd6 <acquire>
    800040b0:	b741                	j	80004030 <iput+0x26>

00000000800040b2 <iunlockput>:
{
    800040b2:	1101                	addi	sp,sp,-32
    800040b4:	ec06                	sd	ra,24(sp)
    800040b6:	e822                	sd	s0,16(sp)
    800040b8:	e426                	sd	s1,8(sp)
    800040ba:	1000                	addi	s0,sp,32
    800040bc:	84aa                	mv	s1,a0
  iunlock(ip);
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	e54080e7          	jalr	-428(ra) # 80003f12 <iunlock>
  iput(ip);
    800040c6:	8526                	mv	a0,s1
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	f42080e7          	jalr	-190(ra) # 8000400a <iput>
}
    800040d0:	60e2                	ld	ra,24(sp)
    800040d2:	6442                	ld	s0,16(sp)
    800040d4:	64a2                	ld	s1,8(sp)
    800040d6:	6105                	addi	sp,sp,32
    800040d8:	8082                	ret

00000000800040da <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040da:	1141                	addi	sp,sp,-16
    800040dc:	e422                	sd	s0,8(sp)
    800040de:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040e0:	411c                	lw	a5,0(a0)
    800040e2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040e4:	415c                	lw	a5,4(a0)
    800040e6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040e8:	04451783          	lh	a5,68(a0)
    800040ec:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040f0:	04a51783          	lh	a5,74(a0)
    800040f4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040f8:	04c56783          	lwu	a5,76(a0)
    800040fc:	e99c                	sd	a5,16(a1)
}
    800040fe:	6422                	ld	s0,8(sp)
    80004100:	0141                	addi	sp,sp,16
    80004102:	8082                	ret

0000000080004104 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004104:	457c                	lw	a5,76(a0)
    80004106:	0ed7e963          	bltu	a5,a3,800041f8 <readi+0xf4>
{
    8000410a:	7159                	addi	sp,sp,-112
    8000410c:	f486                	sd	ra,104(sp)
    8000410e:	f0a2                	sd	s0,96(sp)
    80004110:	eca6                	sd	s1,88(sp)
    80004112:	e8ca                	sd	s2,80(sp)
    80004114:	e4ce                	sd	s3,72(sp)
    80004116:	e0d2                	sd	s4,64(sp)
    80004118:	fc56                	sd	s5,56(sp)
    8000411a:	f85a                	sd	s6,48(sp)
    8000411c:	f45e                	sd	s7,40(sp)
    8000411e:	f062                	sd	s8,32(sp)
    80004120:	ec66                	sd	s9,24(sp)
    80004122:	e86a                	sd	s10,16(sp)
    80004124:	e46e                	sd	s11,8(sp)
    80004126:	1880                	addi	s0,sp,112
    80004128:	8b2a                	mv	s6,a0
    8000412a:	8bae                	mv	s7,a1
    8000412c:	8a32                	mv	s4,a2
    8000412e:	84b6                	mv	s1,a3
    80004130:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004132:	9f35                	addw	a4,a4,a3
    return 0;
    80004134:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004136:	0ad76063          	bltu	a4,a3,800041d6 <readi+0xd2>
  if(off + n > ip->size)
    8000413a:	00e7f463          	bgeu	a5,a4,80004142 <readi+0x3e>
    n = ip->size - off;
    8000413e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004142:	0a0a8963          	beqz	s5,800041f4 <readi+0xf0>
    80004146:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004148:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000414c:	5c7d                	li	s8,-1
    8000414e:	a82d                	j	80004188 <readi+0x84>
    80004150:	020d1d93          	slli	s11,s10,0x20
    80004154:	020ddd93          	srli	s11,s11,0x20
    80004158:	05890793          	addi	a5,s2,88
    8000415c:	86ee                	mv	a3,s11
    8000415e:	963e                	add	a2,a2,a5
    80004160:	85d2                	mv	a1,s4
    80004162:	855e                	mv	a0,s7
    80004164:	ffffe097          	auipc	ra,0xffffe
    80004168:	756080e7          	jalr	1878(ra) # 800028ba <either_copyout>
    8000416c:	05850d63          	beq	a0,s8,800041c6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004170:	854a                	mv	a0,s2
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	5f4080e7          	jalr	1524(ra) # 80003766 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000417a:	013d09bb          	addw	s3,s10,s3
    8000417e:	009d04bb          	addw	s1,s10,s1
    80004182:	9a6e                	add	s4,s4,s11
    80004184:	0559f763          	bgeu	s3,s5,800041d2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004188:	00a4d59b          	srliw	a1,s1,0xa
    8000418c:	855a                	mv	a0,s6
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	8a2080e7          	jalr	-1886(ra) # 80003a30 <bmap>
    80004196:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000419a:	cd85                	beqz	a1,800041d2 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000419c:	000b2503          	lw	a0,0(s6)
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	496080e7          	jalr	1174(ra) # 80003636 <bread>
    800041a8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041aa:	3ff4f613          	andi	a2,s1,1023
    800041ae:	40cc87bb          	subw	a5,s9,a2
    800041b2:	413a873b          	subw	a4,s5,s3
    800041b6:	8d3e                	mv	s10,a5
    800041b8:	2781                	sext.w	a5,a5
    800041ba:	0007069b          	sext.w	a3,a4
    800041be:	f8f6f9e3          	bgeu	a3,a5,80004150 <readi+0x4c>
    800041c2:	8d3a                	mv	s10,a4
    800041c4:	b771                	j	80004150 <readi+0x4c>
      brelse(bp);
    800041c6:	854a                	mv	a0,s2
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	59e080e7          	jalr	1438(ra) # 80003766 <brelse>
      tot = -1;
    800041d0:	59fd                	li	s3,-1
  }
  return tot;
    800041d2:	0009851b          	sext.w	a0,s3
}
    800041d6:	70a6                	ld	ra,104(sp)
    800041d8:	7406                	ld	s0,96(sp)
    800041da:	64e6                	ld	s1,88(sp)
    800041dc:	6946                	ld	s2,80(sp)
    800041de:	69a6                	ld	s3,72(sp)
    800041e0:	6a06                	ld	s4,64(sp)
    800041e2:	7ae2                	ld	s5,56(sp)
    800041e4:	7b42                	ld	s6,48(sp)
    800041e6:	7ba2                	ld	s7,40(sp)
    800041e8:	7c02                	ld	s8,32(sp)
    800041ea:	6ce2                	ld	s9,24(sp)
    800041ec:	6d42                	ld	s10,16(sp)
    800041ee:	6da2                	ld	s11,8(sp)
    800041f0:	6165                	addi	sp,sp,112
    800041f2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041f4:	89d6                	mv	s3,s5
    800041f6:	bff1                	j	800041d2 <readi+0xce>
    return 0;
    800041f8:	4501                	li	a0,0
}
    800041fa:	8082                	ret

00000000800041fc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041fc:	457c                	lw	a5,76(a0)
    800041fe:	10d7e863          	bltu	a5,a3,8000430e <writei+0x112>
{
    80004202:	7159                	addi	sp,sp,-112
    80004204:	f486                	sd	ra,104(sp)
    80004206:	f0a2                	sd	s0,96(sp)
    80004208:	eca6                	sd	s1,88(sp)
    8000420a:	e8ca                	sd	s2,80(sp)
    8000420c:	e4ce                	sd	s3,72(sp)
    8000420e:	e0d2                	sd	s4,64(sp)
    80004210:	fc56                	sd	s5,56(sp)
    80004212:	f85a                	sd	s6,48(sp)
    80004214:	f45e                	sd	s7,40(sp)
    80004216:	f062                	sd	s8,32(sp)
    80004218:	ec66                	sd	s9,24(sp)
    8000421a:	e86a                	sd	s10,16(sp)
    8000421c:	e46e                	sd	s11,8(sp)
    8000421e:	1880                	addi	s0,sp,112
    80004220:	8aaa                	mv	s5,a0
    80004222:	8bae                	mv	s7,a1
    80004224:	8a32                	mv	s4,a2
    80004226:	8936                	mv	s2,a3
    80004228:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000422a:	00e687bb          	addw	a5,a3,a4
    8000422e:	0ed7e263          	bltu	a5,a3,80004312 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004232:	00043737          	lui	a4,0x43
    80004236:	0ef76063          	bltu	a4,a5,80004316 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000423a:	0c0b0863          	beqz	s6,8000430a <writei+0x10e>
    8000423e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004240:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004244:	5c7d                	li	s8,-1
    80004246:	a091                	j	8000428a <writei+0x8e>
    80004248:	020d1d93          	slli	s11,s10,0x20
    8000424c:	020ddd93          	srli	s11,s11,0x20
    80004250:	05848793          	addi	a5,s1,88
    80004254:	86ee                	mv	a3,s11
    80004256:	8652                	mv	a2,s4
    80004258:	85de                	mv	a1,s7
    8000425a:	953e                	add	a0,a0,a5
    8000425c:	ffffe097          	auipc	ra,0xffffe
    80004260:	6b4080e7          	jalr	1716(ra) # 80002910 <either_copyin>
    80004264:	07850263          	beq	a0,s8,800042c8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004268:	8526                	mv	a0,s1
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	780080e7          	jalr	1920(ra) # 800049ea <log_write>
    brelse(bp);
    80004272:	8526                	mv	a0,s1
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	4f2080e7          	jalr	1266(ra) # 80003766 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000427c:	013d09bb          	addw	s3,s10,s3
    80004280:	012d093b          	addw	s2,s10,s2
    80004284:	9a6e                	add	s4,s4,s11
    80004286:	0569f663          	bgeu	s3,s6,800042d2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000428a:	00a9559b          	srliw	a1,s2,0xa
    8000428e:	8556                	mv	a0,s5
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	7a0080e7          	jalr	1952(ra) # 80003a30 <bmap>
    80004298:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000429c:	c99d                	beqz	a1,800042d2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000429e:	000aa503          	lw	a0,0(s5)
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	394080e7          	jalr	916(ra) # 80003636 <bread>
    800042aa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042ac:	3ff97513          	andi	a0,s2,1023
    800042b0:	40ac87bb          	subw	a5,s9,a0
    800042b4:	413b073b          	subw	a4,s6,s3
    800042b8:	8d3e                	mv	s10,a5
    800042ba:	2781                	sext.w	a5,a5
    800042bc:	0007069b          	sext.w	a3,a4
    800042c0:	f8f6f4e3          	bgeu	a3,a5,80004248 <writei+0x4c>
    800042c4:	8d3a                	mv	s10,a4
    800042c6:	b749                	j	80004248 <writei+0x4c>
      brelse(bp);
    800042c8:	8526                	mv	a0,s1
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	49c080e7          	jalr	1180(ra) # 80003766 <brelse>
  }

  if(off > ip->size)
    800042d2:	04caa783          	lw	a5,76(s5)
    800042d6:	0127f463          	bgeu	a5,s2,800042de <writei+0xe2>
    ip->size = off;
    800042da:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042de:	8556                	mv	a0,s5
    800042e0:	00000097          	auipc	ra,0x0
    800042e4:	aa6080e7          	jalr	-1370(ra) # 80003d86 <iupdate>

  return tot;
    800042e8:	0009851b          	sext.w	a0,s3
}
    800042ec:	70a6                	ld	ra,104(sp)
    800042ee:	7406                	ld	s0,96(sp)
    800042f0:	64e6                	ld	s1,88(sp)
    800042f2:	6946                	ld	s2,80(sp)
    800042f4:	69a6                	ld	s3,72(sp)
    800042f6:	6a06                	ld	s4,64(sp)
    800042f8:	7ae2                	ld	s5,56(sp)
    800042fa:	7b42                	ld	s6,48(sp)
    800042fc:	7ba2                	ld	s7,40(sp)
    800042fe:	7c02                	ld	s8,32(sp)
    80004300:	6ce2                	ld	s9,24(sp)
    80004302:	6d42                	ld	s10,16(sp)
    80004304:	6da2                	ld	s11,8(sp)
    80004306:	6165                	addi	sp,sp,112
    80004308:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000430a:	89da                	mv	s3,s6
    8000430c:	bfc9                	j	800042de <writei+0xe2>
    return -1;
    8000430e:	557d                	li	a0,-1
}
    80004310:	8082                	ret
    return -1;
    80004312:	557d                	li	a0,-1
    80004314:	bfe1                	j	800042ec <writei+0xf0>
    return -1;
    80004316:	557d                	li	a0,-1
    80004318:	bfd1                	j	800042ec <writei+0xf0>

000000008000431a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000431a:	1141                	addi	sp,sp,-16
    8000431c:	e406                	sd	ra,8(sp)
    8000431e:	e022                	sd	s0,0(sp)
    80004320:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004322:	4639                	li	a2,14
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	a7e080e7          	jalr	-1410(ra) # 80000da2 <strncmp>
}
    8000432c:	60a2                	ld	ra,8(sp)
    8000432e:	6402                	ld	s0,0(sp)
    80004330:	0141                	addi	sp,sp,16
    80004332:	8082                	ret

0000000080004334 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004334:	7139                	addi	sp,sp,-64
    80004336:	fc06                	sd	ra,56(sp)
    80004338:	f822                	sd	s0,48(sp)
    8000433a:	f426                	sd	s1,40(sp)
    8000433c:	f04a                	sd	s2,32(sp)
    8000433e:	ec4e                	sd	s3,24(sp)
    80004340:	e852                	sd	s4,16(sp)
    80004342:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004344:	04451703          	lh	a4,68(a0)
    80004348:	4785                	li	a5,1
    8000434a:	00f71a63          	bne	a4,a5,8000435e <dirlookup+0x2a>
    8000434e:	892a                	mv	s2,a0
    80004350:	89ae                	mv	s3,a1
    80004352:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004354:	457c                	lw	a5,76(a0)
    80004356:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004358:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000435a:	e79d                	bnez	a5,80004388 <dirlookup+0x54>
    8000435c:	a8a5                	j	800043d4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000435e:	00004517          	auipc	a0,0x4
    80004362:	32250513          	addi	a0,a0,802 # 80008680 <syscalls+0x1c8>
    80004366:	ffffc097          	auipc	ra,0xffffc
    8000436a:	1d8080e7          	jalr	472(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000436e:	00004517          	auipc	a0,0x4
    80004372:	32a50513          	addi	a0,a0,810 # 80008698 <syscalls+0x1e0>
    80004376:	ffffc097          	auipc	ra,0xffffc
    8000437a:	1c8080e7          	jalr	456(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000437e:	24c1                	addiw	s1,s1,16
    80004380:	04c92783          	lw	a5,76(s2)
    80004384:	04f4f763          	bgeu	s1,a5,800043d2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004388:	4741                	li	a4,16
    8000438a:	86a6                	mv	a3,s1
    8000438c:	fc040613          	addi	a2,s0,-64
    80004390:	4581                	li	a1,0
    80004392:	854a                	mv	a0,s2
    80004394:	00000097          	auipc	ra,0x0
    80004398:	d70080e7          	jalr	-656(ra) # 80004104 <readi>
    8000439c:	47c1                	li	a5,16
    8000439e:	fcf518e3          	bne	a0,a5,8000436e <dirlookup+0x3a>
    if(de.inum == 0)
    800043a2:	fc045783          	lhu	a5,-64(s0)
    800043a6:	dfe1                	beqz	a5,8000437e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800043a8:	fc240593          	addi	a1,s0,-62
    800043ac:	854e                	mv	a0,s3
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	f6c080e7          	jalr	-148(ra) # 8000431a <namecmp>
    800043b6:	f561                	bnez	a0,8000437e <dirlookup+0x4a>
      if(poff)
    800043b8:	000a0463          	beqz	s4,800043c0 <dirlookup+0x8c>
        *poff = off;
    800043bc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043c0:	fc045583          	lhu	a1,-64(s0)
    800043c4:	00092503          	lw	a0,0(s2)
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	750080e7          	jalr	1872(ra) # 80003b18 <iget>
    800043d0:	a011                	j	800043d4 <dirlookup+0xa0>
  return 0;
    800043d2:	4501                	li	a0,0
}
    800043d4:	70e2                	ld	ra,56(sp)
    800043d6:	7442                	ld	s0,48(sp)
    800043d8:	74a2                	ld	s1,40(sp)
    800043da:	7902                	ld	s2,32(sp)
    800043dc:	69e2                	ld	s3,24(sp)
    800043de:	6a42                	ld	s4,16(sp)
    800043e0:	6121                	addi	sp,sp,64
    800043e2:	8082                	ret

00000000800043e4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043e4:	711d                	addi	sp,sp,-96
    800043e6:	ec86                	sd	ra,88(sp)
    800043e8:	e8a2                	sd	s0,80(sp)
    800043ea:	e4a6                	sd	s1,72(sp)
    800043ec:	e0ca                	sd	s2,64(sp)
    800043ee:	fc4e                	sd	s3,56(sp)
    800043f0:	f852                	sd	s4,48(sp)
    800043f2:	f456                	sd	s5,40(sp)
    800043f4:	f05a                	sd	s6,32(sp)
    800043f6:	ec5e                	sd	s7,24(sp)
    800043f8:	e862                	sd	s8,16(sp)
    800043fa:	e466                	sd	s9,8(sp)
    800043fc:	1080                	addi	s0,sp,96
    800043fe:	84aa                	mv	s1,a0
    80004400:	8aae                	mv	s5,a1
    80004402:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004404:	00054703          	lbu	a4,0(a0)
    80004408:	02f00793          	li	a5,47
    8000440c:	02f70363          	beq	a4,a5,80004432 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	7e6080e7          	jalr	2022(ra) # 80001bf6 <myproc>
    80004418:	15053503          	ld	a0,336(a0)
    8000441c:	00000097          	auipc	ra,0x0
    80004420:	9f6080e7          	jalr	-1546(ra) # 80003e12 <idup>
    80004424:	89aa                	mv	s3,a0
  while(*path == '/')
    80004426:	02f00913          	li	s2,47
  len = path - s;
    8000442a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000442c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000442e:	4b85                	li	s7,1
    80004430:	a865                	j	800044e8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004432:	4585                	li	a1,1
    80004434:	4505                	li	a0,1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	6e2080e7          	jalr	1762(ra) # 80003b18 <iget>
    8000443e:	89aa                	mv	s3,a0
    80004440:	b7dd                	j	80004426 <namex+0x42>
      iunlockput(ip);
    80004442:	854e                	mv	a0,s3
    80004444:	00000097          	auipc	ra,0x0
    80004448:	c6e080e7          	jalr	-914(ra) # 800040b2 <iunlockput>
      return 0;
    8000444c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000444e:	854e                	mv	a0,s3
    80004450:	60e6                	ld	ra,88(sp)
    80004452:	6446                	ld	s0,80(sp)
    80004454:	64a6                	ld	s1,72(sp)
    80004456:	6906                	ld	s2,64(sp)
    80004458:	79e2                	ld	s3,56(sp)
    8000445a:	7a42                	ld	s4,48(sp)
    8000445c:	7aa2                	ld	s5,40(sp)
    8000445e:	7b02                	ld	s6,32(sp)
    80004460:	6be2                	ld	s7,24(sp)
    80004462:	6c42                	ld	s8,16(sp)
    80004464:	6ca2                	ld	s9,8(sp)
    80004466:	6125                	addi	sp,sp,96
    80004468:	8082                	ret
      iunlock(ip);
    8000446a:	854e                	mv	a0,s3
    8000446c:	00000097          	auipc	ra,0x0
    80004470:	aa6080e7          	jalr	-1370(ra) # 80003f12 <iunlock>
      return ip;
    80004474:	bfe9                	j	8000444e <namex+0x6a>
      iunlockput(ip);
    80004476:	854e                	mv	a0,s3
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	c3a080e7          	jalr	-966(ra) # 800040b2 <iunlockput>
      return 0;
    80004480:	89e6                	mv	s3,s9
    80004482:	b7f1                	j	8000444e <namex+0x6a>
  len = path - s;
    80004484:	40b48633          	sub	a2,s1,a1
    80004488:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000448c:	099c5463          	bge	s8,s9,80004514 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004490:	4639                	li	a2,14
    80004492:	8552                	mv	a0,s4
    80004494:	ffffd097          	auipc	ra,0xffffd
    80004498:	89a080e7          	jalr	-1894(ra) # 80000d2e <memmove>
  while(*path == '/')
    8000449c:	0004c783          	lbu	a5,0(s1)
    800044a0:	01279763          	bne	a5,s2,800044ae <namex+0xca>
    path++;
    800044a4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044a6:	0004c783          	lbu	a5,0(s1)
    800044aa:	ff278de3          	beq	a5,s2,800044a4 <namex+0xc0>
    ilock(ip);
    800044ae:	854e                	mv	a0,s3
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	9a0080e7          	jalr	-1632(ra) # 80003e50 <ilock>
    if(ip->type != T_DIR){
    800044b8:	04499783          	lh	a5,68(s3)
    800044bc:	f97793e3          	bne	a5,s7,80004442 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044c0:	000a8563          	beqz	s5,800044ca <namex+0xe6>
    800044c4:	0004c783          	lbu	a5,0(s1)
    800044c8:	d3cd                	beqz	a5,8000446a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044ca:	865a                	mv	a2,s6
    800044cc:	85d2                	mv	a1,s4
    800044ce:	854e                	mv	a0,s3
    800044d0:	00000097          	auipc	ra,0x0
    800044d4:	e64080e7          	jalr	-412(ra) # 80004334 <dirlookup>
    800044d8:	8caa                	mv	s9,a0
    800044da:	dd51                	beqz	a0,80004476 <namex+0x92>
    iunlockput(ip);
    800044dc:	854e                	mv	a0,s3
    800044de:	00000097          	auipc	ra,0x0
    800044e2:	bd4080e7          	jalr	-1068(ra) # 800040b2 <iunlockput>
    ip = next;
    800044e6:	89e6                	mv	s3,s9
  while(*path == '/')
    800044e8:	0004c783          	lbu	a5,0(s1)
    800044ec:	05279763          	bne	a5,s2,8000453a <namex+0x156>
    path++;
    800044f0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044f2:	0004c783          	lbu	a5,0(s1)
    800044f6:	ff278de3          	beq	a5,s2,800044f0 <namex+0x10c>
  if(*path == 0)
    800044fa:	c79d                	beqz	a5,80004528 <namex+0x144>
    path++;
    800044fc:	85a6                	mv	a1,s1
  len = path - s;
    800044fe:	8cda                	mv	s9,s6
    80004500:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004502:	01278963          	beq	a5,s2,80004514 <namex+0x130>
    80004506:	dfbd                	beqz	a5,80004484 <namex+0xa0>
    path++;
    80004508:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000450a:	0004c783          	lbu	a5,0(s1)
    8000450e:	ff279ce3          	bne	a5,s2,80004506 <namex+0x122>
    80004512:	bf8d                	j	80004484 <namex+0xa0>
    memmove(name, s, len);
    80004514:	2601                	sext.w	a2,a2
    80004516:	8552                	mv	a0,s4
    80004518:	ffffd097          	auipc	ra,0xffffd
    8000451c:	816080e7          	jalr	-2026(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004520:	9cd2                	add	s9,s9,s4
    80004522:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004526:	bf9d                	j	8000449c <namex+0xb8>
  if(nameiparent){
    80004528:	f20a83e3          	beqz	s5,8000444e <namex+0x6a>
    iput(ip);
    8000452c:	854e                	mv	a0,s3
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	adc080e7          	jalr	-1316(ra) # 8000400a <iput>
    return 0;
    80004536:	4981                	li	s3,0
    80004538:	bf19                	j	8000444e <namex+0x6a>
  if(*path == 0)
    8000453a:	d7fd                	beqz	a5,80004528 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000453c:	0004c783          	lbu	a5,0(s1)
    80004540:	85a6                	mv	a1,s1
    80004542:	b7d1                	j	80004506 <namex+0x122>

0000000080004544 <dirlink>:
{
    80004544:	7139                	addi	sp,sp,-64
    80004546:	fc06                	sd	ra,56(sp)
    80004548:	f822                	sd	s0,48(sp)
    8000454a:	f426                	sd	s1,40(sp)
    8000454c:	f04a                	sd	s2,32(sp)
    8000454e:	ec4e                	sd	s3,24(sp)
    80004550:	e852                	sd	s4,16(sp)
    80004552:	0080                	addi	s0,sp,64
    80004554:	892a                	mv	s2,a0
    80004556:	8a2e                	mv	s4,a1
    80004558:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000455a:	4601                	li	a2,0
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	dd8080e7          	jalr	-552(ra) # 80004334 <dirlookup>
    80004564:	e93d                	bnez	a0,800045da <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004566:	04c92483          	lw	s1,76(s2)
    8000456a:	c49d                	beqz	s1,80004598 <dirlink+0x54>
    8000456c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000456e:	4741                	li	a4,16
    80004570:	86a6                	mv	a3,s1
    80004572:	fc040613          	addi	a2,s0,-64
    80004576:	4581                	li	a1,0
    80004578:	854a                	mv	a0,s2
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	b8a080e7          	jalr	-1142(ra) # 80004104 <readi>
    80004582:	47c1                	li	a5,16
    80004584:	06f51163          	bne	a0,a5,800045e6 <dirlink+0xa2>
    if(de.inum == 0)
    80004588:	fc045783          	lhu	a5,-64(s0)
    8000458c:	c791                	beqz	a5,80004598 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000458e:	24c1                	addiw	s1,s1,16
    80004590:	04c92783          	lw	a5,76(s2)
    80004594:	fcf4ede3          	bltu	s1,a5,8000456e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004598:	4639                	li	a2,14
    8000459a:	85d2                	mv	a1,s4
    8000459c:	fc240513          	addi	a0,s0,-62
    800045a0:	ffffd097          	auipc	ra,0xffffd
    800045a4:	83e080e7          	jalr	-1986(ra) # 80000dde <strncpy>
  de.inum = inum;
    800045a8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045ac:	4741                	li	a4,16
    800045ae:	86a6                	mv	a3,s1
    800045b0:	fc040613          	addi	a2,s0,-64
    800045b4:	4581                	li	a1,0
    800045b6:	854a                	mv	a0,s2
    800045b8:	00000097          	auipc	ra,0x0
    800045bc:	c44080e7          	jalr	-956(ra) # 800041fc <writei>
    800045c0:	1541                	addi	a0,a0,-16
    800045c2:	00a03533          	snez	a0,a0
    800045c6:	40a00533          	neg	a0,a0
}
    800045ca:	70e2                	ld	ra,56(sp)
    800045cc:	7442                	ld	s0,48(sp)
    800045ce:	74a2                	ld	s1,40(sp)
    800045d0:	7902                	ld	s2,32(sp)
    800045d2:	69e2                	ld	s3,24(sp)
    800045d4:	6a42                	ld	s4,16(sp)
    800045d6:	6121                	addi	sp,sp,64
    800045d8:	8082                	ret
    iput(ip);
    800045da:	00000097          	auipc	ra,0x0
    800045de:	a30080e7          	jalr	-1488(ra) # 8000400a <iput>
    return -1;
    800045e2:	557d                	li	a0,-1
    800045e4:	b7dd                	j	800045ca <dirlink+0x86>
      panic("dirlink read");
    800045e6:	00004517          	auipc	a0,0x4
    800045ea:	0c250513          	addi	a0,a0,194 # 800086a8 <syscalls+0x1f0>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>

00000000800045f6 <namei>:

struct inode*
namei(char *path)
{
    800045f6:	1101                	addi	sp,sp,-32
    800045f8:	ec06                	sd	ra,24(sp)
    800045fa:	e822                	sd	s0,16(sp)
    800045fc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045fe:	fe040613          	addi	a2,s0,-32
    80004602:	4581                	li	a1,0
    80004604:	00000097          	auipc	ra,0x0
    80004608:	de0080e7          	jalr	-544(ra) # 800043e4 <namex>
}
    8000460c:	60e2                	ld	ra,24(sp)
    8000460e:	6442                	ld	s0,16(sp)
    80004610:	6105                	addi	sp,sp,32
    80004612:	8082                	ret

0000000080004614 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004614:	1141                	addi	sp,sp,-16
    80004616:	e406                	sd	ra,8(sp)
    80004618:	e022                	sd	s0,0(sp)
    8000461a:	0800                	addi	s0,sp,16
    8000461c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000461e:	4585                	li	a1,1
    80004620:	00000097          	auipc	ra,0x0
    80004624:	dc4080e7          	jalr	-572(ra) # 800043e4 <namex>
}
    80004628:	60a2                	ld	ra,8(sp)
    8000462a:	6402                	ld	s0,0(sp)
    8000462c:	0141                	addi	sp,sp,16
    8000462e:	8082                	ret

0000000080004630 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004630:	1101                	addi	sp,sp,-32
    80004632:	ec06                	sd	ra,24(sp)
    80004634:	e822                	sd	s0,16(sp)
    80004636:	e426                	sd	s1,8(sp)
    80004638:	e04a                	sd	s2,0(sp)
    8000463a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000463c:	00024917          	auipc	s2,0x24
    80004640:	bbc90913          	addi	s2,s2,-1092 # 800281f8 <log>
    80004644:	01892583          	lw	a1,24(s2)
    80004648:	02892503          	lw	a0,40(s2)
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	fea080e7          	jalr	-22(ra) # 80003636 <bread>
    80004654:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004656:	02c92683          	lw	a3,44(s2)
    8000465a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000465c:	02d05763          	blez	a3,8000468a <write_head+0x5a>
    80004660:	00024797          	auipc	a5,0x24
    80004664:	bc878793          	addi	a5,a5,-1080 # 80028228 <log+0x30>
    80004668:	05c50713          	addi	a4,a0,92
    8000466c:	36fd                	addiw	a3,a3,-1
    8000466e:	1682                	slli	a3,a3,0x20
    80004670:	9281                	srli	a3,a3,0x20
    80004672:	068a                	slli	a3,a3,0x2
    80004674:	00024617          	auipc	a2,0x24
    80004678:	bb860613          	addi	a2,a2,-1096 # 8002822c <log+0x34>
    8000467c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000467e:	4390                	lw	a2,0(a5)
    80004680:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004682:	0791                	addi	a5,a5,4
    80004684:	0711                	addi	a4,a4,4
    80004686:	fed79ce3          	bne	a5,a3,8000467e <write_head+0x4e>
  }
  bwrite(buf);
    8000468a:	8526                	mv	a0,s1
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	09c080e7          	jalr	156(ra) # 80003728 <bwrite>
  brelse(buf);
    80004694:	8526                	mv	a0,s1
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	0d0080e7          	jalr	208(ra) # 80003766 <brelse>
}
    8000469e:	60e2                	ld	ra,24(sp)
    800046a0:	6442                	ld	s0,16(sp)
    800046a2:	64a2                	ld	s1,8(sp)
    800046a4:	6902                	ld	s2,0(sp)
    800046a6:	6105                	addi	sp,sp,32
    800046a8:	8082                	ret

00000000800046aa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046aa:	00024797          	auipc	a5,0x24
    800046ae:	b7a7a783          	lw	a5,-1158(a5) # 80028224 <log+0x2c>
    800046b2:	0af05d63          	blez	a5,8000476c <install_trans+0xc2>
{
    800046b6:	7139                	addi	sp,sp,-64
    800046b8:	fc06                	sd	ra,56(sp)
    800046ba:	f822                	sd	s0,48(sp)
    800046bc:	f426                	sd	s1,40(sp)
    800046be:	f04a                	sd	s2,32(sp)
    800046c0:	ec4e                	sd	s3,24(sp)
    800046c2:	e852                	sd	s4,16(sp)
    800046c4:	e456                	sd	s5,8(sp)
    800046c6:	e05a                	sd	s6,0(sp)
    800046c8:	0080                	addi	s0,sp,64
    800046ca:	8b2a                	mv	s6,a0
    800046cc:	00024a97          	auipc	s5,0x24
    800046d0:	b5ca8a93          	addi	s5,s5,-1188 # 80028228 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046d4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046d6:	00024997          	auipc	s3,0x24
    800046da:	b2298993          	addi	s3,s3,-1246 # 800281f8 <log>
    800046de:	a00d                	j	80004700 <install_trans+0x56>
    brelse(lbuf);
    800046e0:	854a                	mv	a0,s2
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	084080e7          	jalr	132(ra) # 80003766 <brelse>
    brelse(dbuf);
    800046ea:	8526                	mv	a0,s1
    800046ec:	fffff097          	auipc	ra,0xfffff
    800046f0:	07a080e7          	jalr	122(ra) # 80003766 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f4:	2a05                	addiw	s4,s4,1
    800046f6:	0a91                	addi	s5,s5,4
    800046f8:	02c9a783          	lw	a5,44(s3)
    800046fc:	04fa5e63          	bge	s4,a5,80004758 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004700:	0189a583          	lw	a1,24(s3)
    80004704:	014585bb          	addw	a1,a1,s4
    80004708:	2585                	addiw	a1,a1,1
    8000470a:	0289a503          	lw	a0,40(s3)
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	f28080e7          	jalr	-216(ra) # 80003636 <bread>
    80004716:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004718:	000aa583          	lw	a1,0(s5)
    8000471c:	0289a503          	lw	a0,40(s3)
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	f16080e7          	jalr	-234(ra) # 80003636 <bread>
    80004728:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000472a:	40000613          	li	a2,1024
    8000472e:	05890593          	addi	a1,s2,88
    80004732:	05850513          	addi	a0,a0,88
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	5f8080e7          	jalr	1528(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000473e:	8526                	mv	a0,s1
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	fe8080e7          	jalr	-24(ra) # 80003728 <bwrite>
    if(recovering == 0)
    80004748:	f80b1ce3          	bnez	s6,800046e0 <install_trans+0x36>
      bunpin(dbuf);
    8000474c:	8526                	mv	a0,s1
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	0f2080e7          	jalr	242(ra) # 80003840 <bunpin>
    80004756:	b769                	j	800046e0 <install_trans+0x36>
}
    80004758:	70e2                	ld	ra,56(sp)
    8000475a:	7442                	ld	s0,48(sp)
    8000475c:	74a2                	ld	s1,40(sp)
    8000475e:	7902                	ld	s2,32(sp)
    80004760:	69e2                	ld	s3,24(sp)
    80004762:	6a42                	ld	s4,16(sp)
    80004764:	6aa2                	ld	s5,8(sp)
    80004766:	6b02                	ld	s6,0(sp)
    80004768:	6121                	addi	sp,sp,64
    8000476a:	8082                	ret
    8000476c:	8082                	ret

000000008000476e <initlog>:
{
    8000476e:	7179                	addi	sp,sp,-48
    80004770:	f406                	sd	ra,40(sp)
    80004772:	f022                	sd	s0,32(sp)
    80004774:	ec26                	sd	s1,24(sp)
    80004776:	e84a                	sd	s2,16(sp)
    80004778:	e44e                	sd	s3,8(sp)
    8000477a:	1800                	addi	s0,sp,48
    8000477c:	892a                	mv	s2,a0
    8000477e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004780:	00024497          	auipc	s1,0x24
    80004784:	a7848493          	addi	s1,s1,-1416 # 800281f8 <log>
    80004788:	00004597          	auipc	a1,0x4
    8000478c:	f3058593          	addi	a1,a1,-208 # 800086b8 <syscalls+0x200>
    80004790:	8526                	mv	a0,s1
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	3b4080e7          	jalr	948(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000479a:	0149a583          	lw	a1,20(s3)
    8000479e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800047a0:	0109a783          	lw	a5,16(s3)
    800047a4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800047a6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047aa:	854a                	mv	a0,s2
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	e8a080e7          	jalr	-374(ra) # 80003636 <bread>
  log.lh.n = lh->n;
    800047b4:	4d34                	lw	a3,88(a0)
    800047b6:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047b8:	02d05563          	blez	a3,800047e2 <initlog+0x74>
    800047bc:	05c50793          	addi	a5,a0,92
    800047c0:	00024717          	auipc	a4,0x24
    800047c4:	a6870713          	addi	a4,a4,-1432 # 80028228 <log+0x30>
    800047c8:	36fd                	addiw	a3,a3,-1
    800047ca:	1682                	slli	a3,a3,0x20
    800047cc:	9281                	srli	a3,a3,0x20
    800047ce:	068a                	slli	a3,a3,0x2
    800047d0:	06050613          	addi	a2,a0,96
    800047d4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800047d6:	4390                	lw	a2,0(a5)
    800047d8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047da:	0791                	addi	a5,a5,4
    800047dc:	0711                	addi	a4,a4,4
    800047de:	fed79ce3          	bne	a5,a3,800047d6 <initlog+0x68>
  brelse(buf);
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	f84080e7          	jalr	-124(ra) # 80003766 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047ea:	4505                	li	a0,1
    800047ec:	00000097          	auipc	ra,0x0
    800047f0:	ebe080e7          	jalr	-322(ra) # 800046aa <install_trans>
  log.lh.n = 0;
    800047f4:	00024797          	auipc	a5,0x24
    800047f8:	a207a823          	sw	zero,-1488(a5) # 80028224 <log+0x2c>
  write_head(); // clear the log
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	e34080e7          	jalr	-460(ra) # 80004630 <write_head>
}
    80004804:	70a2                	ld	ra,40(sp)
    80004806:	7402                	ld	s0,32(sp)
    80004808:	64e2                	ld	s1,24(sp)
    8000480a:	6942                	ld	s2,16(sp)
    8000480c:	69a2                	ld	s3,8(sp)
    8000480e:	6145                	addi	sp,sp,48
    80004810:	8082                	ret

0000000080004812 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004812:	1101                	addi	sp,sp,-32
    80004814:	ec06                	sd	ra,24(sp)
    80004816:	e822                	sd	s0,16(sp)
    80004818:	e426                	sd	s1,8(sp)
    8000481a:	e04a                	sd	s2,0(sp)
    8000481c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000481e:	00024517          	auipc	a0,0x24
    80004822:	9da50513          	addi	a0,a0,-1574 # 800281f8 <log>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	3b0080e7          	jalr	944(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000482e:	00024497          	auipc	s1,0x24
    80004832:	9ca48493          	addi	s1,s1,-1590 # 800281f8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004836:	4979                	li	s2,30
    80004838:	a039                	j	80004846 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000483a:	85a6                	mv	a1,s1
    8000483c:	8526                	mv	a0,s1
    8000483e:	ffffe097          	auipc	ra,0xffffe
    80004842:	c10080e7          	jalr	-1008(ra) # 8000244e <sleep>
    if(log.committing){
    80004846:	50dc                	lw	a5,36(s1)
    80004848:	fbed                	bnez	a5,8000483a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000484a:	509c                	lw	a5,32(s1)
    8000484c:	0017871b          	addiw	a4,a5,1
    80004850:	0007069b          	sext.w	a3,a4
    80004854:	0027179b          	slliw	a5,a4,0x2
    80004858:	9fb9                	addw	a5,a5,a4
    8000485a:	0017979b          	slliw	a5,a5,0x1
    8000485e:	54d8                	lw	a4,44(s1)
    80004860:	9fb9                	addw	a5,a5,a4
    80004862:	00f95963          	bge	s2,a5,80004874 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004866:	85a6                	mv	a1,s1
    80004868:	8526                	mv	a0,s1
    8000486a:	ffffe097          	auipc	ra,0xffffe
    8000486e:	be4080e7          	jalr	-1052(ra) # 8000244e <sleep>
    80004872:	bfd1                	j	80004846 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004874:	00024517          	auipc	a0,0x24
    80004878:	98450513          	addi	a0,a0,-1660 # 800281f8 <log>
    8000487c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	40c080e7          	jalr	1036(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004886:	60e2                	ld	ra,24(sp)
    80004888:	6442                	ld	s0,16(sp)
    8000488a:	64a2                	ld	s1,8(sp)
    8000488c:	6902                	ld	s2,0(sp)
    8000488e:	6105                	addi	sp,sp,32
    80004890:	8082                	ret

0000000080004892 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004892:	7139                	addi	sp,sp,-64
    80004894:	fc06                	sd	ra,56(sp)
    80004896:	f822                	sd	s0,48(sp)
    80004898:	f426                	sd	s1,40(sp)
    8000489a:	f04a                	sd	s2,32(sp)
    8000489c:	ec4e                	sd	s3,24(sp)
    8000489e:	e852                	sd	s4,16(sp)
    800048a0:	e456                	sd	s5,8(sp)
    800048a2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800048a4:	00024497          	auipc	s1,0x24
    800048a8:	95448493          	addi	s1,s1,-1708 # 800281f8 <log>
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	328080e7          	jalr	808(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800048b6:	509c                	lw	a5,32(s1)
    800048b8:	37fd                	addiw	a5,a5,-1
    800048ba:	0007891b          	sext.w	s2,a5
    800048be:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048c0:	50dc                	lw	a5,36(s1)
    800048c2:	e7b9                	bnez	a5,80004910 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048c4:	04091e63          	bnez	s2,80004920 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800048c8:	00024497          	auipc	s1,0x24
    800048cc:	93048493          	addi	s1,s1,-1744 # 800281f8 <log>
    800048d0:	4785                	li	a5,1
    800048d2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048d4:	8526                	mv	a0,s1
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	3b4080e7          	jalr	948(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048de:	54dc                	lw	a5,44(s1)
    800048e0:	06f04763          	bgtz	a5,8000494e <end_op+0xbc>
    acquire(&log.lock);
    800048e4:	00024497          	auipc	s1,0x24
    800048e8:	91448493          	addi	s1,s1,-1772 # 800281f8 <log>
    800048ec:	8526                	mv	a0,s1
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	2e8080e7          	jalr	744(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800048f6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048fa:	8526                	mv	a0,s1
    800048fc:	ffffe097          	auipc	ra,0xffffe
    80004900:	bc4080e7          	jalr	-1084(ra) # 800024c0 <wakeup>
    release(&log.lock);
    80004904:	8526                	mv	a0,s1
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	384080e7          	jalr	900(ra) # 80000c8a <release>
}
    8000490e:	a03d                	j	8000493c <end_op+0xaa>
    panic("log.committing");
    80004910:	00004517          	auipc	a0,0x4
    80004914:	db050513          	addi	a0,a0,-592 # 800086c0 <syscalls+0x208>
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	c26080e7          	jalr	-986(ra) # 8000053e <panic>
    wakeup(&log);
    80004920:	00024497          	auipc	s1,0x24
    80004924:	8d848493          	addi	s1,s1,-1832 # 800281f8 <log>
    80004928:	8526                	mv	a0,s1
    8000492a:	ffffe097          	auipc	ra,0xffffe
    8000492e:	b96080e7          	jalr	-1130(ra) # 800024c0 <wakeup>
  release(&log.lock);
    80004932:	8526                	mv	a0,s1
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	356080e7          	jalr	854(ra) # 80000c8a <release>
}
    8000493c:	70e2                	ld	ra,56(sp)
    8000493e:	7442                	ld	s0,48(sp)
    80004940:	74a2                	ld	s1,40(sp)
    80004942:	7902                	ld	s2,32(sp)
    80004944:	69e2                	ld	s3,24(sp)
    80004946:	6a42                	ld	s4,16(sp)
    80004948:	6aa2                	ld	s5,8(sp)
    8000494a:	6121                	addi	sp,sp,64
    8000494c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000494e:	00024a97          	auipc	s5,0x24
    80004952:	8daa8a93          	addi	s5,s5,-1830 # 80028228 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004956:	00024a17          	auipc	s4,0x24
    8000495a:	8a2a0a13          	addi	s4,s4,-1886 # 800281f8 <log>
    8000495e:	018a2583          	lw	a1,24(s4)
    80004962:	012585bb          	addw	a1,a1,s2
    80004966:	2585                	addiw	a1,a1,1
    80004968:	028a2503          	lw	a0,40(s4)
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	cca080e7          	jalr	-822(ra) # 80003636 <bread>
    80004974:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004976:	000aa583          	lw	a1,0(s5)
    8000497a:	028a2503          	lw	a0,40(s4)
    8000497e:	fffff097          	auipc	ra,0xfffff
    80004982:	cb8080e7          	jalr	-840(ra) # 80003636 <bread>
    80004986:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004988:	40000613          	li	a2,1024
    8000498c:	05850593          	addi	a1,a0,88
    80004990:	05848513          	addi	a0,s1,88
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	39a080e7          	jalr	922(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000499c:	8526                	mv	a0,s1
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	d8a080e7          	jalr	-630(ra) # 80003728 <bwrite>
    brelse(from);
    800049a6:	854e                	mv	a0,s3
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	dbe080e7          	jalr	-578(ra) # 80003766 <brelse>
    brelse(to);
    800049b0:	8526                	mv	a0,s1
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	db4080e7          	jalr	-588(ra) # 80003766 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049ba:	2905                	addiw	s2,s2,1
    800049bc:	0a91                	addi	s5,s5,4
    800049be:	02ca2783          	lw	a5,44(s4)
    800049c2:	f8f94ee3          	blt	s2,a5,8000495e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	c6a080e7          	jalr	-918(ra) # 80004630 <write_head>
    install_trans(0); // Now install writes to home locations
    800049ce:	4501                	li	a0,0
    800049d0:	00000097          	auipc	ra,0x0
    800049d4:	cda080e7          	jalr	-806(ra) # 800046aa <install_trans>
    log.lh.n = 0;
    800049d8:	00024797          	auipc	a5,0x24
    800049dc:	8407a623          	sw	zero,-1972(a5) # 80028224 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	c50080e7          	jalr	-944(ra) # 80004630 <write_head>
    800049e8:	bdf5                	j	800048e4 <end_op+0x52>

00000000800049ea <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049ea:	1101                	addi	sp,sp,-32
    800049ec:	ec06                	sd	ra,24(sp)
    800049ee:	e822                	sd	s0,16(sp)
    800049f0:	e426                	sd	s1,8(sp)
    800049f2:	e04a                	sd	s2,0(sp)
    800049f4:	1000                	addi	s0,sp,32
    800049f6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049f8:	00024917          	auipc	s2,0x24
    800049fc:	80090913          	addi	s2,s2,-2048 # 800281f8 <log>
    80004a00:	854a                	mv	a0,s2
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	1d4080e7          	jalr	468(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a0a:	02c92603          	lw	a2,44(s2)
    80004a0e:	47f5                	li	a5,29
    80004a10:	06c7c563          	blt	a5,a2,80004a7a <log_write+0x90>
    80004a14:	00024797          	auipc	a5,0x24
    80004a18:	8007a783          	lw	a5,-2048(a5) # 80028214 <log+0x1c>
    80004a1c:	37fd                	addiw	a5,a5,-1
    80004a1e:	04f65e63          	bge	a2,a5,80004a7a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a22:	00023797          	auipc	a5,0x23
    80004a26:	7f67a783          	lw	a5,2038(a5) # 80028218 <log+0x20>
    80004a2a:	06f05063          	blez	a5,80004a8a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a2e:	4781                	li	a5,0
    80004a30:	06c05563          	blez	a2,80004a9a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a34:	44cc                	lw	a1,12(s1)
    80004a36:	00023717          	auipc	a4,0x23
    80004a3a:	7f270713          	addi	a4,a4,2034 # 80028228 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a3e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a40:	4314                	lw	a3,0(a4)
    80004a42:	04b68c63          	beq	a3,a1,80004a9a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a46:	2785                	addiw	a5,a5,1
    80004a48:	0711                	addi	a4,a4,4
    80004a4a:	fef61be3          	bne	a2,a5,80004a40 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a4e:	0621                	addi	a2,a2,8
    80004a50:	060a                	slli	a2,a2,0x2
    80004a52:	00023797          	auipc	a5,0x23
    80004a56:	7a678793          	addi	a5,a5,1958 # 800281f8 <log>
    80004a5a:	963e                	add	a2,a2,a5
    80004a5c:	44dc                	lw	a5,12(s1)
    80004a5e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a60:	8526                	mv	a0,s1
    80004a62:	fffff097          	auipc	ra,0xfffff
    80004a66:	da2080e7          	jalr	-606(ra) # 80003804 <bpin>
    log.lh.n++;
    80004a6a:	00023717          	auipc	a4,0x23
    80004a6e:	78e70713          	addi	a4,a4,1934 # 800281f8 <log>
    80004a72:	575c                	lw	a5,44(a4)
    80004a74:	2785                	addiw	a5,a5,1
    80004a76:	d75c                	sw	a5,44(a4)
    80004a78:	a835                	j	80004ab4 <log_write+0xca>
    panic("too big a transaction");
    80004a7a:	00004517          	auipc	a0,0x4
    80004a7e:	c5650513          	addi	a0,a0,-938 # 800086d0 <syscalls+0x218>
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	abc080e7          	jalr	-1348(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a8a:	00004517          	auipc	a0,0x4
    80004a8e:	c5e50513          	addi	a0,a0,-930 # 800086e8 <syscalls+0x230>
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	aac080e7          	jalr	-1364(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a9a:	00878713          	addi	a4,a5,8
    80004a9e:	00271693          	slli	a3,a4,0x2
    80004aa2:	00023717          	auipc	a4,0x23
    80004aa6:	75670713          	addi	a4,a4,1878 # 800281f8 <log>
    80004aaa:	9736                	add	a4,a4,a3
    80004aac:	44d4                	lw	a3,12(s1)
    80004aae:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004ab0:	faf608e3          	beq	a2,a5,80004a60 <log_write+0x76>
  }
  release(&log.lock);
    80004ab4:	00023517          	auipc	a0,0x23
    80004ab8:	74450513          	addi	a0,a0,1860 # 800281f8 <log>
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	1ce080e7          	jalr	462(ra) # 80000c8a <release>
}
    80004ac4:	60e2                	ld	ra,24(sp)
    80004ac6:	6442                	ld	s0,16(sp)
    80004ac8:	64a2                	ld	s1,8(sp)
    80004aca:	6902                	ld	s2,0(sp)
    80004acc:	6105                	addi	sp,sp,32
    80004ace:	8082                	ret

0000000080004ad0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ad0:	1101                	addi	sp,sp,-32
    80004ad2:	ec06                	sd	ra,24(sp)
    80004ad4:	e822                	sd	s0,16(sp)
    80004ad6:	e426                	sd	s1,8(sp)
    80004ad8:	e04a                	sd	s2,0(sp)
    80004ada:	1000                	addi	s0,sp,32
    80004adc:	84aa                	mv	s1,a0
    80004ade:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ae0:	00004597          	auipc	a1,0x4
    80004ae4:	c2858593          	addi	a1,a1,-984 # 80008708 <syscalls+0x250>
    80004ae8:	0521                	addi	a0,a0,8
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	05c080e7          	jalr	92(ra) # 80000b46 <initlock>
  lk->name = name;
    80004af2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004af6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004afa:	0204a423          	sw	zero,40(s1)
}
    80004afe:	60e2                	ld	ra,24(sp)
    80004b00:	6442                	ld	s0,16(sp)
    80004b02:	64a2                	ld	s1,8(sp)
    80004b04:	6902                	ld	s2,0(sp)
    80004b06:	6105                	addi	sp,sp,32
    80004b08:	8082                	ret

0000000080004b0a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b0a:	1101                	addi	sp,sp,-32
    80004b0c:	ec06                	sd	ra,24(sp)
    80004b0e:	e822                	sd	s0,16(sp)
    80004b10:	e426                	sd	s1,8(sp)
    80004b12:	e04a                	sd	s2,0(sp)
    80004b14:	1000                	addi	s0,sp,32
    80004b16:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b18:	00850913          	addi	s2,a0,8
    80004b1c:	854a                	mv	a0,s2
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	0b8080e7          	jalr	184(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004b26:	409c                	lw	a5,0(s1)
    80004b28:	cb89                	beqz	a5,80004b3a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b2a:	85ca                	mv	a1,s2
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	ffffe097          	auipc	ra,0xffffe
    80004b32:	920080e7          	jalr	-1760(ra) # 8000244e <sleep>
  while (lk->locked) {
    80004b36:	409c                	lw	a5,0(s1)
    80004b38:	fbed                	bnez	a5,80004b2a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b3a:	4785                	li	a5,1
    80004b3c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b3e:	ffffd097          	auipc	ra,0xffffd
    80004b42:	0b8080e7          	jalr	184(ra) # 80001bf6 <myproc>
    80004b46:	591c                	lw	a5,48(a0)
    80004b48:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b4a:	854a                	mv	a0,s2
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	13e080e7          	jalr	318(ra) # 80000c8a <release>
}
    80004b54:	60e2                	ld	ra,24(sp)
    80004b56:	6442                	ld	s0,16(sp)
    80004b58:	64a2                	ld	s1,8(sp)
    80004b5a:	6902                	ld	s2,0(sp)
    80004b5c:	6105                	addi	sp,sp,32
    80004b5e:	8082                	ret

0000000080004b60 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b60:	1101                	addi	sp,sp,-32
    80004b62:	ec06                	sd	ra,24(sp)
    80004b64:	e822                	sd	s0,16(sp)
    80004b66:	e426                	sd	s1,8(sp)
    80004b68:	e04a                	sd	s2,0(sp)
    80004b6a:	1000                	addi	s0,sp,32
    80004b6c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b6e:	00850913          	addi	s2,a0,8
    80004b72:	854a                	mv	a0,s2
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	062080e7          	jalr	98(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004b7c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b80:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b84:	8526                	mv	a0,s1
    80004b86:	ffffe097          	auipc	ra,0xffffe
    80004b8a:	93a080e7          	jalr	-1734(ra) # 800024c0 <wakeup>
  release(&lk->lk);
    80004b8e:	854a                	mv	a0,s2
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	0fa080e7          	jalr	250(ra) # 80000c8a <release>
}
    80004b98:	60e2                	ld	ra,24(sp)
    80004b9a:	6442                	ld	s0,16(sp)
    80004b9c:	64a2                	ld	s1,8(sp)
    80004b9e:	6902                	ld	s2,0(sp)
    80004ba0:	6105                	addi	sp,sp,32
    80004ba2:	8082                	ret

0000000080004ba4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ba4:	7179                	addi	sp,sp,-48
    80004ba6:	f406                	sd	ra,40(sp)
    80004ba8:	f022                	sd	s0,32(sp)
    80004baa:	ec26                	sd	s1,24(sp)
    80004bac:	e84a                	sd	s2,16(sp)
    80004bae:	e44e                	sd	s3,8(sp)
    80004bb0:	1800                	addi	s0,sp,48
    80004bb2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004bb4:	00850913          	addi	s2,a0,8
    80004bb8:	854a                	mv	a0,s2
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	01c080e7          	jalr	28(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bc2:	409c                	lw	a5,0(s1)
    80004bc4:	ef99                	bnez	a5,80004be2 <holdingsleep+0x3e>
    80004bc6:	4481                	li	s1,0
  release(&lk->lk);
    80004bc8:	854a                	mv	a0,s2
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	0c0080e7          	jalr	192(ra) # 80000c8a <release>
  return r;
}
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	70a2                	ld	ra,40(sp)
    80004bd6:	7402                	ld	s0,32(sp)
    80004bd8:	64e2                	ld	s1,24(sp)
    80004bda:	6942                	ld	s2,16(sp)
    80004bdc:	69a2                	ld	s3,8(sp)
    80004bde:	6145                	addi	sp,sp,48
    80004be0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004be2:	0284a983          	lw	s3,40(s1)
    80004be6:	ffffd097          	auipc	ra,0xffffd
    80004bea:	010080e7          	jalr	16(ra) # 80001bf6 <myproc>
    80004bee:	5904                	lw	s1,48(a0)
    80004bf0:	413484b3          	sub	s1,s1,s3
    80004bf4:	0014b493          	seqz	s1,s1
    80004bf8:	bfc1                	j	80004bc8 <holdingsleep+0x24>

0000000080004bfa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bfa:	1141                	addi	sp,sp,-16
    80004bfc:	e406                	sd	ra,8(sp)
    80004bfe:	e022                	sd	s0,0(sp)
    80004c00:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c02:	00004597          	auipc	a1,0x4
    80004c06:	b1658593          	addi	a1,a1,-1258 # 80008718 <syscalls+0x260>
    80004c0a:	00023517          	auipc	a0,0x23
    80004c0e:	73650513          	addi	a0,a0,1846 # 80028340 <ftable>
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	f34080e7          	jalr	-204(ra) # 80000b46 <initlock>
}
    80004c1a:	60a2                	ld	ra,8(sp)
    80004c1c:	6402                	ld	s0,0(sp)
    80004c1e:	0141                	addi	sp,sp,16
    80004c20:	8082                	ret

0000000080004c22 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c22:	1101                	addi	sp,sp,-32
    80004c24:	ec06                	sd	ra,24(sp)
    80004c26:	e822                	sd	s0,16(sp)
    80004c28:	e426                	sd	s1,8(sp)
    80004c2a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c2c:	00023517          	auipc	a0,0x23
    80004c30:	71450513          	addi	a0,a0,1812 # 80028340 <ftable>
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	fa2080e7          	jalr	-94(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c3c:	00023497          	auipc	s1,0x23
    80004c40:	71c48493          	addi	s1,s1,1820 # 80028358 <ftable+0x18>
    80004c44:	00024717          	auipc	a4,0x24
    80004c48:	6b470713          	addi	a4,a4,1716 # 800292f8 <disk>
    if(f->ref == 0){
    80004c4c:	40dc                	lw	a5,4(s1)
    80004c4e:	cf99                	beqz	a5,80004c6c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c50:	02848493          	addi	s1,s1,40
    80004c54:	fee49ce3          	bne	s1,a4,80004c4c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c58:	00023517          	auipc	a0,0x23
    80004c5c:	6e850513          	addi	a0,a0,1768 # 80028340 <ftable>
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
  return 0;
    80004c68:	4481                	li	s1,0
    80004c6a:	a819                	j	80004c80 <filealloc+0x5e>
      f->ref = 1;
    80004c6c:	4785                	li	a5,1
    80004c6e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c70:	00023517          	auipc	a0,0x23
    80004c74:	6d050513          	addi	a0,a0,1744 # 80028340 <ftable>
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
}
    80004c80:	8526                	mv	a0,s1
    80004c82:	60e2                	ld	ra,24(sp)
    80004c84:	6442                	ld	s0,16(sp)
    80004c86:	64a2                	ld	s1,8(sp)
    80004c88:	6105                	addi	sp,sp,32
    80004c8a:	8082                	ret

0000000080004c8c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c8c:	1101                	addi	sp,sp,-32
    80004c8e:	ec06                	sd	ra,24(sp)
    80004c90:	e822                	sd	s0,16(sp)
    80004c92:	e426                	sd	s1,8(sp)
    80004c94:	1000                	addi	s0,sp,32
    80004c96:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c98:	00023517          	auipc	a0,0x23
    80004c9c:	6a850513          	addi	a0,a0,1704 # 80028340 <ftable>
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	f36080e7          	jalr	-202(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004ca8:	40dc                	lw	a5,4(s1)
    80004caa:	02f05263          	blez	a5,80004cce <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004cae:	2785                	addiw	a5,a5,1
    80004cb0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004cb2:	00023517          	auipc	a0,0x23
    80004cb6:	68e50513          	addi	a0,a0,1678 # 80028340 <ftable>
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	fd0080e7          	jalr	-48(ra) # 80000c8a <release>
  return f;
}
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	60e2                	ld	ra,24(sp)
    80004cc6:	6442                	ld	s0,16(sp)
    80004cc8:	64a2                	ld	s1,8(sp)
    80004cca:	6105                	addi	sp,sp,32
    80004ccc:	8082                	ret
    panic("filedup");
    80004cce:	00004517          	auipc	a0,0x4
    80004cd2:	a5250513          	addi	a0,a0,-1454 # 80008720 <syscalls+0x268>
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	868080e7          	jalr	-1944(ra) # 8000053e <panic>

0000000080004cde <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cde:	7139                	addi	sp,sp,-64
    80004ce0:	fc06                	sd	ra,56(sp)
    80004ce2:	f822                	sd	s0,48(sp)
    80004ce4:	f426                	sd	s1,40(sp)
    80004ce6:	f04a                	sd	s2,32(sp)
    80004ce8:	ec4e                	sd	s3,24(sp)
    80004cea:	e852                	sd	s4,16(sp)
    80004cec:	e456                	sd	s5,8(sp)
    80004cee:	0080                	addi	s0,sp,64
    80004cf0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cf2:	00023517          	auipc	a0,0x23
    80004cf6:	64e50513          	addi	a0,a0,1614 # 80028340 <ftable>
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	edc080e7          	jalr	-292(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004d02:	40dc                	lw	a5,4(s1)
    80004d04:	06f05163          	blez	a5,80004d66 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d08:	37fd                	addiw	a5,a5,-1
    80004d0a:	0007871b          	sext.w	a4,a5
    80004d0e:	c0dc                	sw	a5,4(s1)
    80004d10:	06e04363          	bgtz	a4,80004d76 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d14:	0004a903          	lw	s2,0(s1)
    80004d18:	0094ca83          	lbu	s5,9(s1)
    80004d1c:	0104ba03          	ld	s4,16(s1)
    80004d20:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d24:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d28:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d2c:	00023517          	auipc	a0,0x23
    80004d30:	61450513          	addi	a0,a0,1556 # 80028340 <ftable>
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	f56080e7          	jalr	-170(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004d3c:	4785                	li	a5,1
    80004d3e:	04f90d63          	beq	s2,a5,80004d98 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d42:	3979                	addiw	s2,s2,-2
    80004d44:	4785                	li	a5,1
    80004d46:	0527e063          	bltu	a5,s2,80004d86 <fileclose+0xa8>
    begin_op();
    80004d4a:	00000097          	auipc	ra,0x0
    80004d4e:	ac8080e7          	jalr	-1336(ra) # 80004812 <begin_op>
    iput(ff.ip);
    80004d52:	854e                	mv	a0,s3
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	2b6080e7          	jalr	694(ra) # 8000400a <iput>
    end_op();
    80004d5c:	00000097          	auipc	ra,0x0
    80004d60:	b36080e7          	jalr	-1226(ra) # 80004892 <end_op>
    80004d64:	a00d                	j	80004d86 <fileclose+0xa8>
    panic("fileclose");
    80004d66:	00004517          	auipc	a0,0x4
    80004d6a:	9c250513          	addi	a0,a0,-1598 # 80008728 <syscalls+0x270>
    80004d6e:	ffffb097          	auipc	ra,0xffffb
    80004d72:	7d0080e7          	jalr	2000(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d76:	00023517          	auipc	a0,0x23
    80004d7a:	5ca50513          	addi	a0,a0,1482 # 80028340 <ftable>
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	f0c080e7          	jalr	-244(ra) # 80000c8a <release>
  }
}
    80004d86:	70e2                	ld	ra,56(sp)
    80004d88:	7442                	ld	s0,48(sp)
    80004d8a:	74a2                	ld	s1,40(sp)
    80004d8c:	7902                	ld	s2,32(sp)
    80004d8e:	69e2                	ld	s3,24(sp)
    80004d90:	6a42                	ld	s4,16(sp)
    80004d92:	6aa2                	ld	s5,8(sp)
    80004d94:	6121                	addi	sp,sp,64
    80004d96:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d98:	85d6                	mv	a1,s5
    80004d9a:	8552                	mv	a0,s4
    80004d9c:	00000097          	auipc	ra,0x0
    80004da0:	34c080e7          	jalr	844(ra) # 800050e8 <pipeclose>
    80004da4:	b7cd                	j	80004d86 <fileclose+0xa8>

0000000080004da6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004da6:	715d                	addi	sp,sp,-80
    80004da8:	e486                	sd	ra,72(sp)
    80004daa:	e0a2                	sd	s0,64(sp)
    80004dac:	fc26                	sd	s1,56(sp)
    80004dae:	f84a                	sd	s2,48(sp)
    80004db0:	f44e                	sd	s3,40(sp)
    80004db2:	0880                	addi	s0,sp,80
    80004db4:	84aa                	mv	s1,a0
    80004db6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	e3e080e7          	jalr	-450(ra) # 80001bf6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004dc0:	409c                	lw	a5,0(s1)
    80004dc2:	37f9                	addiw	a5,a5,-2
    80004dc4:	4705                	li	a4,1
    80004dc6:	04f76763          	bltu	a4,a5,80004e14 <filestat+0x6e>
    80004dca:	892a                	mv	s2,a0
    ilock(f->ip);
    80004dcc:	6c88                	ld	a0,24(s1)
    80004dce:	fffff097          	auipc	ra,0xfffff
    80004dd2:	082080e7          	jalr	130(ra) # 80003e50 <ilock>
    stati(f->ip, &st);
    80004dd6:	fb840593          	addi	a1,s0,-72
    80004dda:	6c88                	ld	a0,24(s1)
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	2fe080e7          	jalr	766(ra) # 800040da <stati>
    iunlock(f->ip);
    80004de4:	6c88                	ld	a0,24(s1)
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	12c080e7          	jalr	300(ra) # 80003f12 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004dee:	46e1                	li	a3,24
    80004df0:	fb840613          	addi	a2,s0,-72
    80004df4:	85ce                	mv	a1,s3
    80004df6:	05093503          	ld	a0,80(s2)
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	86e080e7          	jalr	-1938(ra) # 80001668 <copyout>
    80004e02:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e06:	60a6                	ld	ra,72(sp)
    80004e08:	6406                	ld	s0,64(sp)
    80004e0a:	74e2                	ld	s1,56(sp)
    80004e0c:	7942                	ld	s2,48(sp)
    80004e0e:	79a2                	ld	s3,40(sp)
    80004e10:	6161                	addi	sp,sp,80
    80004e12:	8082                	ret
  return -1;
    80004e14:	557d                	li	a0,-1
    80004e16:	bfc5                	j	80004e06 <filestat+0x60>

0000000080004e18 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e18:	7179                	addi	sp,sp,-48
    80004e1a:	f406                	sd	ra,40(sp)
    80004e1c:	f022                	sd	s0,32(sp)
    80004e1e:	ec26                	sd	s1,24(sp)
    80004e20:	e84a                	sd	s2,16(sp)
    80004e22:	e44e                	sd	s3,8(sp)
    80004e24:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e26:	00854783          	lbu	a5,8(a0)
    80004e2a:	c3d5                	beqz	a5,80004ece <fileread+0xb6>
    80004e2c:	84aa                	mv	s1,a0
    80004e2e:	89ae                	mv	s3,a1
    80004e30:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e32:	411c                	lw	a5,0(a0)
    80004e34:	4705                	li	a4,1
    80004e36:	04e78963          	beq	a5,a4,80004e88 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e3a:	470d                	li	a4,3
    80004e3c:	04e78d63          	beq	a5,a4,80004e96 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e40:	4709                	li	a4,2
    80004e42:	06e79e63          	bne	a5,a4,80004ebe <fileread+0xa6>
    ilock(f->ip);
    80004e46:	6d08                	ld	a0,24(a0)
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	008080e7          	jalr	8(ra) # 80003e50 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e50:	874a                	mv	a4,s2
    80004e52:	5094                	lw	a3,32(s1)
    80004e54:	864e                	mv	a2,s3
    80004e56:	4585                	li	a1,1
    80004e58:	6c88                	ld	a0,24(s1)
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	2aa080e7          	jalr	682(ra) # 80004104 <readi>
    80004e62:	892a                	mv	s2,a0
    80004e64:	00a05563          	blez	a0,80004e6e <fileread+0x56>
      f->off += r;
    80004e68:	509c                	lw	a5,32(s1)
    80004e6a:	9fa9                	addw	a5,a5,a0
    80004e6c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e6e:	6c88                	ld	a0,24(s1)
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	0a2080e7          	jalr	162(ra) # 80003f12 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e78:	854a                	mv	a0,s2
    80004e7a:	70a2                	ld	ra,40(sp)
    80004e7c:	7402                	ld	s0,32(sp)
    80004e7e:	64e2                	ld	s1,24(sp)
    80004e80:	6942                	ld	s2,16(sp)
    80004e82:	69a2                	ld	s3,8(sp)
    80004e84:	6145                	addi	sp,sp,48
    80004e86:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e88:	6908                	ld	a0,16(a0)
    80004e8a:	00000097          	auipc	ra,0x0
    80004e8e:	3c6080e7          	jalr	966(ra) # 80005250 <piperead>
    80004e92:	892a                	mv	s2,a0
    80004e94:	b7d5                	j	80004e78 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e96:	02451783          	lh	a5,36(a0)
    80004e9a:	03079693          	slli	a3,a5,0x30
    80004e9e:	92c1                	srli	a3,a3,0x30
    80004ea0:	4725                	li	a4,9
    80004ea2:	02d76863          	bltu	a4,a3,80004ed2 <fileread+0xba>
    80004ea6:	0792                	slli	a5,a5,0x4
    80004ea8:	00023717          	auipc	a4,0x23
    80004eac:	3f870713          	addi	a4,a4,1016 # 800282a0 <devsw>
    80004eb0:	97ba                	add	a5,a5,a4
    80004eb2:	639c                	ld	a5,0(a5)
    80004eb4:	c38d                	beqz	a5,80004ed6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004eb6:	4505                	li	a0,1
    80004eb8:	9782                	jalr	a5
    80004eba:	892a                	mv	s2,a0
    80004ebc:	bf75                	j	80004e78 <fileread+0x60>
    panic("fileread");
    80004ebe:	00004517          	auipc	a0,0x4
    80004ec2:	87a50513          	addi	a0,a0,-1926 # 80008738 <syscalls+0x280>
    80004ec6:	ffffb097          	auipc	ra,0xffffb
    80004eca:	678080e7          	jalr	1656(ra) # 8000053e <panic>
    return -1;
    80004ece:	597d                	li	s2,-1
    80004ed0:	b765                	j	80004e78 <fileread+0x60>
      return -1;
    80004ed2:	597d                	li	s2,-1
    80004ed4:	b755                	j	80004e78 <fileread+0x60>
    80004ed6:	597d                	li	s2,-1
    80004ed8:	b745                	j	80004e78 <fileread+0x60>

0000000080004eda <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004eda:	715d                	addi	sp,sp,-80
    80004edc:	e486                	sd	ra,72(sp)
    80004ede:	e0a2                	sd	s0,64(sp)
    80004ee0:	fc26                	sd	s1,56(sp)
    80004ee2:	f84a                	sd	s2,48(sp)
    80004ee4:	f44e                	sd	s3,40(sp)
    80004ee6:	f052                	sd	s4,32(sp)
    80004ee8:	ec56                	sd	s5,24(sp)
    80004eea:	e85a                	sd	s6,16(sp)
    80004eec:	e45e                	sd	s7,8(sp)
    80004eee:	e062                	sd	s8,0(sp)
    80004ef0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ef2:	00954783          	lbu	a5,9(a0)
    80004ef6:	10078663          	beqz	a5,80005002 <filewrite+0x128>
    80004efa:	892a                	mv	s2,a0
    80004efc:	8aae                	mv	s5,a1
    80004efe:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f00:	411c                	lw	a5,0(a0)
    80004f02:	4705                	li	a4,1
    80004f04:	02e78263          	beq	a5,a4,80004f28 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f08:	470d                	li	a4,3
    80004f0a:	02e78663          	beq	a5,a4,80004f36 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f0e:	4709                	li	a4,2
    80004f10:	0ee79163          	bne	a5,a4,80004ff2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f14:	0ac05d63          	blez	a2,80004fce <filewrite+0xf4>
    int i = 0;
    80004f18:	4981                	li	s3,0
    80004f1a:	6b05                	lui	s6,0x1
    80004f1c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f20:	6b85                	lui	s7,0x1
    80004f22:	c00b8b9b          	addiw	s7,s7,-1024
    80004f26:	a861                	j	80004fbe <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f28:	6908                	ld	a0,16(a0)
    80004f2a:	00000097          	auipc	ra,0x0
    80004f2e:	22e080e7          	jalr	558(ra) # 80005158 <pipewrite>
    80004f32:	8a2a                	mv	s4,a0
    80004f34:	a045                	j	80004fd4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f36:	02451783          	lh	a5,36(a0)
    80004f3a:	03079693          	slli	a3,a5,0x30
    80004f3e:	92c1                	srli	a3,a3,0x30
    80004f40:	4725                	li	a4,9
    80004f42:	0cd76263          	bltu	a4,a3,80005006 <filewrite+0x12c>
    80004f46:	0792                	slli	a5,a5,0x4
    80004f48:	00023717          	auipc	a4,0x23
    80004f4c:	35870713          	addi	a4,a4,856 # 800282a0 <devsw>
    80004f50:	97ba                	add	a5,a5,a4
    80004f52:	679c                	ld	a5,8(a5)
    80004f54:	cbdd                	beqz	a5,8000500a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f56:	4505                	li	a0,1
    80004f58:	9782                	jalr	a5
    80004f5a:	8a2a                	mv	s4,a0
    80004f5c:	a8a5                	j	80004fd4 <filewrite+0xfa>
    80004f5e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f62:	00000097          	auipc	ra,0x0
    80004f66:	8b0080e7          	jalr	-1872(ra) # 80004812 <begin_op>
      ilock(f->ip);
    80004f6a:	01893503          	ld	a0,24(s2)
    80004f6e:	fffff097          	auipc	ra,0xfffff
    80004f72:	ee2080e7          	jalr	-286(ra) # 80003e50 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f76:	8762                	mv	a4,s8
    80004f78:	02092683          	lw	a3,32(s2)
    80004f7c:	01598633          	add	a2,s3,s5
    80004f80:	4585                	li	a1,1
    80004f82:	01893503          	ld	a0,24(s2)
    80004f86:	fffff097          	auipc	ra,0xfffff
    80004f8a:	276080e7          	jalr	630(ra) # 800041fc <writei>
    80004f8e:	84aa                	mv	s1,a0
    80004f90:	00a05763          	blez	a0,80004f9e <filewrite+0xc4>
        f->off += r;
    80004f94:	02092783          	lw	a5,32(s2)
    80004f98:	9fa9                	addw	a5,a5,a0
    80004f9a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f9e:	01893503          	ld	a0,24(s2)
    80004fa2:	fffff097          	auipc	ra,0xfffff
    80004fa6:	f70080e7          	jalr	-144(ra) # 80003f12 <iunlock>
      end_op();
    80004faa:	00000097          	auipc	ra,0x0
    80004fae:	8e8080e7          	jalr	-1816(ra) # 80004892 <end_op>

      if(r != n1){
    80004fb2:	009c1f63          	bne	s8,s1,80004fd0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004fb6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004fba:	0149db63          	bge	s3,s4,80004fd0 <filewrite+0xf6>
      int n1 = n - i;
    80004fbe:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004fc2:	84be                	mv	s1,a5
    80004fc4:	2781                	sext.w	a5,a5
    80004fc6:	f8fb5ce3          	bge	s6,a5,80004f5e <filewrite+0x84>
    80004fca:	84de                	mv	s1,s7
    80004fcc:	bf49                	j	80004f5e <filewrite+0x84>
    int i = 0;
    80004fce:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fd0:	013a1f63          	bne	s4,s3,80004fee <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fd4:	8552                	mv	a0,s4
    80004fd6:	60a6                	ld	ra,72(sp)
    80004fd8:	6406                	ld	s0,64(sp)
    80004fda:	74e2                	ld	s1,56(sp)
    80004fdc:	7942                	ld	s2,48(sp)
    80004fde:	79a2                	ld	s3,40(sp)
    80004fe0:	7a02                	ld	s4,32(sp)
    80004fe2:	6ae2                	ld	s5,24(sp)
    80004fe4:	6b42                	ld	s6,16(sp)
    80004fe6:	6ba2                	ld	s7,8(sp)
    80004fe8:	6c02                	ld	s8,0(sp)
    80004fea:	6161                	addi	sp,sp,80
    80004fec:	8082                	ret
    ret = (i == n ? n : -1);
    80004fee:	5a7d                	li	s4,-1
    80004ff0:	b7d5                	j	80004fd4 <filewrite+0xfa>
    panic("filewrite");
    80004ff2:	00003517          	auipc	a0,0x3
    80004ff6:	75650513          	addi	a0,a0,1878 # 80008748 <syscalls+0x290>
    80004ffa:	ffffb097          	auipc	ra,0xffffb
    80004ffe:	544080e7          	jalr	1348(ra) # 8000053e <panic>
    return -1;
    80005002:	5a7d                	li	s4,-1
    80005004:	bfc1                	j	80004fd4 <filewrite+0xfa>
      return -1;
    80005006:	5a7d                	li	s4,-1
    80005008:	b7f1                	j	80004fd4 <filewrite+0xfa>
    8000500a:	5a7d                	li	s4,-1
    8000500c:	b7e1                	j	80004fd4 <filewrite+0xfa>

000000008000500e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000500e:	7179                	addi	sp,sp,-48
    80005010:	f406                	sd	ra,40(sp)
    80005012:	f022                	sd	s0,32(sp)
    80005014:	ec26                	sd	s1,24(sp)
    80005016:	e84a                	sd	s2,16(sp)
    80005018:	e44e                	sd	s3,8(sp)
    8000501a:	e052                	sd	s4,0(sp)
    8000501c:	1800                	addi	s0,sp,48
    8000501e:	84aa                	mv	s1,a0
    80005020:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005022:	0005b023          	sd	zero,0(a1)
    80005026:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000502a:	00000097          	auipc	ra,0x0
    8000502e:	bf8080e7          	jalr	-1032(ra) # 80004c22 <filealloc>
    80005032:	e088                	sd	a0,0(s1)
    80005034:	c551                	beqz	a0,800050c0 <pipealloc+0xb2>
    80005036:	00000097          	auipc	ra,0x0
    8000503a:	bec080e7          	jalr	-1044(ra) # 80004c22 <filealloc>
    8000503e:	00aa3023          	sd	a0,0(s4)
    80005042:	c92d                	beqz	a0,800050b4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	aa2080e7          	jalr	-1374(ra) # 80000ae6 <kalloc>
    8000504c:	892a                	mv	s2,a0
    8000504e:	c125                	beqz	a0,800050ae <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005050:	4985                	li	s3,1
    80005052:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005056:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000505a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000505e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005062:	00003597          	auipc	a1,0x3
    80005066:	6f658593          	addi	a1,a1,1782 # 80008758 <syscalls+0x2a0>
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	adc080e7          	jalr	-1316(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80005072:	609c                	ld	a5,0(s1)
    80005074:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005078:	609c                	ld	a5,0(s1)
    8000507a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000507e:	609c                	ld	a5,0(s1)
    80005080:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005084:	609c                	ld	a5,0(s1)
    80005086:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000508a:	000a3783          	ld	a5,0(s4)
    8000508e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005092:	000a3783          	ld	a5,0(s4)
    80005096:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000509a:	000a3783          	ld	a5,0(s4)
    8000509e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800050a2:	000a3783          	ld	a5,0(s4)
    800050a6:	0127b823          	sd	s2,16(a5)
  return 0;
    800050aa:	4501                	li	a0,0
    800050ac:	a025                	j	800050d4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050ae:	6088                	ld	a0,0(s1)
    800050b0:	e501                	bnez	a0,800050b8 <pipealloc+0xaa>
    800050b2:	a039                	j	800050c0 <pipealloc+0xb2>
    800050b4:	6088                	ld	a0,0(s1)
    800050b6:	c51d                	beqz	a0,800050e4 <pipealloc+0xd6>
    fileclose(*f0);
    800050b8:	00000097          	auipc	ra,0x0
    800050bc:	c26080e7          	jalr	-986(ra) # 80004cde <fileclose>
  if(*f1)
    800050c0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050c4:	557d                	li	a0,-1
  if(*f1)
    800050c6:	c799                	beqz	a5,800050d4 <pipealloc+0xc6>
    fileclose(*f1);
    800050c8:	853e                	mv	a0,a5
    800050ca:	00000097          	auipc	ra,0x0
    800050ce:	c14080e7          	jalr	-1004(ra) # 80004cde <fileclose>
  return -1;
    800050d2:	557d                	li	a0,-1
}
    800050d4:	70a2                	ld	ra,40(sp)
    800050d6:	7402                	ld	s0,32(sp)
    800050d8:	64e2                	ld	s1,24(sp)
    800050da:	6942                	ld	s2,16(sp)
    800050dc:	69a2                	ld	s3,8(sp)
    800050de:	6a02                	ld	s4,0(sp)
    800050e0:	6145                	addi	sp,sp,48
    800050e2:	8082                	ret
  return -1;
    800050e4:	557d                	li	a0,-1
    800050e6:	b7fd                	j	800050d4 <pipealloc+0xc6>

00000000800050e8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050e8:	1101                	addi	sp,sp,-32
    800050ea:	ec06                	sd	ra,24(sp)
    800050ec:	e822                	sd	s0,16(sp)
    800050ee:	e426                	sd	s1,8(sp)
    800050f0:	e04a                	sd	s2,0(sp)
    800050f2:	1000                	addi	s0,sp,32
    800050f4:	84aa                	mv	s1,a0
    800050f6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050f8:	ffffc097          	auipc	ra,0xffffc
    800050fc:	ade080e7          	jalr	-1314(ra) # 80000bd6 <acquire>
  if(writable){
    80005100:	02090d63          	beqz	s2,8000513a <pipeclose+0x52>
    pi->writeopen = 0;
    80005104:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005108:	21848513          	addi	a0,s1,536
    8000510c:	ffffd097          	auipc	ra,0xffffd
    80005110:	3b4080e7          	jalr	948(ra) # 800024c0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005114:	2204b783          	ld	a5,544(s1)
    80005118:	eb95                	bnez	a5,8000514c <pipeclose+0x64>
    release(&pi->lock);
    8000511a:	8526                	mv	a0,s1
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	b6e080e7          	jalr	-1170(ra) # 80000c8a <release>
    kfree((char*)pi);
    80005124:	8526                	mv	a0,s1
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	8c4080e7          	jalr	-1852(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    8000512e:	60e2                	ld	ra,24(sp)
    80005130:	6442                	ld	s0,16(sp)
    80005132:	64a2                	ld	s1,8(sp)
    80005134:	6902                	ld	s2,0(sp)
    80005136:	6105                	addi	sp,sp,32
    80005138:	8082                	ret
    pi->readopen = 0;
    8000513a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000513e:	21c48513          	addi	a0,s1,540
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	37e080e7          	jalr	894(ra) # 800024c0 <wakeup>
    8000514a:	b7e9                	j	80005114 <pipeclose+0x2c>
    release(&pi->lock);
    8000514c:	8526                	mv	a0,s1
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	b3c080e7          	jalr	-1220(ra) # 80000c8a <release>
}
    80005156:	bfe1                	j	8000512e <pipeclose+0x46>

0000000080005158 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005158:	711d                	addi	sp,sp,-96
    8000515a:	ec86                	sd	ra,88(sp)
    8000515c:	e8a2                	sd	s0,80(sp)
    8000515e:	e4a6                	sd	s1,72(sp)
    80005160:	e0ca                	sd	s2,64(sp)
    80005162:	fc4e                	sd	s3,56(sp)
    80005164:	f852                	sd	s4,48(sp)
    80005166:	f456                	sd	s5,40(sp)
    80005168:	f05a                	sd	s6,32(sp)
    8000516a:	ec5e                	sd	s7,24(sp)
    8000516c:	e862                	sd	s8,16(sp)
    8000516e:	1080                	addi	s0,sp,96
    80005170:	84aa                	mv	s1,a0
    80005172:	8aae                	mv	s5,a1
    80005174:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005176:	ffffd097          	auipc	ra,0xffffd
    8000517a:	a80080e7          	jalr	-1408(ra) # 80001bf6 <myproc>
    8000517e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005180:	8526                	mv	a0,s1
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	a54080e7          	jalr	-1452(ra) # 80000bd6 <acquire>
  while(i < n){
    8000518a:	0b405663          	blez	s4,80005236 <pipewrite+0xde>
  int i = 0;
    8000518e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005190:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005192:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005196:	21c48b93          	addi	s7,s1,540
    8000519a:	a089                	j	800051dc <pipewrite+0x84>
      release(&pi->lock);
    8000519c:	8526                	mv	a0,s1
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	aec080e7          	jalr	-1300(ra) # 80000c8a <release>
      return -1;
    800051a6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051a8:	854a                	mv	a0,s2
    800051aa:	60e6                	ld	ra,88(sp)
    800051ac:	6446                	ld	s0,80(sp)
    800051ae:	64a6                	ld	s1,72(sp)
    800051b0:	6906                	ld	s2,64(sp)
    800051b2:	79e2                	ld	s3,56(sp)
    800051b4:	7a42                	ld	s4,48(sp)
    800051b6:	7aa2                	ld	s5,40(sp)
    800051b8:	7b02                	ld	s6,32(sp)
    800051ba:	6be2                	ld	s7,24(sp)
    800051bc:	6c42                	ld	s8,16(sp)
    800051be:	6125                	addi	sp,sp,96
    800051c0:	8082                	ret
      wakeup(&pi->nread);
    800051c2:	8562                	mv	a0,s8
    800051c4:	ffffd097          	auipc	ra,0xffffd
    800051c8:	2fc080e7          	jalr	764(ra) # 800024c0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051cc:	85a6                	mv	a1,s1
    800051ce:	855e                	mv	a0,s7
    800051d0:	ffffd097          	auipc	ra,0xffffd
    800051d4:	27e080e7          	jalr	638(ra) # 8000244e <sleep>
  while(i < n){
    800051d8:	07495063          	bge	s2,s4,80005238 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800051dc:	2204a783          	lw	a5,544(s1)
    800051e0:	dfd5                	beqz	a5,8000519c <pipewrite+0x44>
    800051e2:	854e                	mv	a0,s3
    800051e4:	ffffd097          	auipc	ra,0xffffd
    800051e8:	55a080e7          	jalr	1370(ra) # 8000273e <killed>
    800051ec:	f945                	bnez	a0,8000519c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051ee:	2184a783          	lw	a5,536(s1)
    800051f2:	21c4a703          	lw	a4,540(s1)
    800051f6:	2007879b          	addiw	a5,a5,512
    800051fa:	fcf704e3          	beq	a4,a5,800051c2 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051fe:	4685                	li	a3,1
    80005200:	01590633          	add	a2,s2,s5
    80005204:	faf40593          	addi	a1,s0,-81
    80005208:	0509b503          	ld	a0,80(s3)
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	4e8080e7          	jalr	1256(ra) # 800016f4 <copyin>
    80005214:	03650263          	beq	a0,s6,80005238 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005218:	21c4a783          	lw	a5,540(s1)
    8000521c:	0017871b          	addiw	a4,a5,1
    80005220:	20e4ae23          	sw	a4,540(s1)
    80005224:	1ff7f793          	andi	a5,a5,511
    80005228:	97a6                	add	a5,a5,s1
    8000522a:	faf44703          	lbu	a4,-81(s0)
    8000522e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005232:	2905                	addiw	s2,s2,1
    80005234:	b755                	j	800051d8 <pipewrite+0x80>
  int i = 0;
    80005236:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005238:	21848513          	addi	a0,s1,536
    8000523c:	ffffd097          	auipc	ra,0xffffd
    80005240:	284080e7          	jalr	644(ra) # 800024c0 <wakeup>
  release(&pi->lock);
    80005244:	8526                	mv	a0,s1
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	a44080e7          	jalr	-1468(ra) # 80000c8a <release>
  return i;
    8000524e:	bfa9                	j	800051a8 <pipewrite+0x50>

0000000080005250 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005250:	715d                	addi	sp,sp,-80
    80005252:	e486                	sd	ra,72(sp)
    80005254:	e0a2                	sd	s0,64(sp)
    80005256:	fc26                	sd	s1,56(sp)
    80005258:	f84a                	sd	s2,48(sp)
    8000525a:	f44e                	sd	s3,40(sp)
    8000525c:	f052                	sd	s4,32(sp)
    8000525e:	ec56                	sd	s5,24(sp)
    80005260:	e85a                	sd	s6,16(sp)
    80005262:	0880                	addi	s0,sp,80
    80005264:	84aa                	mv	s1,a0
    80005266:	892e                	mv	s2,a1
    80005268:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000526a:	ffffd097          	auipc	ra,0xffffd
    8000526e:	98c080e7          	jalr	-1652(ra) # 80001bf6 <myproc>
    80005272:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005274:	8526                	mv	a0,s1
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	960080e7          	jalr	-1696(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000527e:	2184a703          	lw	a4,536(s1)
    80005282:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005286:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000528a:	02f71763          	bne	a4,a5,800052b8 <piperead+0x68>
    8000528e:	2244a783          	lw	a5,548(s1)
    80005292:	c39d                	beqz	a5,800052b8 <piperead+0x68>
    if(killed(pr)){
    80005294:	8552                	mv	a0,s4
    80005296:	ffffd097          	auipc	ra,0xffffd
    8000529a:	4a8080e7          	jalr	1192(ra) # 8000273e <killed>
    8000529e:	e941                	bnez	a0,8000532e <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052a0:	85a6                	mv	a1,s1
    800052a2:	854e                	mv	a0,s3
    800052a4:	ffffd097          	auipc	ra,0xffffd
    800052a8:	1aa080e7          	jalr	426(ra) # 8000244e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052ac:	2184a703          	lw	a4,536(s1)
    800052b0:	21c4a783          	lw	a5,540(s1)
    800052b4:	fcf70de3          	beq	a4,a5,8000528e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052b8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052ba:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052bc:	05505363          	blez	s5,80005302 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    800052c0:	2184a783          	lw	a5,536(s1)
    800052c4:	21c4a703          	lw	a4,540(s1)
    800052c8:	02f70d63          	beq	a4,a5,80005302 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052cc:	0017871b          	addiw	a4,a5,1
    800052d0:	20e4ac23          	sw	a4,536(s1)
    800052d4:	1ff7f793          	andi	a5,a5,511
    800052d8:	97a6                	add	a5,a5,s1
    800052da:	0187c783          	lbu	a5,24(a5)
    800052de:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052e2:	4685                	li	a3,1
    800052e4:	fbf40613          	addi	a2,s0,-65
    800052e8:	85ca                	mv	a1,s2
    800052ea:	050a3503          	ld	a0,80(s4)
    800052ee:	ffffc097          	auipc	ra,0xffffc
    800052f2:	37a080e7          	jalr	890(ra) # 80001668 <copyout>
    800052f6:	01650663          	beq	a0,s6,80005302 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052fa:	2985                	addiw	s3,s3,1
    800052fc:	0905                	addi	s2,s2,1
    800052fe:	fd3a91e3          	bne	s5,s3,800052c0 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005302:	21c48513          	addi	a0,s1,540
    80005306:	ffffd097          	auipc	ra,0xffffd
    8000530a:	1ba080e7          	jalr	442(ra) # 800024c0 <wakeup>
  release(&pi->lock);
    8000530e:	8526                	mv	a0,s1
    80005310:	ffffc097          	auipc	ra,0xffffc
    80005314:	97a080e7          	jalr	-1670(ra) # 80000c8a <release>
  return i;
}
    80005318:	854e                	mv	a0,s3
    8000531a:	60a6                	ld	ra,72(sp)
    8000531c:	6406                	ld	s0,64(sp)
    8000531e:	74e2                	ld	s1,56(sp)
    80005320:	7942                	ld	s2,48(sp)
    80005322:	79a2                	ld	s3,40(sp)
    80005324:	7a02                	ld	s4,32(sp)
    80005326:	6ae2                	ld	s5,24(sp)
    80005328:	6b42                	ld	s6,16(sp)
    8000532a:	6161                	addi	sp,sp,80
    8000532c:	8082                	ret
      release(&pi->lock);
    8000532e:	8526                	mv	a0,s1
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	95a080e7          	jalr	-1702(ra) # 80000c8a <release>
      return -1;
    80005338:	59fd                	li	s3,-1
    8000533a:	bff9                	j	80005318 <piperead+0xc8>

000000008000533c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000533c:	1141                	addi	sp,sp,-16
    8000533e:	e422                	sd	s0,8(sp)
    80005340:	0800                	addi	s0,sp,16
    80005342:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005344:	8905                	andi	a0,a0,1
    80005346:	c111                	beqz	a0,8000534a <flags2perm+0xe>
      perm = PTE_X;
    80005348:	4521                	li	a0,8
    if(flags & 0x2)
    8000534a:	8b89                	andi	a5,a5,2
    8000534c:	c399                	beqz	a5,80005352 <flags2perm+0x16>
      perm |= PTE_W;
    8000534e:	00456513          	ori	a0,a0,4
    return perm;
}
    80005352:	6422                	ld	s0,8(sp)
    80005354:	0141                	addi	sp,sp,16
    80005356:	8082                	ret

0000000080005358 <exec>:

int
exec(char *path, char **argv)
{
    80005358:	de010113          	addi	sp,sp,-544
    8000535c:	20113c23          	sd	ra,536(sp)
    80005360:	20813823          	sd	s0,528(sp)
    80005364:	20913423          	sd	s1,520(sp)
    80005368:	21213023          	sd	s2,512(sp)
    8000536c:	ffce                	sd	s3,504(sp)
    8000536e:	fbd2                	sd	s4,496(sp)
    80005370:	f7d6                	sd	s5,488(sp)
    80005372:	f3da                	sd	s6,480(sp)
    80005374:	efde                	sd	s7,472(sp)
    80005376:	ebe2                	sd	s8,464(sp)
    80005378:	e7e6                	sd	s9,456(sp)
    8000537a:	e3ea                	sd	s10,448(sp)
    8000537c:	ff6e                	sd	s11,440(sp)
    8000537e:	1400                	addi	s0,sp,544
    80005380:	892a                	mv	s2,a0
    80005382:	dea43423          	sd	a0,-536(s0)
    80005386:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000538a:	ffffd097          	auipc	ra,0xffffd
    8000538e:	86c080e7          	jalr	-1940(ra) # 80001bf6 <myproc>
    80005392:	84aa                	mv	s1,a0

  begin_op();
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	47e080e7          	jalr	1150(ra) # 80004812 <begin_op>

  if((ip = namei(path)) == 0){
    8000539c:	854a                	mv	a0,s2
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	258080e7          	jalr	600(ra) # 800045f6 <namei>
    800053a6:	c93d                	beqz	a0,8000541c <exec+0xc4>
    800053a8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	aa6080e7          	jalr	-1370(ra) # 80003e50 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800053b2:	04000713          	li	a4,64
    800053b6:	4681                	li	a3,0
    800053b8:	e5040613          	addi	a2,s0,-432
    800053bc:	4581                	li	a1,0
    800053be:	8556                	mv	a0,s5
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	d44080e7          	jalr	-700(ra) # 80004104 <readi>
    800053c8:	04000793          	li	a5,64
    800053cc:	00f51a63          	bne	a0,a5,800053e0 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800053d0:	e5042703          	lw	a4,-432(s0)
    800053d4:	464c47b7          	lui	a5,0x464c4
    800053d8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053dc:	04f70663          	beq	a4,a5,80005428 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053e0:	8556                	mv	a0,s5
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	cd0080e7          	jalr	-816(ra) # 800040b2 <iunlockput>
    end_op();
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	4a8080e7          	jalr	1192(ra) # 80004892 <end_op>
  }
  return -1;
    800053f2:	557d                	li	a0,-1
}
    800053f4:	21813083          	ld	ra,536(sp)
    800053f8:	21013403          	ld	s0,528(sp)
    800053fc:	20813483          	ld	s1,520(sp)
    80005400:	20013903          	ld	s2,512(sp)
    80005404:	79fe                	ld	s3,504(sp)
    80005406:	7a5e                	ld	s4,496(sp)
    80005408:	7abe                	ld	s5,488(sp)
    8000540a:	7b1e                	ld	s6,480(sp)
    8000540c:	6bfe                	ld	s7,472(sp)
    8000540e:	6c5e                	ld	s8,464(sp)
    80005410:	6cbe                	ld	s9,456(sp)
    80005412:	6d1e                	ld	s10,448(sp)
    80005414:	7dfa                	ld	s11,440(sp)
    80005416:	22010113          	addi	sp,sp,544
    8000541a:	8082                	ret
    end_op();
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	476080e7          	jalr	1142(ra) # 80004892 <end_op>
    return -1;
    80005424:	557d                	li	a0,-1
    80005426:	b7f9                	j	800053f4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005428:	8526                	mv	a0,s1
    8000542a:	ffffd097          	auipc	ra,0xffffd
    8000542e:	890080e7          	jalr	-1904(ra) # 80001cba <proc_pagetable>
    80005432:	8b2a                	mv	s6,a0
    80005434:	d555                	beqz	a0,800053e0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005436:	e7042783          	lw	a5,-400(s0)
    8000543a:	e8845703          	lhu	a4,-376(s0)
    8000543e:	c735                	beqz	a4,800054aa <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005440:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005442:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005446:	6a05                	lui	s4,0x1
    80005448:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000544c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005450:	6d85                	lui	s11,0x1
    80005452:	7d7d                	lui	s10,0xfffff
    80005454:	a481                	j	80005694 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005456:	00003517          	auipc	a0,0x3
    8000545a:	30a50513          	addi	a0,a0,778 # 80008760 <syscalls+0x2a8>
    8000545e:	ffffb097          	auipc	ra,0xffffb
    80005462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005466:	874a                	mv	a4,s2
    80005468:	009c86bb          	addw	a3,s9,s1
    8000546c:	4581                	li	a1,0
    8000546e:	8556                	mv	a0,s5
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	c94080e7          	jalr	-876(ra) # 80004104 <readi>
    80005478:	2501                	sext.w	a0,a0
    8000547a:	1aa91a63          	bne	s2,a0,8000562e <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    8000547e:	009d84bb          	addw	s1,s11,s1
    80005482:	013d09bb          	addw	s3,s10,s3
    80005486:	1f74f763          	bgeu	s1,s7,80005674 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000548a:	02049593          	slli	a1,s1,0x20
    8000548e:	9181                	srli	a1,a1,0x20
    80005490:	95e2                	add	a1,a1,s8
    80005492:	855a                	mv	a0,s6
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	bc8080e7          	jalr	-1080(ra) # 8000105c <walkaddr>
    8000549c:	862a                	mv	a2,a0
    if(pa == 0)
    8000549e:	dd45                	beqz	a0,80005456 <exec+0xfe>
      n = PGSIZE;
    800054a0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800054a2:	fd49f2e3          	bgeu	s3,s4,80005466 <exec+0x10e>
      n = sz - i;
    800054a6:	894e                	mv	s2,s3
    800054a8:	bf7d                	j	80005466 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054aa:	4901                	li	s2,0
  iunlockput(ip);
    800054ac:	8556                	mv	a0,s5
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	c04080e7          	jalr	-1020(ra) # 800040b2 <iunlockput>
  end_op();
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	3dc080e7          	jalr	988(ra) # 80004892 <end_op>
  p = myproc();
    800054be:	ffffc097          	auipc	ra,0xffffc
    800054c2:	738080e7          	jalr	1848(ra) # 80001bf6 <myproc>
    800054c6:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800054c8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800054cc:	6785                	lui	a5,0x1
    800054ce:	17fd                	addi	a5,a5,-1
    800054d0:	993e                	add	s2,s2,a5
    800054d2:	77fd                	lui	a5,0xfffff
    800054d4:	00f977b3          	and	a5,s2,a5
    800054d8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054dc:	4691                	li	a3,4
    800054de:	6609                	lui	a2,0x2
    800054e0:	963e                	add	a2,a2,a5
    800054e2:	85be                	mv	a1,a5
    800054e4:	855a                	mv	a0,s6
    800054e6:	ffffc097          	auipc	ra,0xffffc
    800054ea:	f2a080e7          	jalr	-214(ra) # 80001410 <uvmalloc>
    800054ee:	8c2a                	mv	s8,a0
  ip = 0;
    800054f0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054f2:	12050e63          	beqz	a0,8000562e <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054f6:	75f9                	lui	a1,0xffffe
    800054f8:	95aa                	add	a1,a1,a0
    800054fa:	855a                	mv	a0,s6
    800054fc:	ffffc097          	auipc	ra,0xffffc
    80005500:	13a080e7          	jalr	314(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80005504:	7afd                	lui	s5,0xfffff
    80005506:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005508:	df043783          	ld	a5,-528(s0)
    8000550c:	6388                	ld	a0,0(a5)
    8000550e:	c925                	beqz	a0,8000557e <exec+0x226>
    80005510:	e9040993          	addi	s3,s0,-368
    80005514:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005518:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000551a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000551c:	ffffc097          	auipc	ra,0xffffc
    80005520:	932080e7          	jalr	-1742(ra) # 80000e4e <strlen>
    80005524:	0015079b          	addiw	a5,a0,1
    80005528:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000552c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005530:	13596663          	bltu	s2,s5,8000565c <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005534:	df043d83          	ld	s11,-528(s0)
    80005538:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000553c:	8552                	mv	a0,s4
    8000553e:	ffffc097          	auipc	ra,0xffffc
    80005542:	910080e7          	jalr	-1776(ra) # 80000e4e <strlen>
    80005546:	0015069b          	addiw	a3,a0,1
    8000554a:	8652                	mv	a2,s4
    8000554c:	85ca                	mv	a1,s2
    8000554e:	855a                	mv	a0,s6
    80005550:	ffffc097          	auipc	ra,0xffffc
    80005554:	118080e7          	jalr	280(ra) # 80001668 <copyout>
    80005558:	10054663          	bltz	a0,80005664 <exec+0x30c>
    ustack[argc] = sp;
    8000555c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005560:	0485                	addi	s1,s1,1
    80005562:	008d8793          	addi	a5,s11,8
    80005566:	def43823          	sd	a5,-528(s0)
    8000556a:	008db503          	ld	a0,8(s11)
    8000556e:	c911                	beqz	a0,80005582 <exec+0x22a>
    if(argc >= MAXARG)
    80005570:	09a1                	addi	s3,s3,8
    80005572:	fb3c95e3          	bne	s9,s3,8000551c <exec+0x1c4>
  sz = sz1;
    80005576:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000557a:	4a81                	li	s5,0
    8000557c:	a84d                	j	8000562e <exec+0x2d6>
  sp = sz;
    8000557e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005580:	4481                	li	s1,0
  ustack[argc] = 0;
    80005582:	00349793          	slli	a5,s1,0x3
    80005586:	f9040713          	addi	a4,s0,-112
    8000558a:	97ba                	add	a5,a5,a4
    8000558c:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd5ac8>
  sp -= (argc+1) * sizeof(uint64);
    80005590:	00148693          	addi	a3,s1,1
    80005594:	068e                	slli	a3,a3,0x3
    80005596:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000559a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000559e:	01597663          	bgeu	s2,s5,800055aa <exec+0x252>
  sz = sz1;
    800055a2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055a6:	4a81                	li	s5,0
    800055a8:	a059                	j	8000562e <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055aa:	e9040613          	addi	a2,s0,-368
    800055ae:	85ca                	mv	a1,s2
    800055b0:	855a                	mv	a0,s6
    800055b2:	ffffc097          	auipc	ra,0xffffc
    800055b6:	0b6080e7          	jalr	182(ra) # 80001668 <copyout>
    800055ba:	0a054963          	bltz	a0,8000566c <exec+0x314>
  p->trapframe->a1 = sp;
    800055be:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800055c2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055c6:	de843783          	ld	a5,-536(s0)
    800055ca:	0007c703          	lbu	a4,0(a5)
    800055ce:	cf11                	beqz	a4,800055ea <exec+0x292>
    800055d0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055d2:	02f00693          	li	a3,47
    800055d6:	a039                	j	800055e4 <exec+0x28c>
      last = s+1;
    800055d8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800055dc:	0785                	addi	a5,a5,1
    800055de:	fff7c703          	lbu	a4,-1(a5)
    800055e2:	c701                	beqz	a4,800055ea <exec+0x292>
    if(*s == '/')
    800055e4:	fed71ce3          	bne	a4,a3,800055dc <exec+0x284>
    800055e8:	bfc5                	j	800055d8 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800055ea:	4641                	li	a2,16
    800055ec:	de843583          	ld	a1,-536(s0)
    800055f0:	158b8513          	addi	a0,s7,344
    800055f4:	ffffc097          	auipc	ra,0xffffc
    800055f8:	828080e7          	jalr	-2008(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800055fc:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005600:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005604:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005608:	058bb783          	ld	a5,88(s7)
    8000560c:	e6843703          	ld	a4,-408(s0)
    80005610:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005612:	058bb783          	ld	a5,88(s7)
    80005616:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000561a:	85ea                	mv	a1,s10
    8000561c:	ffffc097          	auipc	ra,0xffffc
    80005620:	73a080e7          	jalr	1850(ra) # 80001d56 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005624:	0004851b          	sext.w	a0,s1
    80005628:	b3f1                	j	800053f4 <exec+0x9c>
    8000562a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000562e:	df843583          	ld	a1,-520(s0)
    80005632:	855a                	mv	a0,s6
    80005634:	ffffc097          	auipc	ra,0xffffc
    80005638:	722080e7          	jalr	1826(ra) # 80001d56 <proc_freepagetable>
  if(ip){
    8000563c:	da0a92e3          	bnez	s5,800053e0 <exec+0x88>
  return -1;
    80005640:	557d                	li	a0,-1
    80005642:	bb4d                	j	800053f4 <exec+0x9c>
    80005644:	df243c23          	sd	s2,-520(s0)
    80005648:	b7dd                	j	8000562e <exec+0x2d6>
    8000564a:	df243c23          	sd	s2,-520(s0)
    8000564e:	b7c5                	j	8000562e <exec+0x2d6>
    80005650:	df243c23          	sd	s2,-520(s0)
    80005654:	bfe9                	j	8000562e <exec+0x2d6>
    80005656:	df243c23          	sd	s2,-520(s0)
    8000565a:	bfd1                	j	8000562e <exec+0x2d6>
  sz = sz1;
    8000565c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005660:	4a81                	li	s5,0
    80005662:	b7f1                	j	8000562e <exec+0x2d6>
  sz = sz1;
    80005664:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005668:	4a81                	li	s5,0
    8000566a:	b7d1                	j	8000562e <exec+0x2d6>
  sz = sz1;
    8000566c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005670:	4a81                	li	s5,0
    80005672:	bf75                	j	8000562e <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005674:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005678:	e0843783          	ld	a5,-504(s0)
    8000567c:	0017869b          	addiw	a3,a5,1
    80005680:	e0d43423          	sd	a3,-504(s0)
    80005684:	e0043783          	ld	a5,-512(s0)
    80005688:	0387879b          	addiw	a5,a5,56
    8000568c:	e8845703          	lhu	a4,-376(s0)
    80005690:	e0e6dee3          	bge	a3,a4,800054ac <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005694:	2781                	sext.w	a5,a5
    80005696:	e0f43023          	sd	a5,-512(s0)
    8000569a:	03800713          	li	a4,56
    8000569e:	86be                	mv	a3,a5
    800056a0:	e1840613          	addi	a2,s0,-488
    800056a4:	4581                	li	a1,0
    800056a6:	8556                	mv	a0,s5
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	a5c080e7          	jalr	-1444(ra) # 80004104 <readi>
    800056b0:	03800793          	li	a5,56
    800056b4:	f6f51be3          	bne	a0,a5,8000562a <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800056b8:	e1842783          	lw	a5,-488(s0)
    800056bc:	4705                	li	a4,1
    800056be:	fae79de3          	bne	a5,a4,80005678 <exec+0x320>
    if(ph.memsz < ph.filesz)
    800056c2:	e4043483          	ld	s1,-448(s0)
    800056c6:	e3843783          	ld	a5,-456(s0)
    800056ca:	f6f4ede3          	bltu	s1,a5,80005644 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800056ce:	e2843783          	ld	a5,-472(s0)
    800056d2:	94be                	add	s1,s1,a5
    800056d4:	f6f4ebe3          	bltu	s1,a5,8000564a <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800056d8:	de043703          	ld	a4,-544(s0)
    800056dc:	8ff9                	and	a5,a5,a4
    800056de:	fbad                	bnez	a5,80005650 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800056e0:	e1c42503          	lw	a0,-484(s0)
    800056e4:	00000097          	auipc	ra,0x0
    800056e8:	c58080e7          	jalr	-936(ra) # 8000533c <flags2perm>
    800056ec:	86aa                	mv	a3,a0
    800056ee:	8626                	mv	a2,s1
    800056f0:	85ca                	mv	a1,s2
    800056f2:	855a                	mv	a0,s6
    800056f4:	ffffc097          	auipc	ra,0xffffc
    800056f8:	d1c080e7          	jalr	-740(ra) # 80001410 <uvmalloc>
    800056fc:	dea43c23          	sd	a0,-520(s0)
    80005700:	d939                	beqz	a0,80005656 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005702:	e2843c03          	ld	s8,-472(s0)
    80005706:	e2042c83          	lw	s9,-480(s0)
    8000570a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000570e:	f60b83e3          	beqz	s7,80005674 <exec+0x31c>
    80005712:	89de                	mv	s3,s7
    80005714:	4481                	li	s1,0
    80005716:	bb95                	j	8000548a <exec+0x132>

0000000080005718 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005718:	7179                	addi	sp,sp,-48
    8000571a:	f406                	sd	ra,40(sp)
    8000571c:	f022                	sd	s0,32(sp)
    8000571e:	ec26                	sd	s1,24(sp)
    80005720:	e84a                	sd	s2,16(sp)
    80005722:	1800                	addi	s0,sp,48
    80005724:	892e                	mv	s2,a1
    80005726:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005728:	fdc40593          	addi	a1,s0,-36
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	9b6080e7          	jalr	-1610(ra) # 800030e2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005734:	fdc42703          	lw	a4,-36(s0)
    80005738:	47bd                	li	a5,15
    8000573a:	02e7eb63          	bltu	a5,a4,80005770 <argfd+0x58>
    8000573e:	ffffc097          	auipc	ra,0xffffc
    80005742:	4b8080e7          	jalr	1208(ra) # 80001bf6 <myproc>
    80005746:	fdc42703          	lw	a4,-36(s0)
    8000574a:	01a70793          	addi	a5,a4,26
    8000574e:	078e                	slli	a5,a5,0x3
    80005750:	953e                	add	a0,a0,a5
    80005752:	611c                	ld	a5,0(a0)
    80005754:	c385                	beqz	a5,80005774 <argfd+0x5c>
    return -1;
  if(pfd)
    80005756:	00090463          	beqz	s2,8000575e <argfd+0x46>
    *pfd = fd;
    8000575a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000575e:	4501                	li	a0,0
  if(pf)
    80005760:	c091                	beqz	s1,80005764 <argfd+0x4c>
    *pf = f;
    80005762:	e09c                	sd	a5,0(s1)
}
    80005764:	70a2                	ld	ra,40(sp)
    80005766:	7402                	ld	s0,32(sp)
    80005768:	64e2                	ld	s1,24(sp)
    8000576a:	6942                	ld	s2,16(sp)
    8000576c:	6145                	addi	sp,sp,48
    8000576e:	8082                	ret
    return -1;
    80005770:	557d                	li	a0,-1
    80005772:	bfcd                	j	80005764 <argfd+0x4c>
    80005774:	557d                	li	a0,-1
    80005776:	b7fd                	j	80005764 <argfd+0x4c>

0000000080005778 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005778:	1101                	addi	sp,sp,-32
    8000577a:	ec06                	sd	ra,24(sp)
    8000577c:	e822                	sd	s0,16(sp)
    8000577e:	e426                	sd	s1,8(sp)
    80005780:	1000                	addi	s0,sp,32
    80005782:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005784:	ffffc097          	auipc	ra,0xffffc
    80005788:	472080e7          	jalr	1138(ra) # 80001bf6 <myproc>
    8000578c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000578e:	0d050793          	addi	a5,a0,208
    80005792:	4501                	li	a0,0
    80005794:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005796:	6398                	ld	a4,0(a5)
    80005798:	cb19                	beqz	a4,800057ae <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000579a:	2505                	addiw	a0,a0,1
    8000579c:	07a1                	addi	a5,a5,8
    8000579e:	fed51ce3          	bne	a0,a3,80005796 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800057a2:	557d                	li	a0,-1
}
    800057a4:	60e2                	ld	ra,24(sp)
    800057a6:	6442                	ld	s0,16(sp)
    800057a8:	64a2                	ld	s1,8(sp)
    800057aa:	6105                	addi	sp,sp,32
    800057ac:	8082                	ret
      p->ofile[fd] = f;
    800057ae:	01a50793          	addi	a5,a0,26
    800057b2:	078e                	slli	a5,a5,0x3
    800057b4:	963e                	add	a2,a2,a5
    800057b6:	e204                	sd	s1,0(a2)
      return fd;
    800057b8:	b7f5                	j	800057a4 <fdalloc+0x2c>

00000000800057ba <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800057ba:	715d                	addi	sp,sp,-80
    800057bc:	e486                	sd	ra,72(sp)
    800057be:	e0a2                	sd	s0,64(sp)
    800057c0:	fc26                	sd	s1,56(sp)
    800057c2:	f84a                	sd	s2,48(sp)
    800057c4:	f44e                	sd	s3,40(sp)
    800057c6:	f052                	sd	s4,32(sp)
    800057c8:	ec56                	sd	s5,24(sp)
    800057ca:	e85a                	sd	s6,16(sp)
    800057cc:	0880                	addi	s0,sp,80
    800057ce:	8b2e                	mv	s6,a1
    800057d0:	89b2                	mv	s3,a2
    800057d2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800057d4:	fb040593          	addi	a1,s0,-80
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	e3c080e7          	jalr	-452(ra) # 80004614 <nameiparent>
    800057e0:	84aa                	mv	s1,a0
    800057e2:	14050f63          	beqz	a0,80005940 <create+0x186>
    return 0;

  ilock(dp);
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	66a080e7          	jalr	1642(ra) # 80003e50 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057ee:	4601                	li	a2,0
    800057f0:	fb040593          	addi	a1,s0,-80
    800057f4:	8526                	mv	a0,s1
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	b3e080e7          	jalr	-1218(ra) # 80004334 <dirlookup>
    800057fe:	8aaa                	mv	s5,a0
    80005800:	c931                	beqz	a0,80005854 <create+0x9a>
    iunlockput(dp);
    80005802:	8526                	mv	a0,s1
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	8ae080e7          	jalr	-1874(ra) # 800040b2 <iunlockput>
    ilock(ip);
    8000580c:	8556                	mv	a0,s5
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	642080e7          	jalr	1602(ra) # 80003e50 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005816:	000b059b          	sext.w	a1,s6
    8000581a:	4789                	li	a5,2
    8000581c:	02f59563          	bne	a1,a5,80005846 <create+0x8c>
    80005820:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd5c0c>
    80005824:	37f9                	addiw	a5,a5,-2
    80005826:	17c2                	slli	a5,a5,0x30
    80005828:	93c1                	srli	a5,a5,0x30
    8000582a:	4705                	li	a4,1
    8000582c:	00f76d63          	bltu	a4,a5,80005846 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005830:	8556                	mv	a0,s5
    80005832:	60a6                	ld	ra,72(sp)
    80005834:	6406                	ld	s0,64(sp)
    80005836:	74e2                	ld	s1,56(sp)
    80005838:	7942                	ld	s2,48(sp)
    8000583a:	79a2                	ld	s3,40(sp)
    8000583c:	7a02                	ld	s4,32(sp)
    8000583e:	6ae2                	ld	s5,24(sp)
    80005840:	6b42                	ld	s6,16(sp)
    80005842:	6161                	addi	sp,sp,80
    80005844:	8082                	ret
    iunlockput(ip);
    80005846:	8556                	mv	a0,s5
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	86a080e7          	jalr	-1942(ra) # 800040b2 <iunlockput>
    return 0;
    80005850:	4a81                	li	s5,0
    80005852:	bff9                	j	80005830 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005854:	85da                	mv	a1,s6
    80005856:	4088                	lw	a0,0(s1)
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	45c080e7          	jalr	1116(ra) # 80003cb4 <ialloc>
    80005860:	8a2a                	mv	s4,a0
    80005862:	c539                	beqz	a0,800058b0 <create+0xf6>
  ilock(ip);
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	5ec080e7          	jalr	1516(ra) # 80003e50 <ilock>
  ip->major = major;
    8000586c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005870:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005874:	4905                	li	s2,1
    80005876:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000587a:	8552                	mv	a0,s4
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	50a080e7          	jalr	1290(ra) # 80003d86 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005884:	000b059b          	sext.w	a1,s6
    80005888:	03258b63          	beq	a1,s2,800058be <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000588c:	004a2603          	lw	a2,4(s4)
    80005890:	fb040593          	addi	a1,s0,-80
    80005894:	8526                	mv	a0,s1
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	cae080e7          	jalr	-850(ra) # 80004544 <dirlink>
    8000589e:	06054f63          	bltz	a0,8000591c <create+0x162>
  iunlockput(dp);
    800058a2:	8526                	mv	a0,s1
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	80e080e7          	jalr	-2034(ra) # 800040b2 <iunlockput>
  return ip;
    800058ac:	8ad2                	mv	s5,s4
    800058ae:	b749                	j	80005830 <create+0x76>
    iunlockput(dp);
    800058b0:	8526                	mv	a0,s1
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	800080e7          	jalr	-2048(ra) # 800040b2 <iunlockput>
    return 0;
    800058ba:	8ad2                	mv	s5,s4
    800058bc:	bf95                	j	80005830 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800058be:	004a2603          	lw	a2,4(s4)
    800058c2:	00003597          	auipc	a1,0x3
    800058c6:	ebe58593          	addi	a1,a1,-322 # 80008780 <syscalls+0x2c8>
    800058ca:	8552                	mv	a0,s4
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	c78080e7          	jalr	-904(ra) # 80004544 <dirlink>
    800058d4:	04054463          	bltz	a0,8000591c <create+0x162>
    800058d8:	40d0                	lw	a2,4(s1)
    800058da:	00003597          	auipc	a1,0x3
    800058de:	eae58593          	addi	a1,a1,-338 # 80008788 <syscalls+0x2d0>
    800058e2:	8552                	mv	a0,s4
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	c60080e7          	jalr	-928(ra) # 80004544 <dirlink>
    800058ec:	02054863          	bltz	a0,8000591c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800058f0:	004a2603          	lw	a2,4(s4)
    800058f4:	fb040593          	addi	a1,s0,-80
    800058f8:	8526                	mv	a0,s1
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	c4a080e7          	jalr	-950(ra) # 80004544 <dirlink>
    80005902:	00054d63          	bltz	a0,8000591c <create+0x162>
    dp->nlink++;  // for ".."
    80005906:	04a4d783          	lhu	a5,74(s1)
    8000590a:	2785                	addiw	a5,a5,1
    8000590c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	474080e7          	jalr	1140(ra) # 80003d86 <iupdate>
    8000591a:	b761                	j	800058a2 <create+0xe8>
  ip->nlink = 0;
    8000591c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005920:	8552                	mv	a0,s4
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	464080e7          	jalr	1124(ra) # 80003d86 <iupdate>
  iunlockput(ip);
    8000592a:	8552                	mv	a0,s4
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	786080e7          	jalr	1926(ra) # 800040b2 <iunlockput>
  iunlockput(dp);
    80005934:	8526                	mv	a0,s1
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	77c080e7          	jalr	1916(ra) # 800040b2 <iunlockput>
  return 0;
    8000593e:	bdcd                	j	80005830 <create+0x76>
    return 0;
    80005940:	8aaa                	mv	s5,a0
    80005942:	b5fd                	j	80005830 <create+0x76>

0000000080005944 <sys_dup>:
{
    80005944:	7179                	addi	sp,sp,-48
    80005946:	f406                	sd	ra,40(sp)
    80005948:	f022                	sd	s0,32(sp)
    8000594a:	ec26                	sd	s1,24(sp)
    8000594c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000594e:	fd840613          	addi	a2,s0,-40
    80005952:	4581                	li	a1,0
    80005954:	4501                	li	a0,0
    80005956:	00000097          	auipc	ra,0x0
    8000595a:	dc2080e7          	jalr	-574(ra) # 80005718 <argfd>
    return -1;
    8000595e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005960:	02054363          	bltz	a0,80005986 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005964:	fd843503          	ld	a0,-40(s0)
    80005968:	00000097          	auipc	ra,0x0
    8000596c:	e10080e7          	jalr	-496(ra) # 80005778 <fdalloc>
    80005970:	84aa                	mv	s1,a0
    return -1;
    80005972:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005974:	00054963          	bltz	a0,80005986 <sys_dup+0x42>
  filedup(f);
    80005978:	fd843503          	ld	a0,-40(s0)
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	310080e7          	jalr	784(ra) # 80004c8c <filedup>
  return fd;
    80005984:	87a6                	mv	a5,s1
}
    80005986:	853e                	mv	a0,a5
    80005988:	70a2                	ld	ra,40(sp)
    8000598a:	7402                	ld	s0,32(sp)
    8000598c:	64e2                	ld	s1,24(sp)
    8000598e:	6145                	addi	sp,sp,48
    80005990:	8082                	ret

0000000080005992 <sys_read>:
{
    80005992:	7179                	addi	sp,sp,-48
    80005994:	f406                	sd	ra,40(sp)
    80005996:	f022                	sd	s0,32(sp)
    80005998:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000599a:	fd840593          	addi	a1,s0,-40
    8000599e:	4505                	li	a0,1
    800059a0:	ffffd097          	auipc	ra,0xffffd
    800059a4:	762080e7          	jalr	1890(ra) # 80003102 <argaddr>
  argint(2, &n);
    800059a8:	fe440593          	addi	a1,s0,-28
    800059ac:	4509                	li	a0,2
    800059ae:	ffffd097          	auipc	ra,0xffffd
    800059b2:	734080e7          	jalr	1844(ra) # 800030e2 <argint>
  if(argfd(0, 0, &f) < 0)
    800059b6:	fe840613          	addi	a2,s0,-24
    800059ba:	4581                	li	a1,0
    800059bc:	4501                	li	a0,0
    800059be:	00000097          	auipc	ra,0x0
    800059c2:	d5a080e7          	jalr	-678(ra) # 80005718 <argfd>
    800059c6:	87aa                	mv	a5,a0
    return -1;
    800059c8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059ca:	0007cc63          	bltz	a5,800059e2 <sys_read+0x50>
  return fileread(f, p, n);
    800059ce:	fe442603          	lw	a2,-28(s0)
    800059d2:	fd843583          	ld	a1,-40(s0)
    800059d6:	fe843503          	ld	a0,-24(s0)
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	43e080e7          	jalr	1086(ra) # 80004e18 <fileread>
}
    800059e2:	70a2                	ld	ra,40(sp)
    800059e4:	7402                	ld	s0,32(sp)
    800059e6:	6145                	addi	sp,sp,48
    800059e8:	8082                	ret

00000000800059ea <sys_write>:
{
    800059ea:	7179                	addi	sp,sp,-48
    800059ec:	f406                	sd	ra,40(sp)
    800059ee:	f022                	sd	s0,32(sp)
    800059f0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800059f2:	fd840593          	addi	a1,s0,-40
    800059f6:	4505                	li	a0,1
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	70a080e7          	jalr	1802(ra) # 80003102 <argaddr>
  argint(2, &n);
    80005a00:	fe440593          	addi	a1,s0,-28
    80005a04:	4509                	li	a0,2
    80005a06:	ffffd097          	auipc	ra,0xffffd
    80005a0a:	6dc080e7          	jalr	1756(ra) # 800030e2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005a0e:	fe840613          	addi	a2,s0,-24
    80005a12:	4581                	li	a1,0
    80005a14:	4501                	li	a0,0
    80005a16:	00000097          	auipc	ra,0x0
    80005a1a:	d02080e7          	jalr	-766(ra) # 80005718 <argfd>
    80005a1e:	87aa                	mv	a5,a0
    return -1;
    80005a20:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a22:	0007cc63          	bltz	a5,80005a3a <sys_write+0x50>
  return filewrite(f, p, n);
    80005a26:	fe442603          	lw	a2,-28(s0)
    80005a2a:	fd843583          	ld	a1,-40(s0)
    80005a2e:	fe843503          	ld	a0,-24(s0)
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	4a8080e7          	jalr	1192(ra) # 80004eda <filewrite>
}
    80005a3a:	70a2                	ld	ra,40(sp)
    80005a3c:	7402                	ld	s0,32(sp)
    80005a3e:	6145                	addi	sp,sp,48
    80005a40:	8082                	ret

0000000080005a42 <sys_close>:
{
    80005a42:	1101                	addi	sp,sp,-32
    80005a44:	ec06                	sd	ra,24(sp)
    80005a46:	e822                	sd	s0,16(sp)
    80005a48:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a4a:	fe040613          	addi	a2,s0,-32
    80005a4e:	fec40593          	addi	a1,s0,-20
    80005a52:	4501                	li	a0,0
    80005a54:	00000097          	auipc	ra,0x0
    80005a58:	cc4080e7          	jalr	-828(ra) # 80005718 <argfd>
    return -1;
    80005a5c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a5e:	02054463          	bltz	a0,80005a86 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a62:	ffffc097          	auipc	ra,0xffffc
    80005a66:	194080e7          	jalr	404(ra) # 80001bf6 <myproc>
    80005a6a:	fec42783          	lw	a5,-20(s0)
    80005a6e:	07e9                	addi	a5,a5,26
    80005a70:	078e                	slli	a5,a5,0x3
    80005a72:	97aa                	add	a5,a5,a0
    80005a74:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a78:	fe043503          	ld	a0,-32(s0)
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	262080e7          	jalr	610(ra) # 80004cde <fileclose>
  return 0;
    80005a84:	4781                	li	a5,0
}
    80005a86:	853e                	mv	a0,a5
    80005a88:	60e2                	ld	ra,24(sp)
    80005a8a:	6442                	ld	s0,16(sp)
    80005a8c:	6105                	addi	sp,sp,32
    80005a8e:	8082                	ret

0000000080005a90 <sys_fstat>:
{
    80005a90:	1101                	addi	sp,sp,-32
    80005a92:	ec06                	sd	ra,24(sp)
    80005a94:	e822                	sd	s0,16(sp)
    80005a96:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005a98:	fe040593          	addi	a1,s0,-32
    80005a9c:	4505                	li	a0,1
    80005a9e:	ffffd097          	auipc	ra,0xffffd
    80005aa2:	664080e7          	jalr	1636(ra) # 80003102 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005aa6:	fe840613          	addi	a2,s0,-24
    80005aaa:	4581                	li	a1,0
    80005aac:	4501                	li	a0,0
    80005aae:	00000097          	auipc	ra,0x0
    80005ab2:	c6a080e7          	jalr	-918(ra) # 80005718 <argfd>
    80005ab6:	87aa                	mv	a5,a0
    return -1;
    80005ab8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005aba:	0007ca63          	bltz	a5,80005ace <sys_fstat+0x3e>
  return filestat(f, st);
    80005abe:	fe043583          	ld	a1,-32(s0)
    80005ac2:	fe843503          	ld	a0,-24(s0)
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	2e0080e7          	jalr	736(ra) # 80004da6 <filestat>
}
    80005ace:	60e2                	ld	ra,24(sp)
    80005ad0:	6442                	ld	s0,16(sp)
    80005ad2:	6105                	addi	sp,sp,32
    80005ad4:	8082                	ret

0000000080005ad6 <sys_link>:
{
    80005ad6:	7169                	addi	sp,sp,-304
    80005ad8:	f606                	sd	ra,296(sp)
    80005ada:	f222                	sd	s0,288(sp)
    80005adc:	ee26                	sd	s1,280(sp)
    80005ade:	ea4a                	sd	s2,272(sp)
    80005ae0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ae2:	08000613          	li	a2,128
    80005ae6:	ed040593          	addi	a1,s0,-304
    80005aea:	4501                	li	a0,0
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	636080e7          	jalr	1590(ra) # 80003122 <argstr>
    return -1;
    80005af4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005af6:	10054e63          	bltz	a0,80005c12 <sys_link+0x13c>
    80005afa:	08000613          	li	a2,128
    80005afe:	f5040593          	addi	a1,s0,-176
    80005b02:	4505                	li	a0,1
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	61e080e7          	jalr	1566(ra) # 80003122 <argstr>
    return -1;
    80005b0c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b0e:	10054263          	bltz	a0,80005c12 <sys_link+0x13c>
  begin_op();
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	d00080e7          	jalr	-768(ra) # 80004812 <begin_op>
  if((ip = namei(old)) == 0){
    80005b1a:	ed040513          	addi	a0,s0,-304
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	ad8080e7          	jalr	-1320(ra) # 800045f6 <namei>
    80005b26:	84aa                	mv	s1,a0
    80005b28:	c551                	beqz	a0,80005bb4 <sys_link+0xde>
  ilock(ip);
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	326080e7          	jalr	806(ra) # 80003e50 <ilock>
  if(ip->type == T_DIR){
    80005b32:	04449703          	lh	a4,68(s1)
    80005b36:	4785                	li	a5,1
    80005b38:	08f70463          	beq	a4,a5,80005bc0 <sys_link+0xea>
  ip->nlink++;
    80005b3c:	04a4d783          	lhu	a5,74(s1)
    80005b40:	2785                	addiw	a5,a5,1
    80005b42:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	23e080e7          	jalr	574(ra) # 80003d86 <iupdate>
  iunlock(ip);
    80005b50:	8526                	mv	a0,s1
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	3c0080e7          	jalr	960(ra) # 80003f12 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b5a:	fd040593          	addi	a1,s0,-48
    80005b5e:	f5040513          	addi	a0,s0,-176
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	ab2080e7          	jalr	-1358(ra) # 80004614 <nameiparent>
    80005b6a:	892a                	mv	s2,a0
    80005b6c:	c935                	beqz	a0,80005be0 <sys_link+0x10a>
  ilock(dp);
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	2e2080e7          	jalr	738(ra) # 80003e50 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b76:	00092703          	lw	a4,0(s2)
    80005b7a:	409c                	lw	a5,0(s1)
    80005b7c:	04f71d63          	bne	a4,a5,80005bd6 <sys_link+0x100>
    80005b80:	40d0                	lw	a2,4(s1)
    80005b82:	fd040593          	addi	a1,s0,-48
    80005b86:	854a                	mv	a0,s2
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	9bc080e7          	jalr	-1604(ra) # 80004544 <dirlink>
    80005b90:	04054363          	bltz	a0,80005bd6 <sys_link+0x100>
  iunlockput(dp);
    80005b94:	854a                	mv	a0,s2
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	51c080e7          	jalr	1308(ra) # 800040b2 <iunlockput>
  iput(ip);
    80005b9e:	8526                	mv	a0,s1
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	46a080e7          	jalr	1130(ra) # 8000400a <iput>
  end_op();
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	cea080e7          	jalr	-790(ra) # 80004892 <end_op>
  return 0;
    80005bb0:	4781                	li	a5,0
    80005bb2:	a085                	j	80005c12 <sys_link+0x13c>
    end_op();
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	cde080e7          	jalr	-802(ra) # 80004892 <end_op>
    return -1;
    80005bbc:	57fd                	li	a5,-1
    80005bbe:	a891                	j	80005c12 <sys_link+0x13c>
    iunlockput(ip);
    80005bc0:	8526                	mv	a0,s1
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	4f0080e7          	jalr	1264(ra) # 800040b2 <iunlockput>
    end_op();
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	cc8080e7          	jalr	-824(ra) # 80004892 <end_op>
    return -1;
    80005bd2:	57fd                	li	a5,-1
    80005bd4:	a83d                	j	80005c12 <sys_link+0x13c>
    iunlockput(dp);
    80005bd6:	854a                	mv	a0,s2
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	4da080e7          	jalr	1242(ra) # 800040b2 <iunlockput>
  ilock(ip);
    80005be0:	8526                	mv	a0,s1
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	26e080e7          	jalr	622(ra) # 80003e50 <ilock>
  ip->nlink--;
    80005bea:	04a4d783          	lhu	a5,74(s1)
    80005bee:	37fd                	addiw	a5,a5,-1
    80005bf0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bf4:	8526                	mv	a0,s1
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	190080e7          	jalr	400(ra) # 80003d86 <iupdate>
  iunlockput(ip);
    80005bfe:	8526                	mv	a0,s1
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	4b2080e7          	jalr	1202(ra) # 800040b2 <iunlockput>
  end_op();
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	c8a080e7          	jalr	-886(ra) # 80004892 <end_op>
  return -1;
    80005c10:	57fd                	li	a5,-1
}
    80005c12:	853e                	mv	a0,a5
    80005c14:	70b2                	ld	ra,296(sp)
    80005c16:	7412                	ld	s0,288(sp)
    80005c18:	64f2                	ld	s1,280(sp)
    80005c1a:	6952                	ld	s2,272(sp)
    80005c1c:	6155                	addi	sp,sp,304
    80005c1e:	8082                	ret

0000000080005c20 <sys_unlink>:
{
    80005c20:	7151                	addi	sp,sp,-240
    80005c22:	f586                	sd	ra,232(sp)
    80005c24:	f1a2                	sd	s0,224(sp)
    80005c26:	eda6                	sd	s1,216(sp)
    80005c28:	e9ca                	sd	s2,208(sp)
    80005c2a:	e5ce                	sd	s3,200(sp)
    80005c2c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c2e:	08000613          	li	a2,128
    80005c32:	f3040593          	addi	a1,s0,-208
    80005c36:	4501                	li	a0,0
    80005c38:	ffffd097          	auipc	ra,0xffffd
    80005c3c:	4ea080e7          	jalr	1258(ra) # 80003122 <argstr>
    80005c40:	18054163          	bltz	a0,80005dc2 <sys_unlink+0x1a2>
  begin_op();
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	bce080e7          	jalr	-1074(ra) # 80004812 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c4c:	fb040593          	addi	a1,s0,-80
    80005c50:	f3040513          	addi	a0,s0,-208
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	9c0080e7          	jalr	-1600(ra) # 80004614 <nameiparent>
    80005c5c:	84aa                	mv	s1,a0
    80005c5e:	c979                	beqz	a0,80005d34 <sys_unlink+0x114>
  ilock(dp);
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	1f0080e7          	jalr	496(ra) # 80003e50 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c68:	00003597          	auipc	a1,0x3
    80005c6c:	b1858593          	addi	a1,a1,-1256 # 80008780 <syscalls+0x2c8>
    80005c70:	fb040513          	addi	a0,s0,-80
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	6a6080e7          	jalr	1702(ra) # 8000431a <namecmp>
    80005c7c:	14050a63          	beqz	a0,80005dd0 <sys_unlink+0x1b0>
    80005c80:	00003597          	auipc	a1,0x3
    80005c84:	b0858593          	addi	a1,a1,-1272 # 80008788 <syscalls+0x2d0>
    80005c88:	fb040513          	addi	a0,s0,-80
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	68e080e7          	jalr	1678(ra) # 8000431a <namecmp>
    80005c94:	12050e63          	beqz	a0,80005dd0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c98:	f2c40613          	addi	a2,s0,-212
    80005c9c:	fb040593          	addi	a1,s0,-80
    80005ca0:	8526                	mv	a0,s1
    80005ca2:	ffffe097          	auipc	ra,0xffffe
    80005ca6:	692080e7          	jalr	1682(ra) # 80004334 <dirlookup>
    80005caa:	892a                	mv	s2,a0
    80005cac:	12050263          	beqz	a0,80005dd0 <sys_unlink+0x1b0>
  ilock(ip);
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	1a0080e7          	jalr	416(ra) # 80003e50 <ilock>
  if(ip->nlink < 1)
    80005cb8:	04a91783          	lh	a5,74(s2)
    80005cbc:	08f05263          	blez	a5,80005d40 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005cc0:	04491703          	lh	a4,68(s2)
    80005cc4:	4785                	li	a5,1
    80005cc6:	08f70563          	beq	a4,a5,80005d50 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005cca:	4641                	li	a2,16
    80005ccc:	4581                	li	a1,0
    80005cce:	fc040513          	addi	a0,s0,-64
    80005cd2:	ffffb097          	auipc	ra,0xffffb
    80005cd6:	000080e7          	jalr	ra # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cda:	4741                	li	a4,16
    80005cdc:	f2c42683          	lw	a3,-212(s0)
    80005ce0:	fc040613          	addi	a2,s0,-64
    80005ce4:	4581                	li	a1,0
    80005ce6:	8526                	mv	a0,s1
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	514080e7          	jalr	1300(ra) # 800041fc <writei>
    80005cf0:	47c1                	li	a5,16
    80005cf2:	0af51563          	bne	a0,a5,80005d9c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005cf6:	04491703          	lh	a4,68(s2)
    80005cfa:	4785                	li	a5,1
    80005cfc:	0af70863          	beq	a4,a5,80005dac <sys_unlink+0x18c>
  iunlockput(dp);
    80005d00:	8526                	mv	a0,s1
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	3b0080e7          	jalr	944(ra) # 800040b2 <iunlockput>
  ip->nlink--;
    80005d0a:	04a95783          	lhu	a5,74(s2)
    80005d0e:	37fd                	addiw	a5,a5,-1
    80005d10:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d14:	854a                	mv	a0,s2
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	070080e7          	jalr	112(ra) # 80003d86 <iupdate>
  iunlockput(ip);
    80005d1e:	854a                	mv	a0,s2
    80005d20:	ffffe097          	auipc	ra,0xffffe
    80005d24:	392080e7          	jalr	914(ra) # 800040b2 <iunlockput>
  end_op();
    80005d28:	fffff097          	auipc	ra,0xfffff
    80005d2c:	b6a080e7          	jalr	-1174(ra) # 80004892 <end_op>
  return 0;
    80005d30:	4501                	li	a0,0
    80005d32:	a84d                	j	80005de4 <sys_unlink+0x1c4>
    end_op();
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	b5e080e7          	jalr	-1186(ra) # 80004892 <end_op>
    return -1;
    80005d3c:	557d                	li	a0,-1
    80005d3e:	a05d                	j	80005de4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d40:	00003517          	auipc	a0,0x3
    80005d44:	a5050513          	addi	a0,a0,-1456 # 80008790 <syscalls+0x2d8>
    80005d48:	ffffa097          	auipc	ra,0xffffa
    80005d4c:	7f6080e7          	jalr	2038(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d50:	04c92703          	lw	a4,76(s2)
    80005d54:	02000793          	li	a5,32
    80005d58:	f6e7f9e3          	bgeu	a5,a4,80005cca <sys_unlink+0xaa>
    80005d5c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d60:	4741                	li	a4,16
    80005d62:	86ce                	mv	a3,s3
    80005d64:	f1840613          	addi	a2,s0,-232
    80005d68:	4581                	li	a1,0
    80005d6a:	854a                	mv	a0,s2
    80005d6c:	ffffe097          	auipc	ra,0xffffe
    80005d70:	398080e7          	jalr	920(ra) # 80004104 <readi>
    80005d74:	47c1                	li	a5,16
    80005d76:	00f51b63          	bne	a0,a5,80005d8c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d7a:	f1845783          	lhu	a5,-232(s0)
    80005d7e:	e7a1                	bnez	a5,80005dc6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d80:	29c1                	addiw	s3,s3,16
    80005d82:	04c92783          	lw	a5,76(s2)
    80005d86:	fcf9ede3          	bltu	s3,a5,80005d60 <sys_unlink+0x140>
    80005d8a:	b781                	j	80005cca <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d8c:	00003517          	auipc	a0,0x3
    80005d90:	a1c50513          	addi	a0,a0,-1508 # 800087a8 <syscalls+0x2f0>
    80005d94:	ffffa097          	auipc	ra,0xffffa
    80005d98:	7aa080e7          	jalr	1962(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d9c:	00003517          	auipc	a0,0x3
    80005da0:	a2450513          	addi	a0,a0,-1500 # 800087c0 <syscalls+0x308>
    80005da4:	ffffa097          	auipc	ra,0xffffa
    80005da8:	79a080e7          	jalr	1946(ra) # 8000053e <panic>
    dp->nlink--;
    80005dac:	04a4d783          	lhu	a5,74(s1)
    80005db0:	37fd                	addiw	a5,a5,-1
    80005db2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005db6:	8526                	mv	a0,s1
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	fce080e7          	jalr	-50(ra) # 80003d86 <iupdate>
    80005dc0:	b781                	j	80005d00 <sys_unlink+0xe0>
    return -1;
    80005dc2:	557d                	li	a0,-1
    80005dc4:	a005                	j	80005de4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005dc6:	854a                	mv	a0,s2
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	2ea080e7          	jalr	746(ra) # 800040b2 <iunlockput>
  iunlockput(dp);
    80005dd0:	8526                	mv	a0,s1
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	2e0080e7          	jalr	736(ra) # 800040b2 <iunlockput>
  end_op();
    80005dda:	fffff097          	auipc	ra,0xfffff
    80005dde:	ab8080e7          	jalr	-1352(ra) # 80004892 <end_op>
  return -1;
    80005de2:	557d                	li	a0,-1
}
    80005de4:	70ae                	ld	ra,232(sp)
    80005de6:	740e                	ld	s0,224(sp)
    80005de8:	64ee                	ld	s1,216(sp)
    80005dea:	694e                	ld	s2,208(sp)
    80005dec:	69ae                	ld	s3,200(sp)
    80005dee:	616d                	addi	sp,sp,240
    80005df0:	8082                	ret

0000000080005df2 <sys_open>:

uint64
sys_open(void)
{
    80005df2:	7131                	addi	sp,sp,-192
    80005df4:	fd06                	sd	ra,184(sp)
    80005df6:	f922                	sd	s0,176(sp)
    80005df8:	f526                	sd	s1,168(sp)
    80005dfa:	f14a                	sd	s2,160(sp)
    80005dfc:	ed4e                	sd	s3,152(sp)
    80005dfe:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005e00:	f4c40593          	addi	a1,s0,-180
    80005e04:	4505                	li	a0,1
    80005e06:	ffffd097          	auipc	ra,0xffffd
    80005e0a:	2dc080e7          	jalr	732(ra) # 800030e2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e0e:	08000613          	li	a2,128
    80005e12:	f5040593          	addi	a1,s0,-176
    80005e16:	4501                	li	a0,0
    80005e18:	ffffd097          	auipc	ra,0xffffd
    80005e1c:	30a080e7          	jalr	778(ra) # 80003122 <argstr>
    80005e20:	87aa                	mv	a5,a0
    return -1;
    80005e22:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e24:	0a07c963          	bltz	a5,80005ed6 <sys_open+0xe4>

  begin_op();
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	9ea080e7          	jalr	-1558(ra) # 80004812 <begin_op>

  if(omode & O_CREATE){
    80005e30:	f4c42783          	lw	a5,-180(s0)
    80005e34:	2007f793          	andi	a5,a5,512
    80005e38:	cfc5                	beqz	a5,80005ef0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e3a:	4681                	li	a3,0
    80005e3c:	4601                	li	a2,0
    80005e3e:	4589                	li	a1,2
    80005e40:	f5040513          	addi	a0,s0,-176
    80005e44:	00000097          	auipc	ra,0x0
    80005e48:	976080e7          	jalr	-1674(ra) # 800057ba <create>
    80005e4c:	84aa                	mv	s1,a0
    if(ip == 0){
    80005e4e:	c959                	beqz	a0,80005ee4 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e50:	04449703          	lh	a4,68(s1)
    80005e54:	478d                	li	a5,3
    80005e56:	00f71763          	bne	a4,a5,80005e64 <sys_open+0x72>
    80005e5a:	0464d703          	lhu	a4,70(s1)
    80005e5e:	47a5                	li	a5,9
    80005e60:	0ce7ed63          	bltu	a5,a4,80005f3a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	dbe080e7          	jalr	-578(ra) # 80004c22 <filealloc>
    80005e6c:	89aa                	mv	s3,a0
    80005e6e:	10050363          	beqz	a0,80005f74 <sys_open+0x182>
    80005e72:	00000097          	auipc	ra,0x0
    80005e76:	906080e7          	jalr	-1786(ra) # 80005778 <fdalloc>
    80005e7a:	892a                	mv	s2,a0
    80005e7c:	0e054763          	bltz	a0,80005f6a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e80:	04449703          	lh	a4,68(s1)
    80005e84:	478d                	li	a5,3
    80005e86:	0cf70563          	beq	a4,a5,80005f50 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e8a:	4789                	li	a5,2
    80005e8c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e90:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e94:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e98:	f4c42783          	lw	a5,-180(s0)
    80005e9c:	0017c713          	xori	a4,a5,1
    80005ea0:	8b05                	andi	a4,a4,1
    80005ea2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ea6:	0037f713          	andi	a4,a5,3
    80005eaa:	00e03733          	snez	a4,a4
    80005eae:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005eb2:	4007f793          	andi	a5,a5,1024
    80005eb6:	c791                	beqz	a5,80005ec2 <sys_open+0xd0>
    80005eb8:	04449703          	lh	a4,68(s1)
    80005ebc:	4789                	li	a5,2
    80005ebe:	0af70063          	beq	a4,a5,80005f5e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ec2:	8526                	mv	a0,s1
    80005ec4:	ffffe097          	auipc	ra,0xffffe
    80005ec8:	04e080e7          	jalr	78(ra) # 80003f12 <iunlock>
  end_op();
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	9c6080e7          	jalr	-1594(ra) # 80004892 <end_op>

  return fd;
    80005ed4:	854a                	mv	a0,s2
}
    80005ed6:	70ea                	ld	ra,184(sp)
    80005ed8:	744a                	ld	s0,176(sp)
    80005eda:	74aa                	ld	s1,168(sp)
    80005edc:	790a                	ld	s2,160(sp)
    80005ede:	69ea                	ld	s3,152(sp)
    80005ee0:	6129                	addi	sp,sp,192
    80005ee2:	8082                	ret
      end_op();
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	9ae080e7          	jalr	-1618(ra) # 80004892 <end_op>
      return -1;
    80005eec:	557d                	li	a0,-1
    80005eee:	b7e5                	j	80005ed6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ef0:	f5040513          	addi	a0,s0,-176
    80005ef4:	ffffe097          	auipc	ra,0xffffe
    80005ef8:	702080e7          	jalr	1794(ra) # 800045f6 <namei>
    80005efc:	84aa                	mv	s1,a0
    80005efe:	c905                	beqz	a0,80005f2e <sys_open+0x13c>
    ilock(ip);
    80005f00:	ffffe097          	auipc	ra,0xffffe
    80005f04:	f50080e7          	jalr	-176(ra) # 80003e50 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f08:	04449703          	lh	a4,68(s1)
    80005f0c:	4785                	li	a5,1
    80005f0e:	f4f711e3          	bne	a4,a5,80005e50 <sys_open+0x5e>
    80005f12:	f4c42783          	lw	a5,-180(s0)
    80005f16:	d7b9                	beqz	a5,80005e64 <sys_open+0x72>
      iunlockput(ip);
    80005f18:	8526                	mv	a0,s1
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	198080e7          	jalr	408(ra) # 800040b2 <iunlockput>
      end_op();
    80005f22:	fffff097          	auipc	ra,0xfffff
    80005f26:	970080e7          	jalr	-1680(ra) # 80004892 <end_op>
      return -1;
    80005f2a:	557d                	li	a0,-1
    80005f2c:	b76d                	j	80005ed6 <sys_open+0xe4>
      end_op();
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	964080e7          	jalr	-1692(ra) # 80004892 <end_op>
      return -1;
    80005f36:	557d                	li	a0,-1
    80005f38:	bf79                	j	80005ed6 <sys_open+0xe4>
    iunlockput(ip);
    80005f3a:	8526                	mv	a0,s1
    80005f3c:	ffffe097          	auipc	ra,0xffffe
    80005f40:	176080e7          	jalr	374(ra) # 800040b2 <iunlockput>
    end_op();
    80005f44:	fffff097          	auipc	ra,0xfffff
    80005f48:	94e080e7          	jalr	-1714(ra) # 80004892 <end_op>
    return -1;
    80005f4c:	557d                	li	a0,-1
    80005f4e:	b761                	j	80005ed6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f50:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f54:	04649783          	lh	a5,70(s1)
    80005f58:	02f99223          	sh	a5,36(s3)
    80005f5c:	bf25                	j	80005e94 <sys_open+0xa2>
    itrunc(ip);
    80005f5e:	8526                	mv	a0,s1
    80005f60:	ffffe097          	auipc	ra,0xffffe
    80005f64:	ffe080e7          	jalr	-2(ra) # 80003f5e <itrunc>
    80005f68:	bfa9                	j	80005ec2 <sys_open+0xd0>
      fileclose(f);
    80005f6a:	854e                	mv	a0,s3
    80005f6c:	fffff097          	auipc	ra,0xfffff
    80005f70:	d72080e7          	jalr	-654(ra) # 80004cde <fileclose>
    iunlockput(ip);
    80005f74:	8526                	mv	a0,s1
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	13c080e7          	jalr	316(ra) # 800040b2 <iunlockput>
    end_op();
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	914080e7          	jalr	-1772(ra) # 80004892 <end_op>
    return -1;
    80005f86:	557d                	li	a0,-1
    80005f88:	b7b9                	j	80005ed6 <sys_open+0xe4>

0000000080005f8a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f8a:	7175                	addi	sp,sp,-144
    80005f8c:	e506                	sd	ra,136(sp)
    80005f8e:	e122                	sd	s0,128(sp)
    80005f90:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f92:	fffff097          	auipc	ra,0xfffff
    80005f96:	880080e7          	jalr	-1920(ra) # 80004812 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f9a:	08000613          	li	a2,128
    80005f9e:	f7040593          	addi	a1,s0,-144
    80005fa2:	4501                	li	a0,0
    80005fa4:	ffffd097          	auipc	ra,0xffffd
    80005fa8:	17e080e7          	jalr	382(ra) # 80003122 <argstr>
    80005fac:	02054963          	bltz	a0,80005fde <sys_mkdir+0x54>
    80005fb0:	4681                	li	a3,0
    80005fb2:	4601                	li	a2,0
    80005fb4:	4585                	li	a1,1
    80005fb6:	f7040513          	addi	a0,s0,-144
    80005fba:	00000097          	auipc	ra,0x0
    80005fbe:	800080e7          	jalr	-2048(ra) # 800057ba <create>
    80005fc2:	cd11                	beqz	a0,80005fde <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	0ee080e7          	jalr	238(ra) # 800040b2 <iunlockput>
  end_op();
    80005fcc:	fffff097          	auipc	ra,0xfffff
    80005fd0:	8c6080e7          	jalr	-1850(ra) # 80004892 <end_op>
  return 0;
    80005fd4:	4501                	li	a0,0
}
    80005fd6:	60aa                	ld	ra,136(sp)
    80005fd8:	640a                	ld	s0,128(sp)
    80005fda:	6149                	addi	sp,sp,144
    80005fdc:	8082                	ret
    end_op();
    80005fde:	fffff097          	auipc	ra,0xfffff
    80005fe2:	8b4080e7          	jalr	-1868(ra) # 80004892 <end_op>
    return -1;
    80005fe6:	557d                	li	a0,-1
    80005fe8:	b7fd                	j	80005fd6 <sys_mkdir+0x4c>

0000000080005fea <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fea:	7135                	addi	sp,sp,-160
    80005fec:	ed06                	sd	ra,152(sp)
    80005fee:	e922                	sd	s0,144(sp)
    80005ff0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ff2:	fffff097          	auipc	ra,0xfffff
    80005ff6:	820080e7          	jalr	-2016(ra) # 80004812 <begin_op>
  argint(1, &major);
    80005ffa:	f6c40593          	addi	a1,s0,-148
    80005ffe:	4505                	li	a0,1
    80006000:	ffffd097          	auipc	ra,0xffffd
    80006004:	0e2080e7          	jalr	226(ra) # 800030e2 <argint>
  argint(2, &minor);
    80006008:	f6840593          	addi	a1,s0,-152
    8000600c:	4509                	li	a0,2
    8000600e:	ffffd097          	auipc	ra,0xffffd
    80006012:	0d4080e7          	jalr	212(ra) # 800030e2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006016:	08000613          	li	a2,128
    8000601a:	f7040593          	addi	a1,s0,-144
    8000601e:	4501                	li	a0,0
    80006020:	ffffd097          	auipc	ra,0xffffd
    80006024:	102080e7          	jalr	258(ra) # 80003122 <argstr>
    80006028:	02054b63          	bltz	a0,8000605e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000602c:	f6841683          	lh	a3,-152(s0)
    80006030:	f6c41603          	lh	a2,-148(s0)
    80006034:	458d                	li	a1,3
    80006036:	f7040513          	addi	a0,s0,-144
    8000603a:	fffff097          	auipc	ra,0xfffff
    8000603e:	780080e7          	jalr	1920(ra) # 800057ba <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006042:	cd11                	beqz	a0,8000605e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006044:	ffffe097          	auipc	ra,0xffffe
    80006048:	06e080e7          	jalr	110(ra) # 800040b2 <iunlockput>
  end_op();
    8000604c:	fffff097          	auipc	ra,0xfffff
    80006050:	846080e7          	jalr	-1978(ra) # 80004892 <end_op>
  return 0;
    80006054:	4501                	li	a0,0
}
    80006056:	60ea                	ld	ra,152(sp)
    80006058:	644a                	ld	s0,144(sp)
    8000605a:	610d                	addi	sp,sp,160
    8000605c:	8082                	ret
    end_op();
    8000605e:	fffff097          	auipc	ra,0xfffff
    80006062:	834080e7          	jalr	-1996(ra) # 80004892 <end_op>
    return -1;
    80006066:	557d                	li	a0,-1
    80006068:	b7fd                	j	80006056 <sys_mknod+0x6c>

000000008000606a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000606a:	7135                	addi	sp,sp,-160
    8000606c:	ed06                	sd	ra,152(sp)
    8000606e:	e922                	sd	s0,144(sp)
    80006070:	e526                	sd	s1,136(sp)
    80006072:	e14a                	sd	s2,128(sp)
    80006074:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006076:	ffffc097          	auipc	ra,0xffffc
    8000607a:	b80080e7          	jalr	-1152(ra) # 80001bf6 <myproc>
    8000607e:	892a                	mv	s2,a0
  
  begin_op();
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	792080e7          	jalr	1938(ra) # 80004812 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006088:	08000613          	li	a2,128
    8000608c:	f6040593          	addi	a1,s0,-160
    80006090:	4501                	li	a0,0
    80006092:	ffffd097          	auipc	ra,0xffffd
    80006096:	090080e7          	jalr	144(ra) # 80003122 <argstr>
    8000609a:	04054b63          	bltz	a0,800060f0 <sys_chdir+0x86>
    8000609e:	f6040513          	addi	a0,s0,-160
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	554080e7          	jalr	1364(ra) # 800045f6 <namei>
    800060aa:	84aa                	mv	s1,a0
    800060ac:	c131                	beqz	a0,800060f0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	da2080e7          	jalr	-606(ra) # 80003e50 <ilock>
  if(ip->type != T_DIR){
    800060b6:	04449703          	lh	a4,68(s1)
    800060ba:	4785                	li	a5,1
    800060bc:	04f71063          	bne	a4,a5,800060fc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800060c0:	8526                	mv	a0,s1
    800060c2:	ffffe097          	auipc	ra,0xffffe
    800060c6:	e50080e7          	jalr	-432(ra) # 80003f12 <iunlock>
  iput(p->cwd);
    800060ca:	15093503          	ld	a0,336(s2)
    800060ce:	ffffe097          	auipc	ra,0xffffe
    800060d2:	f3c080e7          	jalr	-196(ra) # 8000400a <iput>
  end_op();
    800060d6:	ffffe097          	auipc	ra,0xffffe
    800060da:	7bc080e7          	jalr	1980(ra) # 80004892 <end_op>
  p->cwd = ip;
    800060de:	14993823          	sd	s1,336(s2)
  return 0;
    800060e2:	4501                	li	a0,0
}
    800060e4:	60ea                	ld	ra,152(sp)
    800060e6:	644a                	ld	s0,144(sp)
    800060e8:	64aa                	ld	s1,136(sp)
    800060ea:	690a                	ld	s2,128(sp)
    800060ec:	610d                	addi	sp,sp,160
    800060ee:	8082                	ret
    end_op();
    800060f0:	ffffe097          	auipc	ra,0xffffe
    800060f4:	7a2080e7          	jalr	1954(ra) # 80004892 <end_op>
    return -1;
    800060f8:	557d                	li	a0,-1
    800060fa:	b7ed                	j	800060e4 <sys_chdir+0x7a>
    iunlockput(ip);
    800060fc:	8526                	mv	a0,s1
    800060fe:	ffffe097          	auipc	ra,0xffffe
    80006102:	fb4080e7          	jalr	-76(ra) # 800040b2 <iunlockput>
    end_op();
    80006106:	ffffe097          	auipc	ra,0xffffe
    8000610a:	78c080e7          	jalr	1932(ra) # 80004892 <end_op>
    return -1;
    8000610e:	557d                	li	a0,-1
    80006110:	bfd1                	j	800060e4 <sys_chdir+0x7a>

0000000080006112 <sys_exec>:

uint64
sys_exec(void)
{
    80006112:	7145                	addi	sp,sp,-464
    80006114:	e786                	sd	ra,456(sp)
    80006116:	e3a2                	sd	s0,448(sp)
    80006118:	ff26                	sd	s1,440(sp)
    8000611a:	fb4a                	sd	s2,432(sp)
    8000611c:	f74e                	sd	s3,424(sp)
    8000611e:	f352                	sd	s4,416(sp)
    80006120:	ef56                	sd	s5,408(sp)
    80006122:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006124:	e3840593          	addi	a1,s0,-456
    80006128:	4505                	li	a0,1
    8000612a:	ffffd097          	auipc	ra,0xffffd
    8000612e:	fd8080e7          	jalr	-40(ra) # 80003102 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006132:	08000613          	li	a2,128
    80006136:	f4040593          	addi	a1,s0,-192
    8000613a:	4501                	li	a0,0
    8000613c:	ffffd097          	auipc	ra,0xffffd
    80006140:	fe6080e7          	jalr	-26(ra) # 80003122 <argstr>
    80006144:	87aa                	mv	a5,a0
    return -1;
    80006146:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006148:	0c07c263          	bltz	a5,8000620c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000614c:	10000613          	li	a2,256
    80006150:	4581                	li	a1,0
    80006152:	e4040513          	addi	a0,s0,-448
    80006156:	ffffb097          	auipc	ra,0xffffb
    8000615a:	b7c080e7          	jalr	-1156(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000615e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006162:	89a6                	mv	s3,s1
    80006164:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006166:	02000a13          	li	s4,32
    8000616a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000616e:	00391793          	slli	a5,s2,0x3
    80006172:	e3040593          	addi	a1,s0,-464
    80006176:	e3843503          	ld	a0,-456(s0)
    8000617a:	953e                	add	a0,a0,a5
    8000617c:	ffffd097          	auipc	ra,0xffffd
    80006180:	ec8080e7          	jalr	-312(ra) # 80003044 <fetchaddr>
    80006184:	02054a63          	bltz	a0,800061b8 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006188:	e3043783          	ld	a5,-464(s0)
    8000618c:	c3b9                	beqz	a5,800061d2 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000618e:	ffffb097          	auipc	ra,0xffffb
    80006192:	958080e7          	jalr	-1704(ra) # 80000ae6 <kalloc>
    80006196:	85aa                	mv	a1,a0
    80006198:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000619c:	cd11                	beqz	a0,800061b8 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000619e:	6605                	lui	a2,0x1
    800061a0:	e3043503          	ld	a0,-464(s0)
    800061a4:	ffffd097          	auipc	ra,0xffffd
    800061a8:	ef2080e7          	jalr	-270(ra) # 80003096 <fetchstr>
    800061ac:	00054663          	bltz	a0,800061b8 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800061b0:	0905                	addi	s2,s2,1
    800061b2:	09a1                	addi	s3,s3,8
    800061b4:	fb491be3          	bne	s2,s4,8000616a <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061b8:	10048913          	addi	s2,s1,256
    800061bc:	6088                	ld	a0,0(s1)
    800061be:	c531                	beqz	a0,8000620a <sys_exec+0xf8>
    kfree(argv[i]);
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	82a080e7          	jalr	-2006(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061c8:	04a1                	addi	s1,s1,8
    800061ca:	ff2499e3          	bne	s1,s2,800061bc <sys_exec+0xaa>
  return -1;
    800061ce:	557d                	li	a0,-1
    800061d0:	a835                	j	8000620c <sys_exec+0xfa>
      argv[i] = 0;
    800061d2:	0a8e                	slli	s5,s5,0x3
    800061d4:	fc040793          	addi	a5,s0,-64
    800061d8:	9abe                	add	s5,s5,a5
    800061da:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800061de:	e4040593          	addi	a1,s0,-448
    800061e2:	f4040513          	addi	a0,s0,-192
    800061e6:	fffff097          	auipc	ra,0xfffff
    800061ea:	172080e7          	jalr	370(ra) # 80005358 <exec>
    800061ee:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061f0:	10048993          	addi	s3,s1,256
    800061f4:	6088                	ld	a0,0(s1)
    800061f6:	c901                	beqz	a0,80006206 <sys_exec+0xf4>
    kfree(argv[i]);
    800061f8:	ffffa097          	auipc	ra,0xffffa
    800061fc:	7f2080e7          	jalr	2034(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006200:	04a1                	addi	s1,s1,8
    80006202:	ff3499e3          	bne	s1,s3,800061f4 <sys_exec+0xe2>
  return ret;
    80006206:	854a                	mv	a0,s2
    80006208:	a011                	j	8000620c <sys_exec+0xfa>
  return -1;
    8000620a:	557d                	li	a0,-1
}
    8000620c:	60be                	ld	ra,456(sp)
    8000620e:	641e                	ld	s0,448(sp)
    80006210:	74fa                	ld	s1,440(sp)
    80006212:	795a                	ld	s2,432(sp)
    80006214:	79ba                	ld	s3,424(sp)
    80006216:	7a1a                	ld	s4,416(sp)
    80006218:	6afa                	ld	s5,408(sp)
    8000621a:	6179                	addi	sp,sp,464
    8000621c:	8082                	ret

000000008000621e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000621e:	7139                	addi	sp,sp,-64
    80006220:	fc06                	sd	ra,56(sp)
    80006222:	f822                	sd	s0,48(sp)
    80006224:	f426                	sd	s1,40(sp)
    80006226:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006228:	ffffc097          	auipc	ra,0xffffc
    8000622c:	9ce080e7          	jalr	-1586(ra) # 80001bf6 <myproc>
    80006230:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006232:	fd840593          	addi	a1,s0,-40
    80006236:	4501                	li	a0,0
    80006238:	ffffd097          	auipc	ra,0xffffd
    8000623c:	eca080e7          	jalr	-310(ra) # 80003102 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006240:	fc840593          	addi	a1,s0,-56
    80006244:	fd040513          	addi	a0,s0,-48
    80006248:	fffff097          	auipc	ra,0xfffff
    8000624c:	dc6080e7          	jalr	-570(ra) # 8000500e <pipealloc>
    return -1;
    80006250:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006252:	0c054463          	bltz	a0,8000631a <sys_pipe+0xfc>
  fd0 = -1;
    80006256:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000625a:	fd043503          	ld	a0,-48(s0)
    8000625e:	fffff097          	auipc	ra,0xfffff
    80006262:	51a080e7          	jalr	1306(ra) # 80005778 <fdalloc>
    80006266:	fca42223          	sw	a0,-60(s0)
    8000626a:	08054b63          	bltz	a0,80006300 <sys_pipe+0xe2>
    8000626e:	fc843503          	ld	a0,-56(s0)
    80006272:	fffff097          	auipc	ra,0xfffff
    80006276:	506080e7          	jalr	1286(ra) # 80005778 <fdalloc>
    8000627a:	fca42023          	sw	a0,-64(s0)
    8000627e:	06054863          	bltz	a0,800062ee <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006282:	4691                	li	a3,4
    80006284:	fc440613          	addi	a2,s0,-60
    80006288:	fd843583          	ld	a1,-40(s0)
    8000628c:	68a8                	ld	a0,80(s1)
    8000628e:	ffffb097          	auipc	ra,0xffffb
    80006292:	3da080e7          	jalr	986(ra) # 80001668 <copyout>
    80006296:	02054063          	bltz	a0,800062b6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000629a:	4691                	li	a3,4
    8000629c:	fc040613          	addi	a2,s0,-64
    800062a0:	fd843583          	ld	a1,-40(s0)
    800062a4:	0591                	addi	a1,a1,4
    800062a6:	68a8                	ld	a0,80(s1)
    800062a8:	ffffb097          	auipc	ra,0xffffb
    800062ac:	3c0080e7          	jalr	960(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800062b0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062b2:	06055463          	bgez	a0,8000631a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800062b6:	fc442783          	lw	a5,-60(s0)
    800062ba:	07e9                	addi	a5,a5,26
    800062bc:	078e                	slli	a5,a5,0x3
    800062be:	97a6                	add	a5,a5,s1
    800062c0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800062c4:	fc042503          	lw	a0,-64(s0)
    800062c8:	0569                	addi	a0,a0,26
    800062ca:	050e                	slli	a0,a0,0x3
    800062cc:	94aa                	add	s1,s1,a0
    800062ce:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800062d2:	fd043503          	ld	a0,-48(s0)
    800062d6:	fffff097          	auipc	ra,0xfffff
    800062da:	a08080e7          	jalr	-1528(ra) # 80004cde <fileclose>
    fileclose(wf);
    800062de:	fc843503          	ld	a0,-56(s0)
    800062e2:	fffff097          	auipc	ra,0xfffff
    800062e6:	9fc080e7          	jalr	-1540(ra) # 80004cde <fileclose>
    return -1;
    800062ea:	57fd                	li	a5,-1
    800062ec:	a03d                	j	8000631a <sys_pipe+0xfc>
    if(fd0 >= 0)
    800062ee:	fc442783          	lw	a5,-60(s0)
    800062f2:	0007c763          	bltz	a5,80006300 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800062f6:	07e9                	addi	a5,a5,26
    800062f8:	078e                	slli	a5,a5,0x3
    800062fa:	94be                	add	s1,s1,a5
    800062fc:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006300:	fd043503          	ld	a0,-48(s0)
    80006304:	fffff097          	auipc	ra,0xfffff
    80006308:	9da080e7          	jalr	-1574(ra) # 80004cde <fileclose>
    fileclose(wf);
    8000630c:	fc843503          	ld	a0,-56(s0)
    80006310:	fffff097          	auipc	ra,0xfffff
    80006314:	9ce080e7          	jalr	-1586(ra) # 80004cde <fileclose>
    return -1;
    80006318:	57fd                	li	a5,-1
}
    8000631a:	853e                	mv	a0,a5
    8000631c:	70e2                	ld	ra,56(sp)
    8000631e:	7442                	ld	s0,48(sp)
    80006320:	74a2                	ld	s1,40(sp)
    80006322:	6121                	addi	sp,sp,64
    80006324:	8082                	ret
	...

0000000080006330 <kernelvec>:
    80006330:	7111                	addi	sp,sp,-256
    80006332:	e006                	sd	ra,0(sp)
    80006334:	e40a                	sd	sp,8(sp)
    80006336:	e80e                	sd	gp,16(sp)
    80006338:	ec12                	sd	tp,24(sp)
    8000633a:	f016                	sd	t0,32(sp)
    8000633c:	f41a                	sd	t1,40(sp)
    8000633e:	f81e                	sd	t2,48(sp)
    80006340:	fc22                	sd	s0,56(sp)
    80006342:	e0a6                	sd	s1,64(sp)
    80006344:	e4aa                	sd	a0,72(sp)
    80006346:	e8ae                	sd	a1,80(sp)
    80006348:	ecb2                	sd	a2,88(sp)
    8000634a:	f0b6                	sd	a3,96(sp)
    8000634c:	f4ba                	sd	a4,104(sp)
    8000634e:	f8be                	sd	a5,112(sp)
    80006350:	fcc2                	sd	a6,120(sp)
    80006352:	e146                	sd	a7,128(sp)
    80006354:	e54a                	sd	s2,136(sp)
    80006356:	e94e                	sd	s3,144(sp)
    80006358:	ed52                	sd	s4,152(sp)
    8000635a:	f156                	sd	s5,160(sp)
    8000635c:	f55a                	sd	s6,168(sp)
    8000635e:	f95e                	sd	s7,176(sp)
    80006360:	fd62                	sd	s8,184(sp)
    80006362:	e1e6                	sd	s9,192(sp)
    80006364:	e5ea                	sd	s10,200(sp)
    80006366:	e9ee                	sd	s11,208(sp)
    80006368:	edf2                	sd	t3,216(sp)
    8000636a:	f1f6                	sd	t4,224(sp)
    8000636c:	f5fa                	sd	t5,232(sp)
    8000636e:	f9fe                	sd	t6,240(sp)
    80006370:	ba1fc0ef          	jal	ra,80002f10 <kerneltrap>
    80006374:	6082                	ld	ra,0(sp)
    80006376:	6122                	ld	sp,8(sp)
    80006378:	61c2                	ld	gp,16(sp)
    8000637a:	7282                	ld	t0,32(sp)
    8000637c:	7322                	ld	t1,40(sp)
    8000637e:	73c2                	ld	t2,48(sp)
    80006380:	7462                	ld	s0,56(sp)
    80006382:	6486                	ld	s1,64(sp)
    80006384:	6526                	ld	a0,72(sp)
    80006386:	65c6                	ld	a1,80(sp)
    80006388:	6666                	ld	a2,88(sp)
    8000638a:	7686                	ld	a3,96(sp)
    8000638c:	7726                	ld	a4,104(sp)
    8000638e:	77c6                	ld	a5,112(sp)
    80006390:	7866                	ld	a6,120(sp)
    80006392:	688a                	ld	a7,128(sp)
    80006394:	692a                	ld	s2,136(sp)
    80006396:	69ca                	ld	s3,144(sp)
    80006398:	6a6a                	ld	s4,152(sp)
    8000639a:	7a8a                	ld	s5,160(sp)
    8000639c:	7b2a                	ld	s6,168(sp)
    8000639e:	7bca                	ld	s7,176(sp)
    800063a0:	7c6a                	ld	s8,184(sp)
    800063a2:	6c8e                	ld	s9,192(sp)
    800063a4:	6d2e                	ld	s10,200(sp)
    800063a6:	6dce                	ld	s11,208(sp)
    800063a8:	6e6e                	ld	t3,216(sp)
    800063aa:	7e8e                	ld	t4,224(sp)
    800063ac:	7f2e                	ld	t5,232(sp)
    800063ae:	7fce                	ld	t6,240(sp)
    800063b0:	6111                	addi	sp,sp,256
    800063b2:	10200073          	sret
    800063b6:	00000013          	nop
    800063ba:	00000013          	nop
    800063be:	0001                	nop

00000000800063c0 <timervec>:
    800063c0:	34051573          	csrrw	a0,mscratch,a0
    800063c4:	e10c                	sd	a1,0(a0)
    800063c6:	e510                	sd	a2,8(a0)
    800063c8:	e914                	sd	a3,16(a0)
    800063ca:	6d0c                	ld	a1,24(a0)
    800063cc:	7110                	ld	a2,32(a0)
    800063ce:	6194                	ld	a3,0(a1)
    800063d0:	96b2                	add	a3,a3,a2
    800063d2:	e194                	sd	a3,0(a1)
    800063d4:	4589                	li	a1,2
    800063d6:	14459073          	csrw	sip,a1
    800063da:	6914                	ld	a3,16(a0)
    800063dc:	6510                	ld	a2,8(a0)
    800063de:	610c                	ld	a1,0(a0)
    800063e0:	34051573          	csrrw	a0,mscratch,a0
    800063e4:	30200073          	mret
	...

00000000800063ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063ea:	1141                	addi	sp,sp,-16
    800063ec:	e422                	sd	s0,8(sp)
    800063ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063f0:	0c0007b7          	lui	a5,0xc000
    800063f4:	4705                	li	a4,1
    800063f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063f8:	c3d8                	sw	a4,4(a5)
}
    800063fa:	6422                	ld	s0,8(sp)
    800063fc:	0141                	addi	sp,sp,16
    800063fe:	8082                	ret

0000000080006400 <plicinithart>:

void
plicinithart(void)
{
    80006400:	1141                	addi	sp,sp,-16
    80006402:	e406                	sd	ra,8(sp)
    80006404:	e022                	sd	s0,0(sp)
    80006406:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006408:	ffffb097          	auipc	ra,0xffffb
    8000640c:	7c2080e7          	jalr	1986(ra) # 80001bca <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006410:	0085171b          	slliw	a4,a0,0x8
    80006414:	0c0027b7          	lui	a5,0xc002
    80006418:	97ba                	add	a5,a5,a4
    8000641a:	40200713          	li	a4,1026
    8000641e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006422:	00d5151b          	slliw	a0,a0,0xd
    80006426:	0c2017b7          	lui	a5,0xc201
    8000642a:	953e                	add	a0,a0,a5
    8000642c:	00052023          	sw	zero,0(a0)
}
    80006430:	60a2                	ld	ra,8(sp)
    80006432:	6402                	ld	s0,0(sp)
    80006434:	0141                	addi	sp,sp,16
    80006436:	8082                	ret

0000000080006438 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006438:	1141                	addi	sp,sp,-16
    8000643a:	e406                	sd	ra,8(sp)
    8000643c:	e022                	sd	s0,0(sp)
    8000643e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006440:	ffffb097          	auipc	ra,0xffffb
    80006444:	78a080e7          	jalr	1930(ra) # 80001bca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006448:	00d5179b          	slliw	a5,a0,0xd
    8000644c:	0c201537          	lui	a0,0xc201
    80006450:	953e                	add	a0,a0,a5
  return irq;
}
    80006452:	4148                	lw	a0,4(a0)
    80006454:	60a2                	ld	ra,8(sp)
    80006456:	6402                	ld	s0,0(sp)
    80006458:	0141                	addi	sp,sp,16
    8000645a:	8082                	ret

000000008000645c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000645c:	1101                	addi	sp,sp,-32
    8000645e:	ec06                	sd	ra,24(sp)
    80006460:	e822                	sd	s0,16(sp)
    80006462:	e426                	sd	s1,8(sp)
    80006464:	1000                	addi	s0,sp,32
    80006466:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006468:	ffffb097          	auipc	ra,0xffffb
    8000646c:	762080e7          	jalr	1890(ra) # 80001bca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006470:	00d5151b          	slliw	a0,a0,0xd
    80006474:	0c2017b7          	lui	a5,0xc201
    80006478:	97aa                	add	a5,a5,a0
    8000647a:	c3c4                	sw	s1,4(a5)
}
    8000647c:	60e2                	ld	ra,24(sp)
    8000647e:	6442                	ld	s0,16(sp)
    80006480:	64a2                	ld	s1,8(sp)
    80006482:	6105                	addi	sp,sp,32
    80006484:	8082                	ret

0000000080006486 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006486:	1141                	addi	sp,sp,-16
    80006488:	e406                	sd	ra,8(sp)
    8000648a:	e022                	sd	s0,0(sp)
    8000648c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000648e:	479d                	li	a5,7
    80006490:	04a7cc63          	blt	a5,a0,800064e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006494:	00023797          	auipc	a5,0x23
    80006498:	e6478793          	addi	a5,a5,-412 # 800292f8 <disk>
    8000649c:	97aa                	add	a5,a5,a0
    8000649e:	0187c783          	lbu	a5,24(a5)
    800064a2:	ebb9                	bnez	a5,800064f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800064a4:	00451613          	slli	a2,a0,0x4
    800064a8:	00023797          	auipc	a5,0x23
    800064ac:	e5078793          	addi	a5,a5,-432 # 800292f8 <disk>
    800064b0:	6394                	ld	a3,0(a5)
    800064b2:	96b2                	add	a3,a3,a2
    800064b4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800064b8:	6398                	ld	a4,0(a5)
    800064ba:	9732                	add	a4,a4,a2
    800064bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800064c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800064c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800064c8:	953e                	add	a0,a0,a5
    800064ca:	4785                	li	a5,1
    800064cc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800064d0:	00023517          	auipc	a0,0x23
    800064d4:	e4050513          	addi	a0,a0,-448 # 80029310 <disk+0x18>
    800064d8:	ffffc097          	auipc	ra,0xffffc
    800064dc:	fe8080e7          	jalr	-24(ra) # 800024c0 <wakeup>
}
    800064e0:	60a2                	ld	ra,8(sp)
    800064e2:	6402                	ld	s0,0(sp)
    800064e4:	0141                	addi	sp,sp,16
    800064e6:	8082                	ret
    panic("free_desc 1");
    800064e8:	00002517          	auipc	a0,0x2
    800064ec:	2e850513          	addi	a0,a0,744 # 800087d0 <syscalls+0x318>
    800064f0:	ffffa097          	auipc	ra,0xffffa
    800064f4:	04e080e7          	jalr	78(ra) # 8000053e <panic>
    panic("free_desc 2");
    800064f8:	00002517          	auipc	a0,0x2
    800064fc:	2e850513          	addi	a0,a0,744 # 800087e0 <syscalls+0x328>
    80006500:	ffffa097          	auipc	ra,0xffffa
    80006504:	03e080e7          	jalr	62(ra) # 8000053e <panic>

0000000080006508 <virtio_disk_init>:
{
    80006508:	1101                	addi	sp,sp,-32
    8000650a:	ec06                	sd	ra,24(sp)
    8000650c:	e822                	sd	s0,16(sp)
    8000650e:	e426                	sd	s1,8(sp)
    80006510:	e04a                	sd	s2,0(sp)
    80006512:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006514:	00002597          	auipc	a1,0x2
    80006518:	2dc58593          	addi	a1,a1,732 # 800087f0 <syscalls+0x338>
    8000651c:	00023517          	auipc	a0,0x23
    80006520:	f0450513          	addi	a0,a0,-252 # 80029420 <disk+0x128>
    80006524:	ffffa097          	auipc	ra,0xffffa
    80006528:	622080e7          	jalr	1570(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000652c:	100017b7          	lui	a5,0x10001
    80006530:	4398                	lw	a4,0(a5)
    80006532:	2701                	sext.w	a4,a4
    80006534:	747277b7          	lui	a5,0x74727
    80006538:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000653c:	14f71c63          	bne	a4,a5,80006694 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006540:	100017b7          	lui	a5,0x10001
    80006544:	43dc                	lw	a5,4(a5)
    80006546:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006548:	4709                	li	a4,2
    8000654a:	14e79563          	bne	a5,a4,80006694 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000654e:	100017b7          	lui	a5,0x10001
    80006552:	479c                	lw	a5,8(a5)
    80006554:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006556:	12e79f63          	bne	a5,a4,80006694 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000655a:	100017b7          	lui	a5,0x10001
    8000655e:	47d8                	lw	a4,12(a5)
    80006560:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006562:	554d47b7          	lui	a5,0x554d4
    80006566:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000656a:	12f71563          	bne	a4,a5,80006694 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000656e:	100017b7          	lui	a5,0x10001
    80006572:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006576:	4705                	li	a4,1
    80006578:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000657a:	470d                	li	a4,3
    8000657c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000657e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006580:	c7ffe737          	lui	a4,0xc7ffe
    80006584:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd5327>
    80006588:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000658a:	2701                	sext.w	a4,a4
    8000658c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000658e:	472d                	li	a4,11
    80006590:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006592:	5bbc                	lw	a5,112(a5)
    80006594:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006598:	8ba1                	andi	a5,a5,8
    8000659a:	10078563          	beqz	a5,800066a4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000659e:	100017b7          	lui	a5,0x10001
    800065a2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800065a6:	43fc                	lw	a5,68(a5)
    800065a8:	2781                	sext.w	a5,a5
    800065aa:	10079563          	bnez	a5,800066b4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800065ae:	100017b7          	lui	a5,0x10001
    800065b2:	5bdc                	lw	a5,52(a5)
    800065b4:	2781                	sext.w	a5,a5
  if(max == 0)
    800065b6:	10078763          	beqz	a5,800066c4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800065ba:	471d                	li	a4,7
    800065bc:	10f77c63          	bgeu	a4,a5,800066d4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800065c0:	ffffa097          	auipc	ra,0xffffa
    800065c4:	526080e7          	jalr	1318(ra) # 80000ae6 <kalloc>
    800065c8:	00023497          	auipc	s1,0x23
    800065cc:	d3048493          	addi	s1,s1,-720 # 800292f8 <disk>
    800065d0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800065d2:	ffffa097          	auipc	ra,0xffffa
    800065d6:	514080e7          	jalr	1300(ra) # 80000ae6 <kalloc>
    800065da:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	50a080e7          	jalr	1290(ra) # 80000ae6 <kalloc>
    800065e4:	87aa                	mv	a5,a0
    800065e6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800065e8:	6088                	ld	a0,0(s1)
    800065ea:	cd6d                	beqz	a0,800066e4 <virtio_disk_init+0x1dc>
    800065ec:	00023717          	auipc	a4,0x23
    800065f0:	d1473703          	ld	a4,-748(a4) # 80029300 <disk+0x8>
    800065f4:	cb65                	beqz	a4,800066e4 <virtio_disk_init+0x1dc>
    800065f6:	c7fd                	beqz	a5,800066e4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800065f8:	6605                	lui	a2,0x1
    800065fa:	4581                	li	a1,0
    800065fc:	ffffa097          	auipc	ra,0xffffa
    80006600:	6d6080e7          	jalr	1750(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006604:	00023497          	auipc	s1,0x23
    80006608:	cf448493          	addi	s1,s1,-780 # 800292f8 <disk>
    8000660c:	6605                	lui	a2,0x1
    8000660e:	4581                	li	a1,0
    80006610:	6488                	ld	a0,8(s1)
    80006612:	ffffa097          	auipc	ra,0xffffa
    80006616:	6c0080e7          	jalr	1728(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000661a:	6605                	lui	a2,0x1
    8000661c:	4581                	li	a1,0
    8000661e:	6888                	ld	a0,16(s1)
    80006620:	ffffa097          	auipc	ra,0xffffa
    80006624:	6b2080e7          	jalr	1714(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006628:	100017b7          	lui	a5,0x10001
    8000662c:	4721                	li	a4,8
    8000662e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006630:	4098                	lw	a4,0(s1)
    80006632:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006636:	40d8                	lw	a4,4(s1)
    80006638:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000663c:	6498                	ld	a4,8(s1)
    8000663e:	0007069b          	sext.w	a3,a4
    80006642:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006646:	9701                	srai	a4,a4,0x20
    80006648:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000664c:	6898                	ld	a4,16(s1)
    8000664e:	0007069b          	sext.w	a3,a4
    80006652:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006656:	9701                	srai	a4,a4,0x20
    80006658:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000665c:	4705                	li	a4,1
    8000665e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006660:	00e48c23          	sb	a4,24(s1)
    80006664:	00e48ca3          	sb	a4,25(s1)
    80006668:	00e48d23          	sb	a4,26(s1)
    8000666c:	00e48da3          	sb	a4,27(s1)
    80006670:	00e48e23          	sb	a4,28(s1)
    80006674:	00e48ea3          	sb	a4,29(s1)
    80006678:	00e48f23          	sb	a4,30(s1)
    8000667c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006680:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006684:	0727a823          	sw	s2,112(a5)
}
    80006688:	60e2                	ld	ra,24(sp)
    8000668a:	6442                	ld	s0,16(sp)
    8000668c:	64a2                	ld	s1,8(sp)
    8000668e:	6902                	ld	s2,0(sp)
    80006690:	6105                	addi	sp,sp,32
    80006692:	8082                	ret
    panic("could not find virtio disk");
    80006694:	00002517          	auipc	a0,0x2
    80006698:	16c50513          	addi	a0,a0,364 # 80008800 <syscalls+0x348>
    8000669c:	ffffa097          	auipc	ra,0xffffa
    800066a0:	ea2080e7          	jalr	-350(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800066a4:	00002517          	auipc	a0,0x2
    800066a8:	17c50513          	addi	a0,a0,380 # 80008820 <syscalls+0x368>
    800066ac:	ffffa097          	auipc	ra,0xffffa
    800066b0:	e92080e7          	jalr	-366(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800066b4:	00002517          	auipc	a0,0x2
    800066b8:	18c50513          	addi	a0,a0,396 # 80008840 <syscalls+0x388>
    800066bc:	ffffa097          	auipc	ra,0xffffa
    800066c0:	e82080e7          	jalr	-382(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800066c4:	00002517          	auipc	a0,0x2
    800066c8:	19c50513          	addi	a0,a0,412 # 80008860 <syscalls+0x3a8>
    800066cc:	ffffa097          	auipc	ra,0xffffa
    800066d0:	e72080e7          	jalr	-398(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800066d4:	00002517          	auipc	a0,0x2
    800066d8:	1ac50513          	addi	a0,a0,428 # 80008880 <syscalls+0x3c8>
    800066dc:	ffffa097          	auipc	ra,0xffffa
    800066e0:	e62080e7          	jalr	-414(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800066e4:	00002517          	auipc	a0,0x2
    800066e8:	1bc50513          	addi	a0,a0,444 # 800088a0 <syscalls+0x3e8>
    800066ec:	ffffa097          	auipc	ra,0xffffa
    800066f0:	e52080e7          	jalr	-430(ra) # 8000053e <panic>

00000000800066f4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066f4:	7119                	addi	sp,sp,-128
    800066f6:	fc86                	sd	ra,120(sp)
    800066f8:	f8a2                	sd	s0,112(sp)
    800066fa:	f4a6                	sd	s1,104(sp)
    800066fc:	f0ca                	sd	s2,96(sp)
    800066fe:	ecce                	sd	s3,88(sp)
    80006700:	e8d2                	sd	s4,80(sp)
    80006702:	e4d6                	sd	s5,72(sp)
    80006704:	e0da                	sd	s6,64(sp)
    80006706:	fc5e                	sd	s7,56(sp)
    80006708:	f862                	sd	s8,48(sp)
    8000670a:	f466                	sd	s9,40(sp)
    8000670c:	f06a                	sd	s10,32(sp)
    8000670e:	ec6e                	sd	s11,24(sp)
    80006710:	0100                	addi	s0,sp,128
    80006712:	8aaa                	mv	s5,a0
    80006714:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006716:	00c52d03          	lw	s10,12(a0)
    8000671a:	001d1d1b          	slliw	s10,s10,0x1
    8000671e:	1d02                	slli	s10,s10,0x20
    80006720:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006724:	00023517          	auipc	a0,0x23
    80006728:	cfc50513          	addi	a0,a0,-772 # 80029420 <disk+0x128>
    8000672c:	ffffa097          	auipc	ra,0xffffa
    80006730:	4aa080e7          	jalr	1194(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006734:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006736:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006738:	00023b97          	auipc	s7,0x23
    8000673c:	bc0b8b93          	addi	s7,s7,-1088 # 800292f8 <disk>
  for(int i = 0; i < 3; i++){
    80006740:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006742:	00023c97          	auipc	s9,0x23
    80006746:	cdec8c93          	addi	s9,s9,-802 # 80029420 <disk+0x128>
    8000674a:	a08d                	j	800067ac <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000674c:	00fb8733          	add	a4,s7,a5
    80006750:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006754:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006756:	0207c563          	bltz	a5,80006780 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000675a:	2905                	addiw	s2,s2,1
    8000675c:	0611                	addi	a2,a2,4
    8000675e:	05690c63          	beq	s2,s6,800067b6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006762:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006764:	00023717          	auipc	a4,0x23
    80006768:	b9470713          	addi	a4,a4,-1132 # 800292f8 <disk>
    8000676c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000676e:	01874683          	lbu	a3,24(a4)
    80006772:	fee9                	bnez	a3,8000674c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006774:	2785                	addiw	a5,a5,1
    80006776:	0705                	addi	a4,a4,1
    80006778:	fe979be3          	bne	a5,s1,8000676e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000677c:	57fd                	li	a5,-1
    8000677e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006780:	01205d63          	blez	s2,8000679a <virtio_disk_rw+0xa6>
    80006784:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006786:	000a2503          	lw	a0,0(s4)
    8000678a:	00000097          	auipc	ra,0x0
    8000678e:	cfc080e7          	jalr	-772(ra) # 80006486 <free_desc>
      for(int j = 0; j < i; j++)
    80006792:	2d85                	addiw	s11,s11,1
    80006794:	0a11                	addi	s4,s4,4
    80006796:	ffb918e3          	bne	s2,s11,80006786 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000679a:	85e6                	mv	a1,s9
    8000679c:	00023517          	auipc	a0,0x23
    800067a0:	b7450513          	addi	a0,a0,-1164 # 80029310 <disk+0x18>
    800067a4:	ffffc097          	auipc	ra,0xffffc
    800067a8:	caa080e7          	jalr	-854(ra) # 8000244e <sleep>
  for(int i = 0; i < 3; i++){
    800067ac:	f8040a13          	addi	s4,s0,-128
{
    800067b0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800067b2:	894e                	mv	s2,s3
    800067b4:	b77d                	j	80006762 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067b6:	f8042583          	lw	a1,-128(s0)
    800067ba:	00a58793          	addi	a5,a1,10
    800067be:	0792                	slli	a5,a5,0x4

  if(write)
    800067c0:	00023617          	auipc	a2,0x23
    800067c4:	b3860613          	addi	a2,a2,-1224 # 800292f8 <disk>
    800067c8:	00f60733          	add	a4,a2,a5
    800067cc:	018036b3          	snez	a3,s8
    800067d0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800067d2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800067d6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800067da:	f6078693          	addi	a3,a5,-160
    800067de:	6218                	ld	a4,0(a2)
    800067e0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067e2:	00878513          	addi	a0,a5,8
    800067e6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800067e8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800067ea:	6208                	ld	a0,0(a2)
    800067ec:	96aa                	add	a3,a3,a0
    800067ee:	4741                	li	a4,16
    800067f0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067f2:	4705                	li	a4,1
    800067f4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800067f8:	f8442703          	lw	a4,-124(s0)
    800067fc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006800:	0712                	slli	a4,a4,0x4
    80006802:	953a                	add	a0,a0,a4
    80006804:	058a8693          	addi	a3,s5,88
    80006808:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000680a:	6208                	ld	a0,0(a2)
    8000680c:	972a                	add	a4,a4,a0
    8000680e:	40000693          	li	a3,1024
    80006812:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006814:	001c3c13          	seqz	s8,s8
    80006818:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000681a:	001c6c13          	ori	s8,s8,1
    8000681e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006822:	f8842603          	lw	a2,-120(s0)
    80006826:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000682a:	00023697          	auipc	a3,0x23
    8000682e:	ace68693          	addi	a3,a3,-1330 # 800292f8 <disk>
    80006832:	00258713          	addi	a4,a1,2
    80006836:	0712                	slli	a4,a4,0x4
    80006838:	9736                	add	a4,a4,a3
    8000683a:	587d                	li	a6,-1
    8000683c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006840:	0612                	slli	a2,a2,0x4
    80006842:	9532                	add	a0,a0,a2
    80006844:	f9078793          	addi	a5,a5,-112
    80006848:	97b6                	add	a5,a5,a3
    8000684a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000684c:	629c                	ld	a5,0(a3)
    8000684e:	97b2                	add	a5,a5,a2
    80006850:	4605                	li	a2,1
    80006852:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006854:	4509                	li	a0,2
    80006856:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000685a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000685e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006862:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006866:	6698                	ld	a4,8(a3)
    80006868:	00275783          	lhu	a5,2(a4)
    8000686c:	8b9d                	andi	a5,a5,7
    8000686e:	0786                	slli	a5,a5,0x1
    80006870:	97ba                	add	a5,a5,a4
    80006872:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006876:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000687a:	6698                	ld	a4,8(a3)
    8000687c:	00275783          	lhu	a5,2(a4)
    80006880:	2785                	addiw	a5,a5,1
    80006882:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006886:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000688a:	100017b7          	lui	a5,0x10001
    8000688e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006892:	004aa783          	lw	a5,4(s5)
    80006896:	02c79163          	bne	a5,a2,800068b8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000689a:	00023917          	auipc	s2,0x23
    8000689e:	b8690913          	addi	s2,s2,-1146 # 80029420 <disk+0x128>
  while(b->disk == 1) {
    800068a2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800068a4:	85ca                	mv	a1,s2
    800068a6:	8556                	mv	a0,s5
    800068a8:	ffffc097          	auipc	ra,0xffffc
    800068ac:	ba6080e7          	jalr	-1114(ra) # 8000244e <sleep>
  while(b->disk == 1) {
    800068b0:	004aa783          	lw	a5,4(s5)
    800068b4:	fe9788e3          	beq	a5,s1,800068a4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800068b8:	f8042903          	lw	s2,-128(s0)
    800068bc:	00290793          	addi	a5,s2,2
    800068c0:	00479713          	slli	a4,a5,0x4
    800068c4:	00023797          	auipc	a5,0x23
    800068c8:	a3478793          	addi	a5,a5,-1484 # 800292f8 <disk>
    800068cc:	97ba                	add	a5,a5,a4
    800068ce:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800068d2:	00023997          	auipc	s3,0x23
    800068d6:	a2698993          	addi	s3,s3,-1498 # 800292f8 <disk>
    800068da:	00491713          	slli	a4,s2,0x4
    800068de:	0009b783          	ld	a5,0(s3)
    800068e2:	97ba                	add	a5,a5,a4
    800068e4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800068e8:	854a                	mv	a0,s2
    800068ea:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068ee:	00000097          	auipc	ra,0x0
    800068f2:	b98080e7          	jalr	-1128(ra) # 80006486 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068f6:	8885                	andi	s1,s1,1
    800068f8:	f0ed                	bnez	s1,800068da <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068fa:	00023517          	auipc	a0,0x23
    800068fe:	b2650513          	addi	a0,a0,-1242 # 80029420 <disk+0x128>
    80006902:	ffffa097          	auipc	ra,0xffffa
    80006906:	388080e7          	jalr	904(ra) # 80000c8a <release>
}
    8000690a:	70e6                	ld	ra,120(sp)
    8000690c:	7446                	ld	s0,112(sp)
    8000690e:	74a6                	ld	s1,104(sp)
    80006910:	7906                	ld	s2,96(sp)
    80006912:	69e6                	ld	s3,88(sp)
    80006914:	6a46                	ld	s4,80(sp)
    80006916:	6aa6                	ld	s5,72(sp)
    80006918:	6b06                	ld	s6,64(sp)
    8000691a:	7be2                	ld	s7,56(sp)
    8000691c:	7c42                	ld	s8,48(sp)
    8000691e:	7ca2                	ld	s9,40(sp)
    80006920:	7d02                	ld	s10,32(sp)
    80006922:	6de2                	ld	s11,24(sp)
    80006924:	6109                	addi	sp,sp,128
    80006926:	8082                	ret

0000000080006928 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006928:	1101                	addi	sp,sp,-32
    8000692a:	ec06                	sd	ra,24(sp)
    8000692c:	e822                	sd	s0,16(sp)
    8000692e:	e426                	sd	s1,8(sp)
    80006930:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006932:	00023497          	auipc	s1,0x23
    80006936:	9c648493          	addi	s1,s1,-1594 # 800292f8 <disk>
    8000693a:	00023517          	auipc	a0,0x23
    8000693e:	ae650513          	addi	a0,a0,-1306 # 80029420 <disk+0x128>
    80006942:	ffffa097          	auipc	ra,0xffffa
    80006946:	294080e7          	jalr	660(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000694a:	10001737          	lui	a4,0x10001
    8000694e:	533c                	lw	a5,96(a4)
    80006950:	8b8d                	andi	a5,a5,3
    80006952:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006954:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006958:	689c                	ld	a5,16(s1)
    8000695a:	0204d703          	lhu	a4,32(s1)
    8000695e:	0027d783          	lhu	a5,2(a5)
    80006962:	04f70863          	beq	a4,a5,800069b2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006966:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000696a:	6898                	ld	a4,16(s1)
    8000696c:	0204d783          	lhu	a5,32(s1)
    80006970:	8b9d                	andi	a5,a5,7
    80006972:	078e                	slli	a5,a5,0x3
    80006974:	97ba                	add	a5,a5,a4
    80006976:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006978:	00278713          	addi	a4,a5,2
    8000697c:	0712                	slli	a4,a4,0x4
    8000697e:	9726                	add	a4,a4,s1
    80006980:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006984:	e721                	bnez	a4,800069cc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006986:	0789                	addi	a5,a5,2
    80006988:	0792                	slli	a5,a5,0x4
    8000698a:	97a6                	add	a5,a5,s1
    8000698c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000698e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006992:	ffffc097          	auipc	ra,0xffffc
    80006996:	b2e080e7          	jalr	-1234(ra) # 800024c0 <wakeup>

    disk.used_idx += 1;
    8000699a:	0204d783          	lhu	a5,32(s1)
    8000699e:	2785                	addiw	a5,a5,1
    800069a0:	17c2                	slli	a5,a5,0x30
    800069a2:	93c1                	srli	a5,a5,0x30
    800069a4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069a8:	6898                	ld	a4,16(s1)
    800069aa:	00275703          	lhu	a4,2(a4)
    800069ae:	faf71ce3          	bne	a4,a5,80006966 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800069b2:	00023517          	auipc	a0,0x23
    800069b6:	a6e50513          	addi	a0,a0,-1426 # 80029420 <disk+0x128>
    800069ba:	ffffa097          	auipc	ra,0xffffa
    800069be:	2d0080e7          	jalr	720(ra) # 80000c8a <release>
}
    800069c2:	60e2                	ld	ra,24(sp)
    800069c4:	6442                	ld	s0,16(sp)
    800069c6:	64a2                	ld	s1,8(sp)
    800069c8:	6105                	addi	sp,sp,32
    800069ca:	8082                	ret
      panic("virtio_disk_intr status");
    800069cc:	00002517          	auipc	a0,0x2
    800069d0:	eec50513          	addi	a0,a0,-276 # 800088b8 <syscalls+0x400>
    800069d4:	ffffa097          	auipc	ra,0xffffa
    800069d8:	b6a080e7          	jalr	-1174(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
