library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.INTERFACE_regs.ALL;

--VERSION with one CPU, testitng comunication between it and interfaces
entity main is
    generic(
--		--CLOCK = 12MHz
		WIDHT: integer :=8 -- number of bits in a single uart signal
  );
    Port(
        i_clk, i_rst: in std_logic;
        
        i_rx_pm 		: in 	std_logic;
        
        i_rx 			: in 	std_logic_vector(UARTS-1 downto 0);
        o_tx 			: out 	std_logic_vector(UARTS-1 downto 0);
        
        io_sda			: inout	std_logic_vector(I2CS-1 downto 0);	--serial data output of i2c bus
		io_scl			: inout	std_logic_vector(I2CS-1 downto 0);
		o_sclk			: out 	std_logic_vector(SPIS-1 downto 0);
											
		o_ss			: out 	ss_spi_type;	 --slave select			
		i_miso			: in 	std_logic_vector(SPIS-1 downto 0);	
		o_mosi			: out 	std_logic_vector(SPIS-1 downto 0);
		o_pwm			: out	std_logic_vector(PWMS-1 downto 0)
    );
end main;

architecture Behavioral of main is

	--signal interrupt_vec	: std_logic_vector (5 downto 0);
	signal dpu_in_data	: std_logic_vector (7 downto 0);
	signal dpu_out_data	: std_logic_vector (7 downto 0);
	
	
	signal opcode       : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal pc        	: STD_LOGIC_VECTOR(15 DOWNTO 0);-- used to debug
	signal addr_io   	: STD_LOGIC_VECTOR( 7 DOWNTO 0);
	signal rd_io   		: std_logic;
	signal we_io		: std_logic;
	signal i_dpu_rst	: std_logic;
	
	
	--constant UART_1 : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000010";
	

	--conections between interface and cpu
	signal cpu_o_interupt : std_logic;
	signal int_reg_we : std_logic;
	signal int_reg_addr:	std_logic_vector (7 downto 0);
	signal int_in_data:	std_logic_vector (7 downto 0);
	signal int_out_data:	std_logic_vector (7 downto 0);
	
	signal o_intt : std_logic_vector (15 downto 0); --random big number
	

       signal input_data_cpu : proc_data_type;
       signal output_data_cpu : proc_data_type;
       signal addr_cpu : proc_addr_type;
       signal addr_main : STD_LOGIC_VECTOR( 4 DOWNTO 0);
       
       signal data_mem : STD_LOGIC_VECTOR( 7 DOWNTO 0);
       signal input_data_int : int_data_type;
       signal output_data_int : int_data_type;
       signal output_interrupt_int : STD_LOGIC_VECTOR(INTERFACES-1 downto 0);
       signal input_interupt_cpu : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
       signal input_interupt_main : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0); --TODO wpisywanie wartoœci do tego  
       
       signal input_addr_int : int_addr_type;
       signal interrupt_main_vec : STD_LOGIC_VECTOR( 5 DOWNTO 0);
       signal prog_mem_we : STD_LOGIC_VECTOR(PROCESSORS DOWNTO 0);
       signal interrupt_vec :intterupts_type;
       
       signal prog_mem_data : std_logic_vector(15 downto 0);
       signal prog_mem_addr : std_logic_vector(CPU_PM_SIZE_LOG-1 downto 0);
       signal i_prog_mem_we : std_logic;
       signal rst_pm : std_logic;

			
begin  


	generate_dpu: for i in 0 to PROCESSORS-1 generate	
		DPU_core : entity work.CPU_core(Behavioral)--to change
		port map(
			i_clk=> i_clk,
			i_rst_pm=>rst_pm,
			i_rst=> i_dpu_rst,
			
			i_prog_mem_addr=>prog_mem_addr(11 downto 0),
			i_prog_mem_we=>prog_mem_we(1+i),
			i_prog_mem_data=>prog_mem_data,
			
			
			i_interrupt_vec => interrupt_vec(i),
			i_data_mem => output_data_cpu(i),
			o_opc => open,
			o_pc => open,
			o_data => input_data_cpu(i),
			o_addr_io(4 downto 0) => addr_cpu(i),
			--o_addr_io(7 downto 5) => open,
			o_rd_io => open,
			o_we_io => open);
		interrupt_vec(i)(0)<=input_interupt_cpu(i);
		interrupt_vec(i)(1)<=input_interupt_main(i);
	end generate generate_dpu;
					

	CPU_core : entity work.CPU_core(Behavioral)
		port map(
			i_clk=> i_clk,
			
			i_rst_pm=>rst_pm,
			i_prog_mem_addr=>prog_mem_addr(11 downto 0),
			i_prog_mem_we=>prog_mem_we(0),
			i_prog_mem_data=>prog_mem_data,
			
			i_rst=> i_rst,
			i_interrupt_vec => interrupt_main_vec,
			i_data_mem => dpu_in_data,
			o_opc => opcode,
			o_pc => pc,
			o_data => data_mem,
			o_addr_io(4 downto 0) => addr_main,
			--o_addr_io(7 downto 5) => open,
			o_rd_io => open,
			o_we_io => open);	
				
	Multiplexer :  entity work.Int_selection(Behavioral)
		port map(
			i_clk=> i_clk,
			i_rst=> i_dpu_rst,
			i_data_cpu=>input_data_cpu,  --data from dpu
			o_data_to_cpu=>output_data_cpu, -- data to dpu
			i_addr_cpu=>addr_cpu,	--adress from dpu
			i_addr_main=>addr_main,
			i_data_mem=>data_mem,
			i_data_from_int=>input_data_int,--data from interace to dpu
			o_data_to_int=>output_data_int,--data from dpu to interface
			i_interrupt_int=>output_interrupt_int,--from interface
			o_interupt_cpu=>input_interupt_cpu,
			o_addr_int=>input_addr_int
			);
		
	gen_uart: for i in 0 to UARTS-1 generate	
	    uart_module: entity work.uart_and_interface(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			
			--conection to cpu
			i_interupt =>'0', -- to delete
			i_reg_we =>'0', -- to delete
			i_reg_addr =>input_addr_int(i),
			i_reg_data=>output_data_int(i),
			o_reg_data=>input_data_int(i),
			o_intt=>output_interrupt_int(i), 
			i_rx=>i_rx(i), o_tx=>o_tx(i)
			);
	end generate gen_uart;
	
	
	gen_i2c: for i in 0 to I2CS-1 generate	
		i2c_module: entity work.i2c_and_interface(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			
			--conection to cpu
			i_interupt =>'0', -- to delete
			i_reg_we =>'0', -- to delete
			i_reg_addr =>input_addr_int(UARTS+i),
			i_reg_data=>output_data_int(UARTS+i),
			o_reg_data=>input_data_int(UARTS+i),
			o_intt=>output_interrupt_int(UARTS+i), 
			
			io_sda=>io_sda(i), io_scl=>io_scl(i)
			);
	end generate gen_i2c;
			

     gen_SPI: for i in 0 to SPIS-1 generate	
		spi_module: entity work.spi_and_interface(Behavioral)
			generic map(
				MAX_SLAVES=>SPI_MAX_SLAVE)
			port map(	
				i_clk=>i_clk, 
				i_rst=>i_rst, 
				
				--conection to cpu
				i_interupt =>'0', -- to delete
				i_reg_we =>'0', -- to delete
				i_reg_addr =>input_addr_int(UARTS+I2CS+i),
				i_reg_data=>output_data_int(UARTS+I2CS+i),
				o_reg_data=>input_data_int(UARTS+I2CS+i),
				o_intt=>output_interrupt_int(UARTS+I2CS+i), 
				
				o_sclk=>o_sclk(i),o_ss=>o_ss(i),
				i_miso=>i_miso(i),o_mosi=>o_mosi(i)
				);
	end generate gen_SPI;   

			
	gen_PWM: for i in 0 to PWMS-1 generate	
		pwm: entity work.pwm_module(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			
			--conection to cpu
			i_interupt =>'0', -- to delete
			i_reg_we =>'0', -- to delete
			i_reg_addr =>input_addr_int(UARTS+I2CS+SPIS+i),
			i_reg_data=>output_data_int(UARTS+I2CS+SPIS+i),
			
			o_pwm=>o_pwm(i)
			);
	end generate gen_PWM;

	gen_pm_addr: for i in 0 to PROCESSORS generate		
		prog_mem_we(i) <= '1' when unsigned(prog_mem_addr(15+PROCESSORS downto 15)) = i and i_prog_mem_we = '1' else '0';
	end generate gen_pm_addr; 

	prog_mem : entity work.prog_mem_module(Behavioral) 
	port map(
	        i_clk=>i_clk, 
			i_rst=>i_rst, 
			i_rx=>i_rx_pm,
			o_mem_addr=>prog_mem_addr,
			o_mem_wr=>i_prog_mem_we,
			o_mem_data=>prog_mem_data
	);
	-- for cpu i_prog_mem_addr(31 downto 16) = x0000
	-- for dpu1 i_prog_mem_addr(31 downto 16) = x0001
	

end Behavioral; 