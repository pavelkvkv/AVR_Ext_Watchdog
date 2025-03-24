/**
 * @file main.c
 * @brief Компактная программа для ATtiny13A с подсчетом импульсов через Timer0.
 *
 * Измеряет число внешних импульсов на PB1 (внешний тактовый вход Timer0) за интервал MEASURE_PERIOD_MS.
 * Если итоговое число импульсов (с учетом переполнений 8-битного таймера) меньше MIN_PULSES или больше MAX_PULSES,
 * и при этом на PB4 высокий уровень, генерируется сброс внешнего устройства через PB0 (открытый коллектор).
 * Если же в течение RESET_TIMEOUT_MS (например, 60 секунд) PB4 находится в низком уровне, также выполняется сброс.
 */

 #define F_CPU (9600000UL)

 #include <avr/io.h>
 #include <avr/interrupt.h>
 #include <util/delay.h>
 #include <avr/wdt.h>
 
 #define MEASURE_PERIOD_MS    500UL     ///< Интервал измерения импульсов (мс)
 #define POST_EVENT_DELAY_MS  500UL     ///< Задержка после сброса или старта (мс)
 #define RESET_PULSE_WIDTH_MS 100UL     ///< Длительность сбросного импульса (мс)
 #define RESET_TIMEOUT_MS     10000UL  ///< Время (мс), в течение которого PB4 должен быть низким для инициирования сброса
 
 #define MIN_FREQ             1500UL     ///< Минимальное число импульсов в секунду
 #define MAX_FREQ             20000UL   ///< Максимальное число импульсов в секунду
 
 #define MIN_PULSES           ((MIN_FREQ * MEASURE_PERIOD_MS) / 100000UL)  ///< Минимальное число импульсов за интервал измерения
 #define MAX_PULSES           ((MAX_FREQ * MEASURE_PERIOD_MS) / 100000UL)  ///< Максимальное число импульсов за интервал измерения
 
 #define MAX_DELAY_MS         1U       ///< Максимально допустимая задержка за один вызов my_delay()
 
 volatile uint16_t pulse_high = 0; ///< Старший разряд счётчика (переполнения таймера)
 
 /**
  * @brief Задержка на указанное количество миллисекунд.
  *
  * Делит задержку на шаги не более MAX_DELAY_MS.
  *
  * @param[in] ms Время задержки в миллисекундах.
  */
 void my_delay(int16_t ms)
 {
     for (uint16_t i = 0; i < ms / MAX_DELAY_MS; i++)
     {
         _delay_ms(MAX_DELAY_MS);
     }
 }
 
 /**
  * @brief Обработчик прерывания таймера по сравнению OCR0A.
  *
  * Увеличивает счётчик переполнения таймера и сбрасывает значение TCNT0.
  */
 ISR(TIM0_COMPA_vect)
 {
     pulse_high++;
     TCNT0 = 0;
 }
 
 int main(void)
 {
     uint16_t lowPB4_counter = 0; ///< Счётчик времени низкого уровня на PB4
 
     // Настройка портов:
     // PB2 — вход для внешнего тактирования (T0)
     // PB0 — выход сброса (открытый коллектор)
     // PB4 — вход с подтяжкой
     // PB3 — диагностический выход
 
     DDRB &= ~(1 << PB0); // PB0 как вход (по умолчанию high-Z)
     DDRB &= ~(1 << PB4); // PB4 как вход
     DDRB |= (1 << PB3);  // PB3 как выход
 
     PORTB |= (1 << PB4); // Включаем подтяжку на PB4
 
     // Настройка таймера:
     // Режим Normal, источник — внешний сигнал на T0 (PB2), фронт — по возрастанию
     TCCR0A = 0;
     TCCR0B = 0b00000111; // Внешнее тактирование с делителем, настройка на фронт по возрастанию
     OCR0A = 99;         // Значение сравнения для деления частоты
 
     TIMSK0 |= (1 << OCIE0A); // Разрешение прерывания по сравнению
 
     wdt_enable(WDTO_4S); // Включение watchdog
     asm volatile("sei"); // Глобальное разрешение прерываний
 
     my_delay(POST_EVENT_DELAY_MS); // Задержка перед измерением
 
     while (1)
     {
         wdt_reset(); // Сброс watchdog
 
         pulse_high = 0;
         TCNT0 = 0;
 
         my_delay(MEASURE_PERIOD_MS); // Интервал измерения
 
         // Чтение значения счётчика (атомарно)
         asm volatile("cli");
         uint16_t pulses = pulse_high;
         asm volatile("sei");
 
         // Диагностический вывод на PB3
         PORTB |= (1 << PB3);
         my_delay(pulses);
         PORTB &= ~(1 << PB3);
         _delay_us(10);
         PORTB |= (1 << PB3);
         my_delay(MIN_PULSES);
         PORTB &= ~(1 << PB3);
         _delay_us(10);
         PORTB |= (1 << PB3);
         my_delay(MAX_PULSES);
         PORTB &= ~(1 << PB3);
 
         // Проверка состояния PB4 и корректности числа импульсов
         if (PINB & (1 << PB4))
         {
             // Если PB4 высокий, сбрасываем счётчик низкого уровня
             lowPB4_counter = 0;
 
             // Если число импульсов вне допустимого диапазона, инициируем сброс
             if (pulses < MIN_PULSES || pulses > MAX_PULSES)
             {
                 DDRB |= (1 << PB0);   // Переводим PB0 в режим выхода
                 PORTB &= ~(1 << PB0); // Устанавливаем 0 (сброс внешнего устройства)
                 my_delay(RESET_PULSE_WIDTH_MS);
                 DDRB &= ~(1 << PB0);  // Возвращаем PB0 в режим high-Z
                 PORTB &= ~(1 << PB0); // Обнуляем PB0 на всякий случай
 
                 my_delay(POST_EVENT_DELAY_MS);
             }
         }
         else
         {
             // Если PB4 низкий, увеличиваем счётчик времени низкого уровня
             lowPB4_counter++;
 
             // Если PB4 в низком состоянии в течение RESET_TIMEOUT_MS, инициируем сброс
             if (lowPB4_counter >= (RESET_TIMEOUT_MS / MEASURE_PERIOD_MS))
             {
                 DDRB |= (1 << PB0);   // Переводим PB0 в режим выхода
                 PORTB &= ~(1 << PB0); // Устанавливаем 0 (сброс внешнего устройства)
                 my_delay(RESET_PULSE_WIDTH_MS);
                 DDRB &= ~(1 << PB0);  // Возвращаем PB0 в режим high-Z
                 PORTB &= ~(1 << PB0); // Обнуляем PB0 на всякий случай
 
                 lowPB4_counter = 0; // Сбрасываем счётчик времени низкого уровня
                 my_delay(POST_EVENT_DELAY_MS);
             }
         }
     }
 
     return 0;
 }
 