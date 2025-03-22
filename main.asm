
build/Debug/avr_dashboard_resetter.elf:     file format elf32-avr


Disassembly of section .text:

00000000 <__vectors>:
   0:	09 c0       	rjmp	.+18     	; 0x14 <__ctors_end>
   2:	16 c0       	rjmp	.+44     	; 0x30 <__bad_interrupt>
   4:	15 c0       	rjmp	.+42     	; 0x30 <__bad_interrupt>
   6:	15 c0       	rjmp	.+42     	; 0x32 <__vector_3>
   8:	13 c0       	rjmp	.+38     	; 0x30 <__bad_interrupt>
   a:	12 c0       	rjmp	.+36     	; 0x30 <__bad_interrupt>
   c:	11 c0       	rjmp	.+34     	; 0x30 <__bad_interrupt>
   e:	10 c0       	rjmp	.+32     	; 0x30 <__bad_interrupt>
  10:	0f c0       	rjmp	.+30     	; 0x30 <__bad_interrupt>
  12:	0e c0       	rjmp	.+28     	; 0x30 <__bad_interrupt>

00000014 <__ctors_end>:
  14:	11 24       	eor	r1, r1
  16:	1f be       	out	0x3f, r1	; 63
  18:	cf e9       	ldi	r28, 0x9F	; 159
  1a:	cd bf       	out	0x3d, r28	; 61

0000001c <__do_clear_bss>:
  1c:	20 e0       	ldi	r18, 0x00	; 0
  1e:	a0 e6       	ldi	r26, 0x60	; 96
  20:	b0 e0       	ldi	r27, 0x00	; 0
  22:	01 c0       	rjmp	.+2      	; 0x26 <.do_clear_bss_start>

00000024 <.do_clear_bss_loop>:
  24:	1d 92       	st	X+, r1

00000026 <.do_clear_bss_start>:
  26:	a1 36       	cpi	r26, 0x61	; 97
  28:	b2 07       	cpc	r27, r18
  2a:	e1 f7       	brne	.-8      	; 0x24 <.do_clear_bss_loop>
  2c:	13 d0       	rcall	.+38     	; 0x54 <main>
  2e:	56 c0       	rjmp	.+172    	; 0xdc <_exit>

00000030 <__bad_interrupt>:
  30:	e7 cf       	rjmp	.-50     	; 0x0 <__vectors>

00000032 <__vector_3>:
 
 volatile uint8_t pulse_high = 0;     // "Второй разряд" счетчика (количество переполнений Timer0)
 
 // Обработчик прерывания переполнения Timer0
 ISR(TIM0_OVF_vect)
 {
  32:	1f 92       	push	r1
  34:	0f 92       	push	r0
  36:	0f b6       	in	r0, 0x3f	; 63
  38:	0f 92       	push	r0
  3a:	11 24       	eor	r1, r1
  3c:	8f 93       	push	r24
     pulse_high++; // Инкрементируем старший разряд счетчика
  3e:	80 91 60 00 	lds	r24, 0x0060	; 0x800060 <__DATA_REGION_ORIGIN__>
  42:	8f 5f       	subi	r24, 0xFF	; 255
  44:	80 93 60 00 	sts	0x0060, r24	; 0x800060 <__DATA_REGION_ORIGIN__>
 }
  48:	8f 91       	pop	r24
  4a:	0f 90       	pop	r0
  4c:	0f be       	out	0x3f, r0	; 63
  4e:	0f 90       	pop	r0
  50:	1f 90       	pop	r1
  52:	18 95       	reti

00000054 <main>:
 int main(void)
 {
     // Настраиваем пины:
     // PB1 - вход для внешнего тактового сигнала Timer0 (подключается непосредственно к внешнему импульсному генератору)
     // PB0 - выход для сброса (по умолчанию high-Z, используется как "открытый коллектор")
     DDRB &= ~(1 << PB1);  // PB1 как вход
  54:	b9 98       	cbi	0x17, 1	; 23
     DDRB &= ~(1 << PB0);  // PB0 как вход
  56:	b8 98       	cbi	0x17, 0	; 23

     OSCCAL = 127;
  58:	8f e7       	ldi	r24, 0x7F	; 127
  5a:	81 bf       	out	0x31, r24	; 49
 
     // Настройка Timer0:
     // Режим нормальный, внешний тактовый сигнал (восходящий фронт) через TCCR0B = 0b00000111.
     // Это позволяет таймеру считать внешние импульсы, поступающие на PB1.
     TCCR0A = 0;
  5c:	1f bc       	out	0x2f, r1	; 47
     TCCR0B = 0b00000111;
  5e:	87 e0       	ldi	r24, 0x07	; 7
  60:	83 bf       	out	0x33, r24	; 51
 
     // Разрешаем прерывание переполнения Timer0
     TIMSK0 |= (1 << TOIE0);
  62:	89 b7       	in	r24, 0x39	; 57
  64:	82 60       	ori	r24, 0x02	; 2
  66:	89 bf       	out	0x39, r24	; 57
__attribute__ ((__always_inline__))
void wdt_enable (const uint8_t value)
{
	if (_SFR_IO_REG_P (_WD_CONTROL_REG))
	{
		__asm__ __volatile__ (
  68:	88 e1       	ldi	r24, 0x18	; 24
  6a:	9e e0       	ldi	r25, 0x0E	; 14
  6c:	0f b6       	in	r0, 0x3f	; 63
  6e:	f8 94       	cli
  70:	a8 95       	wdr
  72:	81 bd       	out	0x21, r24	; 33
  74:	0f be       	out	0x3f, r0	; 63
  76:	91 bd       	out	0x21, r25	; 33
 
     wdt_enable(WDTO_1S);  // Включаем watchdog (~1 сек)
     sei();                // Глобально разрешаем прерывания
  78:	78 94       	sei
 
     while (1)
     {
         wdt_reset();                     // Сброс watchdog
  7a:	a8 95       	wdr
	#else
		//round up by default
		__ticks_dc = (uint32_t)(ceil(fabs(__tmp)));
	#endif

	__builtin_avr_delay_cycles(__ticks_dc);
  7c:	2f ef       	ldi	r18, 0xFF	; 255
  7e:	87 eb       	ldi	r24, 0xB7	; 183
  80:	9b e0       	ldi	r25, 0x0B	; 11
  82:	21 50       	subi	r18, 0x01	; 1
  84:	80 40       	sbci	r24, 0x00	; 0
  86:	90 40       	sbci	r25, 0x00	; 0
  88:	e1 f7       	brne	.-8      	; 0x82 <main+0x2e>
  8a:	00 c0       	rjmp	.+0      	; 0x8c <main+0x38>
  8c:	00 00       	nop
         _delay_ms(POST_EVENT_DELAY_MS);  // Задержка после сброса или старта
 
         // Сброс счетчика: обнуляем "старший разряд" и сам Timer0
         pulse_high = 0;
  8e:	10 92 60 00 	sts	0x0060, r1	; 0x800060 <__DATA_REGION_ORIGIN__>
         TCNT0 = 0;
  92:	12 be       	out	0x32, r1	; 50
  94:	2f ef       	ldi	r18, 0xFF	; 255
  96:	87 eb       	ldi	r24, 0xB7	; 183
  98:	9b e0       	ldi	r25, 0x0B	; 11
  9a:	21 50       	subi	r18, 0x01	; 1
  9c:	80 40       	sbci	r24, 0x00	; 0
  9e:	90 40       	sbci	r25, 0x00	; 0
  a0:	e1 f7       	brne	.-8      	; 0x9a <main+0x46>
  a2:	00 c0       	rjmp	.+0      	; 0xa4 <__stack+0x5>
  a4:	00 00       	nop
 
         _delay_ms(MEASURE_PERIOD_MS);    // Измерительный интервал
 
         // Считываем общее число импульсов: (pulse_high << 8) | TCNT0
         cli();
  a6:	f8 94       	cli
         uint16_t pulses = ((uint16_t)pulse_high << 8) | TCNT0;
  a8:	80 91 60 00 	lds	r24, 0x0060	; 0x800060 <__DATA_REGION_ORIGIN__>
  ac:	92 b7       	in	r25, 0x32	; 50
         sei();
  ae:	78 94       	sei
 
         _delay_ms(MEASURE_PERIOD_MS);    // Измерительный интервал
 
         // Считываем общее число импульсов: (pulse_high << 8) | TCNT0
         cli();
         uint16_t pulses = ((uint16_t)pulse_high << 8) | TCNT0;
  b0:	89 27       	eor	r24, r25
  b2:	98 27       	eor	r25, r24
  b4:	89 27       	eor	r24, r25
         sei();
 
         // Если число импульсов вне допустимого диапазона, инициируем сброс внешнего устройства
         if (pulses < MIN_PULSES || pulses > MAX_PULSES)
  b6:	80 59       	subi	r24, 0x90	; 144
  b8:	91 40       	sbci	r25, 0x01	; 1
  ba:	81 31       	cpi	r24, 0x11	; 17
  bc:	9e 40       	sbci	r25, 0x0E	; 14
  be:	e8 f2       	brcs	.-70     	; 0x7a <main+0x26>
         {
             DDRB |= (1 << PB0);    // Переводим PB0 в режим выхода
  c0:	b8 9a       	sbi	0x17, 0	; 23
             PORTB &= ~(1 << PB0);  // Выводим 0 (сброс)
  c2:	c0 98       	cbi	0x18, 0	; 24
  c4:	8f ef       	ldi	r24, 0xFF	; 255
  c6:	9d ee       	ldi	r25, 0xED	; 237
  c8:	22 e0       	ldi	r18, 0x02	; 2
  ca:	81 50       	subi	r24, 0x01	; 1
  cc:	90 40       	sbci	r25, 0x00	; 0
  ce:	20 40       	sbci	r18, 0x00	; 0
  d0:	e1 f7       	brne	.-8      	; 0xca <__stack+0x2b>
  d2:	00 c0       	rjmp	.+0      	; 0xd4 <__stack+0x35>
  d4:	00 00       	nop
             _delay_ms(RESET_PULSE_WIDTH_MS);
             DDRB &= ~(1 << PB0);   // Возвращаем PB0 в режим high-Z
  d6:	b8 98       	cbi	0x17, 0	; 23
             PORTB &= ~(1 << PB0);
  d8:	c0 98       	cbi	0x18, 0	; 24
  da:	cf cf       	rjmp	.-98     	; 0x7a <main+0x26>

000000dc <_exit>:
  dc:	f8 94       	cli

000000de <__stop_program>:
  de:	ff cf       	rjmp	.-2      	; 0xde <__stop_program>
