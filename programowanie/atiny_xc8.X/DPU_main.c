#include "stdint.h"
//#include "avr/io.h"
#include "myAtmega8.h"
#include "avr/pgmspace.h"

#undef F_CPU
#define F_CPU 25000000UL
#include "util/delay.h"
#include "functions_dpu.h"
#include "interrupt.h"

uint8_t data;
#define ERROR 44
#define MESSAGE 55
#define MAX_TEMPERATURE 30
#define Addres1 0x68
#define Addres2 0x69

#define SPI 2
#define UART 0
#define I2C 1
#define PWM 3

uint8_t mes[16];
int main(void)
{   
    //send_byte_to_user(0xAA);
    sei(); 
    while(1);
}

// I2C test
//ISR(INTER_MESS_FROM_CPU){
//    uint8_t data1 = SELECT_CPU_DATA;
//    Interface_initiation();
//    I2C_inintiation(data1); 
//    uint8_t sending_reg = 117;
//    //send_data_to_cpu(sending_reg)
//    I2C_read();
//    //send_data_to_cpu(data1);
//    sei();
//}

//UART test
//ISR(INTER_MESS_FROM_CPU){
//    uint8_t data1 = SELECT_CPU_DATA;
//    UART_initiation(0x85);
//    send_byte_to_interface(data1);
//    send_byte_to_interface(data1+1);
//    send_byte_to_interface(data1+2);
//    sei();
//}
//full test


//uint8_t mes[16];
uint8_t i;
uint8_t addres;
uint8_t interface_select;
uint16_t freq;
uint32_t pwm_duty, pwm_freq;
uint8_t read_addres1, read_addres2;
uint8_t read_byte_n;

ISR(INTER_MESS_FROM_CPU){
    uint8_t mes_len;
    mes_len = SELECT_CPU_DATA;
    mes_len = mes_len - 1;
    uint8_t mes[16];
    uint8_t i;
    uint8_t addres;
    uint16_t freq;
    uint32_t pwm_duty, pwm_freq;

    interface_select = SELECT_CPU_DATA;
    i=1;
//    while (i<mes_len){
//        mes[i] = SELECT_CPU_DATA;
//        i++;
//    }
    if (interface_select== UART){
        UART_initiation(0x85);
        i=1;
        uint8_t data_to_send;
        while  (i<mes_len){
            data_to_send = SELECT_CPU_DATA;
             send_byte_to_interface(data_to_send);
             i++;
        }
    }else if (interface_select ==  I2C){
        addres = 0x68;
         uint8_t dumb = SELECT_CPU_DATA;
        freq = 0x116E;
        I2C_inintiation(addres, freq);
//        if (mes_len >4) {
//            I2C_write();
//             send_byte_to_interface(mes[4]);
//        }
        read_addres1 = SELECT_CPU_DATA;
        read_addres2 = SELECT_CPU_DATA;
       
        I2C_write();
        send_byte_to_interface(read_addres1);
        I2C_read();
        read_byte_n = 0;
    }else if (interface_select ==  SPI){
        read_addres1 = SELECT_CPU_DATA;
        read_addres2 = SELECT_CPU_DATA;
        freq = 0x1B6E;
        SPI_initiation(addres, freq);
        i = 1;
        send_byte_to_interface(read_addres1);
        i++;
    }else if (interface_select ==  PWM){
        if (mes_len == 9) {
            pwm_duty = mes[1]<<24||mes[2]<<16||mes[3]<<8||mes[4];
            pwm_freq = mes[5]<<24||mes[6]<<16||mes[7]<<8||mes[8];
            PWM_write_data(pwm_duty, pwm_freq);
        }
    }else{
        send_data_to_cpu(ERROR);
    }
    sei();
}


int16_t temperature;
int16_t temperature100;
ISR(INTER_READ_INTERFACE){
    uint8_t mes_len;
    uint8_t read_data = SELECT_MUL_DATA; 
    mes_len = SELECT_CPU_DATA;
    if (interface_select == 1){ 
        if (read_byte_n == 0){
            read_byte_n = 1;
            temperature = read_data;
            I2C_write();
            send_byte_to_interface(read_addres2);
            I2C_read();
        } else {
            read_byte_n = 0;
            temperature = read_data<<8||temperature;
            temperature100 = temperature/3.4 + 3653;
            if (temperature100 > MAX_TEMPERATURE*100 ){
                send_data_to_cpu(MESSAGE);
            }
            I2C_write();
            send_byte_to_interface(read_addres1);
            I2C_read();
        }
    }else if (interface_select == 2){
        if (read_byte_n == 0){
            read_byte_n = 1;
            temperature = read_data;
            send_byte_to_interface(read_addres2);
        } else {
            read_byte_n = 0;
            temperature = read_data<<8||temperature;
            temperature100 = temperature/3.4 + 3653;
            if (temperature100 > MAX_TEMPERATURE*100 ){
                send_data_to_cpu(MESSAGE);
            }
            send_byte_to_interface(read_addres1);
        }
    }
}


ISR(INTER_MESS_TO_CPU_NOT_SENT)
{
    sei();
}

ISR(INTER_MESS_ABLE_TO_SENT)
{
    //send_data_to_cpu(readed_data);
    sei();
}


//PWM_write_data(4608, 9216);