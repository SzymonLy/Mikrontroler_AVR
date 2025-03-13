library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package INTERFACE_regs is

-- CONSTANTS:
	constant PROCESSORS 	: integer := 5;
	constant PROCESSORS_LOG : integer := 3;
	constant CPU_PM_SIZE_LOG : integer := 12;
	constant DPU_PM_SIZE_LOG : integer := 12;
	constant INTERFACES 	: integer := 16; -- = UARTS+I2CS+SPIS+PWMS+..
	constant SPI_MAX_SLAVE 	: integer := 2;
	constant UARTS 			: integer := 2;
	constant I2CS 			: integer := 4;--2, 3, 4
	constant SPIS 			: integer := 2;
	constant PWMS			: integer := 8;
	constant GPIOS			: integer := 3;
	
	constant UART_MEM_SIZE 	: integer := 3;
	constant I2C_MEM_SIZE 	: integer := 3;
	constant SPI_MEM_SIZE 	: integer := 3;
	constant CPU_LOG_PROG_MEM_SIZE 	: integer := 12;  
	constant DPU_LOG_PROG_MEM_SIZE 	: integer := 10; --has to be smaller than CPU_LOG_PROG_MEM_SIZE
		-- starting signal signalizing that this data is from dpu
	constant DATA_SEND_MESSEGE		: STD_LOGIC_VECTOR(15 DOWNTO 0) := x"FFFF"; 
	
-- ADDRESES USED BY CPU:
	-- multiplexer addresing
	constant INT_SELECT_1 : 				STD_LOGIC_VECTOR(4 DOWNTO 0) := "00011"; 
	constant INT_SELECT_2 : 				STD_LOGIC_VECTOR(4 DOWNTO 0) := "00001"; 
	constant INT_DESELECT_1 : 				STD_LOGIC_VECTOR(4 DOWNTO 0) := "00010"; 
	constant INT_DESELECT_2 : 				STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000"; 
	
	constant SEND_DATA_TO_USER :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "10000";--selected by cpu or dpu
	
	-- two modes of operation. Writing intterrupt or writing data to the dpu
	-- first the dpu has to be select, then new address and data is require
	constant DPU_WRITE_SEL :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11111";
	constant DPU_WRITE_DATA :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11110";
	constant DPU_WRITE_REMOVE :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11101";
	constant DPU_WRITE_CLEAR :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11100";
	constant DPU_INTERRUPT :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11011";
	constant DPU_WRITE_GPIO :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11010";
	constant DPU_WRITE_LED :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11000";
	--constant DPU_INTER_ADD :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11011";
	--constant DPU_INTER_REMOVE:	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11010";
	--constant DPU_INTER_DATA :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11001";
	--constant DPU_INTER_CLEAR :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11000";
	
	

-- ADDRESSES USED BY DPU:
	--DPU input data select
	--constant SELECT_DPU_DATA : 			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01011"; --addres
	constant SELECT_MUL_DATA : 			STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000"; --data
	constant SELECT_CPU_DATA : 			STD_LOGIC_VECTOR(4 DOWNTO 0) := "00001";
	
	constant INT_DATA_IN : 				STD_LOGIC_VECTOR(4 DOWNTO 0) := "11111"; --addresses
	constant INT_SENDING_MODE : 		STD_LOGIC_VECTOR(4 DOWNTO 0) := "11110";
	constant INT_SET_INTT :				STD_LOGIC_VECTOR(4 DOWNTO 0) := "11101";
	constant INT_READ_DATA :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "11100";
	constant INT_READ_MEMORY_STATUS :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11011";
	constant INT_READ_CURRENT_STATUS :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11001";
	constant INT_READ_RX_STACK_HEAD :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "11010";
	

	
	-- to write to cpu dpu just select an address. Its simpler because there is only one option
	constant WRITE_TO_CPU :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "10111";
	constant SELECT_DATA_TO_CPU :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "10110";
	constant WRITE_DATA_TO_CPU :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "01001";--selected by dpu
	-- DPU CAN USE IT --constant SEND_DATA_TO_USER :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "10000";--selected by cpu or dpu
	
	--constant INTER_TO_CPU :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "10110";
	constant INTER_RX_MESS :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "00001";
	constant INTER_BUTTON :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "00010";
	--constant INTER_TO_CPU :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "00011"; reserved
	
--	constant MUL_SELECT_INT0 :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "10111";
--	constant MUL_SELECT_INT1 :	STD_LOGIC_VECTOR(4 DOWNTO 0) := "10110";
--	constant INT_SELE 		:	STD_LOGIC_VECTOR(4 DOWNTO 0) := "10110";
	

		

	
	constant UART_BAUD_RATE : 			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01110"; --adresses
	constant UART_PARITY_BIT : 			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01101";
	constant UART_LENGHT : 				STD_LOGIC_VECTOR(4 DOWNTO 0) := "01100";
	constant UART_STOP_BITS : 			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01011";
	constant UART_FLOW_CONTROL :		STD_LOGIC_VECTOR(4 DOWNTO 0) := "01010";
	
	constant SPI_CPOL_SELECT :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01110";
	constant SPI_CPHA_SELECT :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01101";
	constant SPI_CONT_SELECT :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01100";
	constant SPI_CLK_DIV_SELECT :		STD_LOGIC_VECTOR(4 DOWNTO 0) := "01011";
	constant SPI_ADDRES_SELECT :		STD_LOGIC_VECTOR(4 DOWNTO 0) := "01010";
	--constant SPI_FLOW_CONTROL :		STD_LOGIC_VECTOR(4 DOWNTO 0) := "01010";
	
	constant I2C_UPPER_ADDR :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01110"; --USED TO SELECT ADDRESS MODE TO
	constant I2C_LOWER_ADDR :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01101";--FIRST 8 BITS
	constant I2C_READ_WRITE :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01100";
	constant I2C_CLK_DIV_LOW :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01011";
	constant I2C_CLK_DIV_HIGH :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01001";
	constant I2C_CONT_MODE_SEL :		STD_LOGIC_VECTOR(4 DOWNTO 0) := "01010";
	
	constant PWM_DUTY_HIGH :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01110";
	constant PWM_DUTY_LOW :				STD_LOGIC_VECTOR(4 DOWNTO 0) := "01101";
	constant PWM_FREQ_DIV_HIGH :		STD_LOGIC_VECTOR(4 DOWNTO 0) := "01100";
	constant PWM_FREQ_DIV_LOW :			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01011";
	constant PWM_ENABLE			:			STD_LOGIC_VECTOR(4 DOWNTO 0) := "01010";
	
	constant INT_SINGLE_MODE: 		STD_LOGIC_VECTOR(2 DOWNTO 0) := "000"; --data writed to INT_SENDING_MODE address
	constant INT_CONTINUE_MODE: 	STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
	constant INT_INTT_START_MODE: 	STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
	constant INT_INTT_WAIT_MODE: 	STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
	constant INT_RESET_MODE: 		STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";
	constant INT_BIT_SEND_MODE: 	STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";


--INTERUPTS
	constant INTER_RESET 				:		STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";
	-- To DPU
	constant INTER_MESS_TO_CPU_NOT_SENT :		STD_LOGIC_VECTOR(5 DOWNTO 0) := "000001";
	constant INTER_MESS_ABLE_TO_SENT 	:		STD_LOGIC_VECTOR(5 DOWNTO 0) := "000010";
	constant INTER_MESS_FROM_CPU 		:		STD_LOGIC_VECTOR(5 DOWNTO 0) := "000011";
	constant INTER_READ_INTERFACE 		:		STD_LOGIC_VECTOR(5 DOWNTO 0) := "000100"; -- from 0x01 to 0x0F depending on number of bytes interface has read
	
	-- To CPU
	constant INTER_MESS_FROM_DPU 		: 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "000101"; -- from 0x01 to 0x0F depending which dpu wants to send messege. 
	constant READ_RX_DATA 				: 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000"; -- 
	-- READ addres data by the CPU
	constant READ_RX_DATA_ADDRES 		: 		STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000"; -- 
	-- if more than 1 dpu wants to send a messege to cpu, the lowest one send it and higher ones receive an interrupt
	-- after receiving a message the CPU has to send a messege informing, that its able to read next messege from dpu. 
	constant CPU_ALLOW_MES_FROM_DPUS 	:	STD_LOGIC_VECTOR(4 DOWNTO 0) := "01001"; --ADDRES
	--constant READ_DPU 	:	STD_LOGIC_VECTOR(4 DOWNTO 0) := "01000"; --ADDRES 
	
		
		
-- TYPES
	
	type proc_addr_type 	is array(0 to PROCESSORS-1) of STD_LOGIC_VECTOR( 4 DOWNTO 0);
	type int_addr_type 		is array(0 to INTERFACES-1) of STD_LOGIC_VECTOR( 4 DOWNTO 0);
	type proc_data_type 	is array(0 to PROCESSORS-1) of STD_LOGIC_VECTOR( 7 DOWNTO 0);
	type proc_opc_type 		is array(0 to PROCESSORS-1) of STD_LOGIC_VECTOR( 15 DOWNTO 0);
	 
	type sending_data_type 	is array(0 to 2*PROCESSORS+2) of STD_LOGIC_VECTOR( 7 DOWNTO 0); -- 1(because of cpu) + 2*processors + 2(sending_dpu_message)- 1
	constant SEND_BYTES_ZERO : STD_LOGIC_VECTOR(2*PROCESSORS+2 DOWNTO 0) := (others=>'0');
	constant DPU_WE_ZERO : STD_LOGIC_VECTOR(PROCESSORS-1 DOWNTO 0) := (others=>'0');
	type int_data_type 		is array(0 to INTERFACES-1) of STD_LOGIC_VECTOR( 7 DOWNTO 0);
	
	type intterupts_type	is array(0 to PROCESSORS-1) of STD_LOGIC_VECTOR( 5 DOWNTO 0);
	type ss_spi_type 			is array(0 to SPIS-1) of STD_LOGIC_VECTOR( SPI_MAX_SLAVE-1 DOWNTO 0);
end package;
