/* 
 * File:   functions_cpu.h
 * Author: Szymo
 *
 * Created on May 9, 2024, 3:57 PM
 */

#ifndef FUNCTIONS_CPU_H
#define	FUNCTIONS_CPU_H

#ifdef	__cplusplus
extern "C" {
#endif

#include "uc_addres.h"
#include <string.h>
    // 4 uarts - 0, 1, 2, 3
// 2 i2c- 4, 5
// 2 spi - 6, 7
// 4 pwms - 8, 9, 10, 11
// to use by cpu:

void connect_interface( uint8_t dpu_number, uint8_t interface_number) {
    // 3 bits dpu_number, 5 bits interface_number
    uint8_t sending_data;
    sending_data = (dpu_number << 5) | interface_number;
    if (dpu_number<8){
        INT_SELECT_2 = sending_data;
    }else{
        INT_SELECT_1 = sending_data;
    }
}
void disconnect_interface( uint8_t dpu_number, uint8_t interface_number) {
       uint8_t sending_data;
    sending_data = (dpu_number << 5) | interface_number;
    if (dpu_number<8){
        INT_DESELECT_2 = sending_data;
    }else{
        INT_DESELECT_1 = sending_data;
    }
}
void dpu_interrupt(){
    DPU_INTERRUPT = 1;
}
void add_dpu_from_cpu_transmision(uint8_t dpu){
    DPU_WRITE_SEL = dpu;
}
void remove_dpu_from_cpu_transmision(uint8_t dpu){
    DPU_WRITE_REMOVE = dpu;
}
void clear_dpu_from_cpu_transmision(){
    DPU_WRITE_CLEAR = 0;// can be any number
}
void send_data_from_cpu_to_interface(uint8_t data){
    DPU_WRITE_DATA = data;
}
void send_4_bytes_from_cpu_to_interface(uint32_t data){
    uint8_t pwm_array[4];
    pwm_array[3] = data>>24;
    pwm_array[2] = data>>16;
    pwm_array[1] = data>>8;
    pwm_array[0] = data;
    send_data_from_cpu_to_interface(pwm_array[0]);
    send_data_from_cpu_to_interface(pwm_array[1]);
    send_data_from_cpu_to_interface(pwm_array[2]);
    send_data_from_cpu_to_interface(pwm_array[3]);
}

void set_gpio(uint8_t gpio){
    DPU_WRITE_GPIO  = gpio<<1 | 1;
}
void clear_gpio(uint8_t gpio){
    DPU_WRITE_GPIO  = gpio<<1 | 0;
}

void set_led(uint8_t led){
    DPU_WRITE_GPIO  = led<<1 | 1;
}
void clear_led(uint8_t led){
    DPU_WRITE_GPIO  = led<<1 | 0;
}

void select_data_to_cpu_from_interface(uint8_t dpu){
    SELECT_DATA_TO_CPU  = dpu;
}
// Warning. This function clears existing comunication with cpu
void send_data_to_1_dpu(uint8_t dpu, uint8_t data){
    clear_dpu_from_cpu_transmision();
    add_dpu_from_cpu_transmision(dpu);
    send_data_from_cpu_to_interface(data);
}
void allow_mes_from_dpus(){
    sei(); // enable global interrupts
    CPU_ALLOW_MES_FROM_DPUS = 0;
}


void send_data_to_user(char data[], uint8_t len){
    uint8_t i;
    i = len;
    while(i>0){
        SEND_DATA_TO_USER = data[len-i];
        i = i-1;
    }  
}

void send_byte_to_user(uint8_t data){
    SEND_DATA_TO_USER = data;
}

#ifdef	__cplusplus
}
#endif

#endif	/* FUNCTIONS_CPU_H */

