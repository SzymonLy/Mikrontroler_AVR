#include "stdint.h"
#include <stdio.h>
//#include "avr/io.h"
#include "sfr_defs.h"
#include "common.h"
#include "avr/pgmspace.h"
//#include <stdio.h>
#include "interrupt.h"
#undef F_CPU
#define F_CPU 25000000UL
#include "util/delay.h"
#include "functions_cpu.h"
#include <util/delay.h>

#define TempH_addr      66
#define TempL_addr      65
#define MPU6050_addr   0x68
#define MPU9250_addr   0x68

#define SPI 2
#define UART 0
#define I2C 1
#define PWM 3


/* Interrupt test
int main(void){   
    _delay_us(10);
    select_interface(0, 4);
    clear_dpu_from_cpu_transmision();
    add_dpu_from_cpu_transmision(0);
    uint8_t data_to_send = 1;
    send_data_from_cpu_to_interface(data_to_send);
    //allow_mes_from_dpus(); 
    sei(); // enable global interrupts
    while(1);
}

ISR(INTER_MESS_FROM_DPU)
{
    uint8_t data;
    data = DPU0;
    data = data + 1;
	send_byte_to_user(data);
    _delay_us(1);
    send_data_from_cpu_to_interface(data);
    allow_mes_from_dpus(); // after every interrupt this function has to be writed. It allow another interrupt from dpu
    sei();
}
*/
//uint8_t i;
// pwm and multiplexer test
//int main(void){   
//    i= 1;
//    //_delay_us(10);
//    connect_interface(0, 1); 
//    // additional test
//    connect_interface(1, 11);
//    connect_interface(2, 12);
//    connect_interface(3, 13);
//    
//    clear_dpu_from_cpu_transmision();
//    add_dpu_from_cpu_transmision(0);
//    send_data_from_cpu_to_interface(i);
//    //allow_mes_from_dpus(); 
//    sei(); // enable global interrupts
//    while(1);
//}
//
//ISR(INTER_MESS_FROM_DPU)
//{
//    i =  i + 1;
//    if (i >16) {
//        i=0;
//    }
//	//send_byte_to_user(data);
//    _delay_us(10);
//    send_data_from_cpu_to_interface(i);
//    allow_mes_from_dpus(); // after every interrupt this function has to be writed. It allow another interrupt from dpu
//    sei();
//}

//	constant UARTS 			: integer := 2;
//	constant I2CS 			: integer := 4;--2, 3, 4, 5
//	constant SPIS 			: integer := 2; 6, 7
//	constant PWMS			: integer := 8; 8, 9...

int main(void){   
    // DPU 0
    connect_interface(0, 2); //DPU 0, interface 2
    clear_dpu_from_cpu_transmision();
    add_dpu_from_cpu_transmision(0);
    send_data_from_cpu_to_interface(4);
    send_data_from_cpu_to_interface(I2C);
    send_data_from_cpu_to_interface(MPU6050_addr);
    send_data_from_cpu_to_interface(TempL_addr);
    send_data_from_cpu_to_interface(TempH_addr);
    dpu_interrupt();
    // DPU 1
    connect_interface(1, 3);
    clear_dpu_from_cpu_transmision();
    add_dpu_from_cpu_transmision(1);
    send_data_from_cpu_to_interface(4);
    send_data_from_cpu_to_interface(I2C);
    send_data_from_cpu_to_interface(MPU6050_addr);
    send_data_from_cpu_to_interface(TempL_addr);
    send_data_from_cpu_to_interface(TempH_addr);
    dpu_interrupt();
    //DPU 2
    connect_interface(2, 4);
    clear_dpu_from_cpu_transmision();
    add_dpu_from_cpu_transmision(2);
    send_data_from_cpu_to_interface(4);
    send_data_from_cpu_to_interface(I2C);
    send_data_from_cpu_to_interface(MPU9250_addr);
    send_data_from_cpu_to_interface(TempL_addr);
    send_data_from_cpu_to_interface(TempH_addr);
    dpu_interrupt();
    //DPU 3
    connect_interface(3, 5);
    clear_dpu_from_cpu_transmision();
    add_dpu_from_cpu_transmision(3);
    send_data_from_cpu_to_interface(4);
    send_data_from_cpu_to_interface(I2C);
    send_data_from_cpu_to_interface(MPU9250_addr);
    send_data_from_cpu_to_interface(TempL_addr);
    send_data_from_cpu_to_interface(TempH_addr);
    dpu_interrupt();
    
   // DPU 4
    connect_interface(4, 8);
    clear_dpu_from_cpu_transmision();
    add_dpu_from_cpu_transmision(4);
    send_data_from_cpu_to_interface(9);
    send_data_from_cpu_to_interface(3);
    uint32_t pwm_duty = 0x500;
    uint32_t pwm_freq = 0x1000;
    send_data_from_cpu_to_interface(9);
    send_data_from_cpu_to_interface(PWM);
    send_4_bytes_from_cpu_to_interface(pwm_duty);
    send_4_bytes_from_cpu_to_interface(pwm_freq);
    dpu_interrupt();
    clear_dpu_from_cpu_transmision();
    allow_mes_from_dpus(); 
    sei(); // enable global interrupts
    while(1);
}

ISR(INTER_MESS_DPU_0){
 uint8_t data;
    data = DPU0;
    if (data > max_temp) {
        max_temp = data;
        char tekst[] = sprintf("Maks temperatura wynosi %d C z interfejsu 0", max_temp);
        send_data_to_user(tekst, strlen(tekst));
        send_byte_to_user(data);

        add_dpu_from_cpu_transmision(4);
        uint32_t pwm_duty = max_temp*50;
        uint32_t pwm_freq = 5000; // 100us/20ns
        send_data_from_cpu_to_interface(9);
        send_data_from_cpu_to_interface(PWM);
        send_4_bytes_from_cpu_to_interface(pwm_duty);
        send_4_bytes_from_cpu_to_interface(pwm_freq);
        dpu_interrupt();
    }
    allow_mes_from_dpus(); 
    sei();
}
ISR(INTER_MESS_DPU_1){
    uint8_t data;
    data = DPU1;
    char tekst[] = "DPU nr. 1- ";
    //send_data_to_user(tekst, strlen(tekst));
     send_byte_to_user(2);
	send_byte_to_user(data);
    allow_mes_from_dpus(); 
    sei();
}
ISR(INTER_MESS_DPU_2){
    uint8_t data;
    data = DPU2;
    send_byte_to_user(3);
    char tekst[] = "Dane z DPU nr. 0- ";
    //send_data_to_user(tekst, strlen(tekst));
	send_byte_to_user(data);
    allow_mes_from_dpus(); 
    sei();
}
ISR(INTER_MESS_DPU_3){
    uint8_t data;
    data = DPU3;
     send_byte_to_user(4);
//    char tekst[] = "Dane z DPU nr. 1- ";
    //send_data_to_user(tekst, strlen(tekst));
	send_byte_to_user(data);
    allow_mes_from_dpus(); 
    sei();
}
//
//ISR(INTER_MESS_USER){
//    uint8_t data;
//    data = READ_RX_DATA;
//    send_byte_to_user(6);
//	send_byte_to_user(data);
//    send_byte_to_user(7);
//    allow_mes_from_dpus(); 
//    sei();
//}