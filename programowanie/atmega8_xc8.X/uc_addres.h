/* 
 * File:   uc_addres.h
 * Author: Szymo
 *
 * Created on April 25, 2024, 2:51)PM
 */

#ifndef UC_ADDRES_H
#define	UC_ADDRES_H

#ifdef	__cplusplus
extern "C" {
#endif




#ifdef	__cplusplus
}
#endif

// read addresses by CPU
#define DPU0	_SFR_IO8(0x01)
#define DPU1	_SFR_IO8(0x02)
#define DPU2	_SFR_IO8(0x03)
#define DPU3	_SFR_IO8(0x04)
#define DPU4	_SFR_IO8(0x05)
#define DPU5	_SFR_IO8(0x06)
#define DPU6	_SFR_IO8(0x07)
#define DPU7	_SFR_IO8(0x08)

#define READ_RX_DATA	_SFR_IO8(0x00)


// multiplexer
#define INT_SELECT_1                _SFR_IO8(0b00000011)
#define INT_SELECT_2                _SFR_IO8(0b00000001)
#define INT_DESELECT_1              _SFR_IO8(0b00000111)
#define INT_DESELECT_2              _SFR_IO8(0b00000101)

// INTERRUPTS
// To DPU
#define INTER_MESS_TO_CPU_NOT_SENT          _VECTOR(1)
#define INTER_MESS_ABLE_TO_SENT             _VECTOR(2)
#define INTER_MESS_FROM_CPU                 _VECTOR(3)
#define INTER_READ_INTERFACE                _VECTOR(4)
// to CPU
#define INTER_MESS_USER             _VECTOR(1)
//#define INTER_MESS_BUTTON           _VECTOR(2)
#define INTER_MESS_DPU_0            _VECTOR(2)
#define INTER_MESS_DPU_1            _VECTOR(3)
#define INTER_MESS_DPU_2            _VECTOR(4)
#define INTER_MESS_DPU_3            _VECTOR(5)
#define INTER_MESS_DPU_4            _VECTOR(6)
#define INTER_MESS_DPU_5            _VECTOR(7)
#define INTER_MESS_DPU_6            _VECTOR(8)
#define INTER_MESS_DPU_7            _VECTOR(9)
#define INTER_MESS_DPU_8            _VECTOR(10)
#define INTER_MESS_DPU_9            _VECTOR(11)
#define INTER_MESS_DPU_10            _VECTOR(12)
#define INTER_MESS_DPU_11           _VECTOR(13)
#define INTER_MESS_DPU_12            _VECTOR(14)
#define INTER_MESS_DPU_13           _VECTOR(15)
#define INTER_MESS_DPU_14           _VECTOR(16)
#define INTER_MESS_DPU_15           _VECTOR(17)


// addres to allow next interrupt
#define CPU_ALLOW_MES_FROM_DPUS     _SFR_IO8(0b00001001)
            
#define SEND_DATA_TO_USER           _SFR_IO8(0b00010000)

// DPU
#define SELECT_MUL_DATA             _SFR_IO8(0b00000000)
#define SELECT_CPU_DATA             _SFR_IO8(0b00000001)
    
#define INT_DATA_IN                 _SFR_IO8(0b00011111)
#define INT_SENDING_MODE            _SFR_IO8(0b00011110)
#define INT_SET_INTT                _SFR_IO8(0b00011101)
#define INT_READ_DATA               _SFR_IO8(0b00011100)
#define INT_READ_MEMORY_STATUS      _SFR_IO8(0b00011011)
#define INT_READ_CURRENT_STATUS     _SFR_IO8(0b00011001)
#define INT_READ_RX_STACK_HEAD      _SFR_IO8(0b00011010)

#define DPU_WRITE_SEL               _SFR_IO8(0b00011111)
#define DPU_WRITE_DATA              _SFR_IO8(0b00011110)
#define DPU_WRITE_REMOVE            _SFR_IO8(0b00011101)
#define DPU_WRITE_CLEAR             _SFR_IO8(0b00011100)
#define  DPU_INTERRUPT              _SFR_IO8(0b00011011)
#define DPU_WRITE_GPIO             _SFR_IO8(0b00011010)
#define  DPU_WRITE_LED              _SFR_IO8(0b00011000)

#define WRITE_TO_CPU                _SFR_IO8(0b00010111)
#define SELECT_DATA_TO_CPU          _SFR_IO8(0b00010110)
#define WRITE_DATA_TO_CPU           _SFR_IO8(0b00001001)
#define SEND_DATA_TO_USER           _SFR_IO8(0b00010000)


#define UART_BAUD_RATE              _SFR_IO8(0b00001110)
#define UART_PARITY_BIT             _SFR_IO8(0b00001101)
#define UART_LENGHT                 _SFR_IO8(0b00001100)
#define UART_STOP_BITS              _SFR_IO8(0b00001011)
#define UART_FLOW_CONTROL           _SFR_IO8(0b00001010)

#define SPI_CPOL_SELECT             _SFR_IO8(0b00001110)
#define SPI_CPHA_SELECT             _SFR_IO8(0b00001101)
#define SPI_CONT_SELECT             _SFR_IO8(0b00001100)
#define SPI_CLK_DIV_LOW          _SFR_IO8(0b00001011)
#define SPI_CLK_DIV_HIGH          _SFR_IO8(0b00001001)
#define SPI_ADDRES_SELECT           _SFR_IO8(0b00001010)

#define I2C_UPPER_ADDR              _SFR_IO8(0b00001110)
#define I2C_LOWER_ADDR              _SFR_IO8(0b00001101)//first 8 bits
#define I2C_READ_WRITE              _SFR_IO8(0b00001100)
#define I2C_CLK_DIV_LOW          _SFR_IO8(0b00001011)
#define I2C_CLK_DIV_HIGH         _SFR_IO8(0b00001001)
#define I2C_CONT_MODE_SEL           _SFR_IO8(0b00001010)

#define PWM_DUTY_HIGH               _SFR_IO8(0b00001110)
#define PWM_DUTY_LOW                _SFR_IO8(0b00001101)//first 8 bits
#define PWM_FREQ_DIV_HIGH           _SFR_IO8(0b00001100)
#define PWM_FREQ_DIV_LOW            _SFR_IO8(0b00001011)
#define PWM_ENABLE                  _SFR_IO8(0b00001010)

// Interface modes, selected by data 
#define INT_SINGLE_MODE             0
#define INT_CONTINUE_MODE           1
#define INT_INTT_START_MODE         2
#define INT_INTT_WAIT_MODE          3
#define INT_RESET_MODE              4
#define INT_BIT_SEND_MODE           5

#endif	/* UC_ADDRES_H */

