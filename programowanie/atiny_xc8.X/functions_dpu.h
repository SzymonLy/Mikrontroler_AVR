/* 
 * File:   functions_dpu.h
 * Author: Szymo
 *
 * Created on May 9, 2024, 3:57 PM
 */

#ifndef FUNCTIONS_DPU_H
#define	FUNCTIONS_DPU_H

#ifdef	__cplusplus
extern "C" {
#endif
    
#include "uc_addres.h"

void send_byte_to_interface(uint8_t data){
    INT_DATA_IN = data;
}

void send_data_to_cpu(uint8_t data){
    WRITE_TO_CPU = data;
}
void I2C_inintiation(uint8_t addres, uint16_t freq){
    I2C_UPPER_ADDR = 0; // not used
    I2C_LOWER_ADDR = addres;
    I2C_READ_WRITE = 1; // write (0) to or read (1)
    I2C_CLK_DIV_LOW = freq & 0xff; // frequency of clock is 50MHz, f_sclk = f_clk/(2*i_clk_div), so clk_div = 50M/20k = 2500 = 0x9c4
    I2C_CLK_DIV_HIGH = freq>>8;
    I2C_CONT_MODE_SEL = 0;
}
void I2C_read(){
    I2C_READ_WRITE = 1; // write (0) to or read (1)
}
void I2C_write(){
    I2C_READ_WRITE = 0; // write (0) to or read (1)
}
void SPI_initiation(uint8_t addres, uint8_t freq ){
    SPI_CPOL_SELECT = 0;
    SPI_CPHA_SELECT = 0;
    SPI_CONT_SELECT = 0;
    SPI_CLK_DIV_LOW = freq & 0xff;
    SPI_CLK_DIV_HIGH = freq>>8;
    SPI_ADDRES_SELECT = addres; // first spi
}
// duty < freq
// Maksymalna cz?stotliwo?? u?ywana przez wi?kszo?? ur
void PWM_write_data(uint32_t duty, uint32_t freq){
    PWM_DUTY_HIGH = duty >> 8;
    PWM_DUTY_LOW = duty;
    PWM_FREQ_DIV_HIGH = freq>>8;
    PWM_FREQ_DIV_LOW = freq;
    PWM_ENABLE = 1;
}

void PWM_disable(){
    PWM_ENABLE = 0;
}

//void select_DPU_data_source(uint8_t data){ // 1 for cpu, 0 to multiplexer
//    switch (data) {
//      case 0:
//       SELECT_DPU_DATA=SELECT_MUL_DATA;
//        break;
//      case 1:
//       SELECT_DPU_DATA=SELECT_CPU_DATA;
//        break;
//      default:
//        SELECT_DPU_DATA=SELECT_CPU_DATA;
//    }
//}
// to use by dpu
void Interface_initiation(){
    INT_SENDING_MODE = INT_SINGLE_MODE;
   // INT_SENDING_MODE =INT_CONTINUE_MODE;
}

void UART_initiation(uint8_t baud_rate){
    //INT_SENDING_MODE = INT_SINGLE_MODE;
    UART_BAUD_RATE   = baud_rate ;    
    INT_SENDING_MODE = INT_SINGLE_MODE;
    UART_PARITY_BIT  = 0;     
    UART_LENGHT      = 8;  
    UART_STOP_BITS   = 1;      
    UART_FLOW_CONTROL= 0; // not implemented   
    
}

#ifdef	__cplusplus
}
#endif

#endif	/* FUNCTIONS_DPU_H */

