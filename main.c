/**
 * @file main.c
 * @brief Компактная программа для ATtiny13A с подсчетом импульсов через Timer0.
 *
 * Измеряет число внешних импульсов на PB1 (внешний тактовый вход Timer0) за интервал MEASURE_PERIOD_MS.
 * Если итоговое число импульсов (учитывая переполнения 8-битного таймера) меньше MIN_PULSES или больше MAX_PULSES,
 * и на PB4 высокий уровень, генерируется сброс внешнего устройства через PB0 (открытый коллектор).
 */

#define F_CPU (9600000UL)

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <avr/wdt.h>

#define MEASURE_PERIOD_MS    500U  ///< Интервал измерения импульсов (мс)
#define POST_EVENT_DELAY_MS  500U ///< Задержка после сброса или старта (мс)
#define RESET_PULSE_WIDTH_MS 100U  ///< Длительность сбросного импульса (мс)

#define MIN_FREQ             100U   ///< Минимальное число импульсов в секунду
#define MAX_FREQ             20000U ///< Максимальное число импульсов в секунду

#define MIN_PULSES           ((MIN_FREQ * MEASURE_PERIOD_MS) / 1000U)
#define MAX_PULSES           ((MAX_FREQ * MEASURE_PERIOD_MS) / 1000U)

#define MAX_DELAY_MS         1U ///< Максимально допустимая задержка за один вызов my_delay()

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
    for (uint16_t i = 0; i < ms / MAX_DELAY_MS; i++) _delay_ms(MAX_DELAY_MS);
}

ISR(TIM0_COMPA_vect)
{
    pulse_high++;
    TCNT0 = 0;
}

int main(void)
{
    // Настройка портов:
    // PB2 — вход для внешнего тактирования (T0)
    // PB0 — выход сброса (открытый коллектор)
    // PB4 — вход с подтяжкой 

    DDRB &= ~(1 << PB0); // PB0 как вход (по умолчанию high-Z)
    DDRB &= ~(1 << PB4); // PB4 как вход
    DDRB |= (1 << PB3);  // PB3 как выход

    PORTB |= (1 << PB4); // Включаем подтяжку на PB4

    // Настройка таймера:
    // Режим Normal, источник — внешний сигнал на T0 (PB2), фронт — по возрастанию
    TCCR0A = 0;
    TCCR0B = 0b00000111;
    OCR0A = 64;

    TIMSK0 |= (1 << OCIE0A); // Разрешение прерывания по сравнению

    wdt_enable(WDTO_4S); // Включение watchdog
    asm volatile("sei");              // Глобальное разрешение прерываний

    my_delay(POST_EVENT_DELAY_MS); // Задержка перед измерением

    while (1) {
        wdt_reset();                   // Сброс watchdog
        

        pulse_high = 0;
        TCNT0      = 0;

        my_delay(MEASURE_PERIOD_MS); // Интервал измерения

        // Чтение значения счётчика (атомарно)
        asm volatile("cli");
        uint16_t pulses = pulse_high;
        asm volatile("sei");

        PORTB |= (1 << PB3);
        my_delay(pulses);
        PORTB &= ~(1 << PB3); // логгинг задержки

        // Проверка диапазона и сигнала на PB4
        if ((pulses < 10 || pulses > 200) && (PINB & (1 << PB4))) 
        {
            DDRB |= (1 << PB0);   // Переводим PB0 в режим выхода
            PORTB &= ~(1 << PB0); // Устанавливаем 0 (сброс)
            my_delay(pulses);
            DDRB &= ~(1 << PB0);  // Возвращаем PB0 в high-Z
            PORTB &= ~(1 << PB0); // На всякий случай обнуляем

            my_delay(POST_EVENT_DELAY_MS);
        }
    }

    return 0;
}
