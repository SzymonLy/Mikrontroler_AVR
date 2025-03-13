library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.INTERFACE_regs.ALL;


entity full_uc is
    generic(
--		--CLOCK = 12MHz
		WIDHT: integer :=8; -- number of bits in a single uart signal
		PROG_BAUD_RATE: unsigned(15 downto 0) := x"00A2";
		PROG_STOP_TICKS: integer := 31
		);
    Port(
        i_clk_125, i_rst: in std_logic;
        
        i_rx_pm 		: in 	std_logic;
        eth_rst_b 		: out 	std_logic; --0
        o_tx_pm			: out 	std_logic;
        
        o_led			: out 	std_logic_vector(3 downto 0); 
        o_GPIO			: out 	std_logic_vector(GPIOS-1 downto 0);
        i_btn			: in 	std_logic_vector(2 downto 0); --debug only
        
        i_rx 			: in 	std_logic_vector(UARTS-1 downto 0);
        o_tx 			: out 	std_logic_vector(UARTS-1 downto 0);
        
        io_sda			: inout	std_logic_vector(I2CS-1 downto 0);	--serial data output of i2c bus
		io_scl			: inout	std_logic_vector(I2CS-1 downto 0);								
		
		o_ss			: out 	ss_spi_type;	 --slave select			
		o_sclk			: out 	std_logic_vector(SPIS-1 downto 0);
		i_miso			: in 	std_logic_vector(SPIS-1 downto 0);	
		o_mosi			: out 	std_logic_vector(SPIS-1 downto 0);
		
		o_pwm			: out	std_logic_vector(PWMS-1 downto 0)
    );
end full_uc;

 
 
 
 
  architecture Behavioral of full_uc is

	--signal interrupt_vec	: std_logic_vector (5 downto 0);
	signal dpu_in_data	: std_logic_vector (7 downto 0);
	signal dpu_out_data	: std_logic_vector (7 downto 0);
	
	
	signal opcode       : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal pc        	: STD_LOGIC_VECTOR(15 DOWNTO 0);-- used to debug
	signal addr_io   	: STD_LOGIC_VECTOR( 7 DOWNTO 0);
	signal rd_io   		: std_logic;
	signal we_io		: std_logic;
	signal cpu_rst	: std_logic;
	
	signal pc_wait	: std_logic;
	
	
	--constant UART_1 : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000010";
	

	--conections between interface and cpu
	signal cpu_o_interupt : std_logic;
	signal int_reg_we : std_logic;
	signal int_reg_addr:	std_logic_vector (7 downto 0);
	signal int_in_data:	std_logic_vector (7 downto 0);
	signal int_out_data:	std_logic_vector (7 downto 0);
	
	
	signal o_intt : std_logic_vector (15 downto 0); --random big number
	
	
	signal dpu_data_sel : std_logic_vector (PROCESSORS-1 downto 0); 
	signal dpu_or_int_sel:	std_logic_vector (PROCESSORS-1 downto 0);
	signal dpu_inter_sel : std_logic_vector (PROCESSORS-1 downto 0); 
	signal data_from_cpu_to_dpu : std_logic_vector (7 downto 0); 
	signal dpu_intter_out : std_logic_vector (7 downto 0); 
	signal dpu_input_data_select : unsigned (7 downto 0); 
	
	signal cpu_in_data : std_logic_vector (7 downto 0); 
	
	
	signal input_data_dpu : proc_data_type;
	signal opc_dpu : proc_opc_type;
	signal output_data_dpu : proc_data_type;
	signal output_data_dpu_to_cpu : proc_data_type;
	signal data_from_mul_to_dpu : proc_data_type;
	signal addr_dpu : proc_addr_type;
	signal addr_main : STD_LOGIC_VECTOR( 4 DOWNTO 0);
	
	signal data_main : STD_LOGIC_VECTOR( 7 DOWNTO 0);
	signal input_data_int : int_data_type;
	signal output_data_int : int_data_type;
	signal output_interrupt_int : STD_LOGIC_VECTOR(INTERFACES-1 downto 0);
	signal interupt_interface_dpu : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
	signal we_dpu : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
	signal rd_dpu : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
	signal inter_done : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
	signal we_rd_dpu : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
	signal we_int : STD_LOGIC_VECTOR(INTERFACES-1 downto 0);
	signal input_interupt_main : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0); 
	--FIFO
	signal FIFO_write : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
	signal FIFO_read : STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
	signal FIFO_in_data : proc_data_type;
	signal FIFO_out_data : proc_data_type;

           
	
	signal input_addr_int : int_addr_type;
	signal interrupt_main_vec : STD_LOGIC_VECTOR( 5 DOWNTO 0);
	signal prog_mem_we : STD_LOGIC_VECTOR(PROCESSORS DOWNTO 0);
	signal interrupt_vec :intterupts_type;
	signal interrupt_main :std_logic;
	
	signal prog_mem_data : std_logic_vector(15 downto 0);
	signal prog_mem_addr : std_logic_vector(31 downto 0);
	signal prog_mem_we_bit : std_logic;
	signal rst_pm : std_logic;
	
	signal user_write : std_logic;
	signal cpu_out_we : std_logic;
	signal cpu_rd 	: std_logic;
	signal user_data : std_logic_vector(7 downto 0);
	signal inter_done_main : std_logic;
	
		-- creating data to send
	signal sending_index 			: unsigned(7 downto 0);
	signal full_sending_bytes 		: std_logic_vector(2*PROCESSORS+2 downto 0);
	signal sending_data 			: sending_data_type;
	signal not_empty_sending_frame 	: std_logic;
	
	
	signal send_mes_to_cpu 		: std_logic;
	signal mess_to_cpu_en 		: std_logic;
	signal mess_not_sent		: STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
	signal mess_able_to_send	: STD_LOGIC_VECTOR(PROCESSORS-1 downto 0);
	
	signal rx_data 		: std_logic_vector(7 downto 0);
	signal rx_read 		: std_logic;
	signal rx_not_empty 	: std_logic;
	
	component clk_wiz_0
	port ( 
		clk_out1 		: out std_logic;
		clk_in1 	: in std_logic
	);
	end component;
	signal i_clk 	: std_logic;
	

begin  
	rst_pm <= '0'; -- TODO add buttom
	eth_rst_b <= '1';
	clk_gen : clk_wiz_0
	port map(
    	clk_in1 => i_clk_125,
    	clk_out1 => i_clk   
    );
    
	generate_dpu: for i in 0 to PROCESSORS-1 generate	
		DPU_core : entity work.CPU_core(Behavioral)--to change
		port map(
			i_clk=> i_clk,
			i_rst_pm=>rst_pm,
			i_rst=> cpu_rst,
			
			i_prog_mem_addr=>prog_mem_addr(11 downto 0),
			i_prog_mem_we=>prog_mem_we(1+i),
			i_prog_mem_data=>prog_mem_data,
			
			
			i_interrupt_vec => interrupt_vec(i),
			i_data=> input_data_dpu(i),
			o_opc => opc_dpu(i),
			o_pc => open,
			o_data => output_data_dpu(i),
			o_addr_io(4 downto 0) => addr_dpu(i),
			--o_addr_io(7 downto 5) => open,
			o_rd_io => rd_dpu(i),
			o_we_io => we_dpu(i),
			o_inter_done=>inter_done(i));
		
		DPU_FIFO :entity work.FIFO(Behavioral)
		port map(
			i_clk=> i_clk,
           i_rst=>rst_pm,
           i_loop =>'0',
           o_return => open,
           i_write => FIFO_write(i),
           i_read => FIFO_read(i),
           o_full => open,
           o_empty => open,
           i_data =>FIFO_in_data(i),
           o_data =>FIFO_out_data(i)
		);
		we_rd_dpu(i) <= rd_dpu(i) or we_dpu(i); -- one  signal to simplify reading

		--data to dpu is data from cpu when the dpu is selected. Its important to clean input_interupt_main downto
		-- DPU selects data it receive by writing to the register INPUT_DATA_SELECT 
		input_data_dpu(i) <= data_from_mul_to_dpu(i) 	when addr_dpu(i) = SELECT_MUL_DATA  and rd_dpu(i) = '1' else
							 FIFO_out_data(i) 			when addr_dpu(i) = SELECT_CPU_DATA  and rd_dpu(i) = '1';
		FIFO_read(i) <= '1'								when addr_dpu(i) = SELECT_CPU_DATA  and rd_dpu(i) = '1' else '0';
		
		-- data to cpu from dpu is selected by cpu selecting one source of input
		 -- 
		
		interrupt_vec(i) <= (others=>'0')				when inter_done(i) = '1' or  i_rst = '1'		else
							INTER_READ_INTERFACE 		when interupt_interface_dpu(i) = '1'			else 
							INTER_MESS_FROM_CPU 		when input_interupt_main(i) = '1' 				else
							INTER_MESS_TO_CPU_NOT_SENT 	when mess_not_sent(i) = '1' 					else 
							INTER_MESS_ABLE_TO_SENT 	when mess_able_to_send(i) = '1';
		
		-- this latched data can be selected by cpu					
		output_data_dpu_to_cpu(i) <= output_data_dpu(i) when addr_dpu(i) = WRITE_TO_CPU and we_dpu(i) = '1' 
					else x"00" when i_rst = '1'; 		-- Zapobiega b  dom w przypadku wpisania do pami ci cpu UU. 			
		--interrupt_vec(i)(0)<=interupt_interface_dpu(i);
		--interrupt_vec(i)(1)<=input_interupt_main(i);
		-- interrupt to notify dpu that cpu is waitng for a data.
		--interrupt_vec(i)(2) <= '1' when to_integer(unsigned(dpu_input_data_select)) = i else '0';
		-- dpu will select writng to some address. if the adress matches, intterupt will be send to cpu
		--interrupt_main <= '1' when addr_dpu(i) = WRITE_TO_CPU else '0';
		--interrupt_main_vec(0) <= interrupt_main_vec(0) or interrupt_main;
		-- works only if there are less than 9 dpus
		--dpu_in_data(i) <= '1' when addr_dpu(i) = WRITE_TO_CPU else '0';
	end generate generate_dpu;
	
	-- generating interrupts for cpu and creating interrupt to dpu if messege is not sent. 
	process (i_clk, i_rst) begin
		if i_rst = '1' then
			mess_not_sent <= (others=>'0'); -- 
			mess_able_to_send <= (others=>'0');
			mess_to_cpu_en <= '1';
			interrupt_main_vec <= (others => '0');
		elsif rising_edge(i_clk) then
			
			if inter_done_main = '1' then
				interrupt_main_vec <= (others => '0');
			end if;
			if rx_not_empty = '1' then 
				interrupt_main_vec(4 downto 0) <= INTER_RX_MESS;
			else
				for i in 0 to PROCESSORS-1 loop
					if addr_dpu(i) = WRITE_TO_CPU and we_dpu(i) = '1' then
						--if send_mes_to_cpu = '0' then
						mess_able_to_send(i) <= '0';
						if mess_to_cpu_en = '1' then
							interrupt_main_vec <= std_logic_vector( to_unsigned(i+2, interrupt_main_vec'length));
							--send_mes_to_cpu <= '1';
							mess_not_sent(i) <= '0';
							mess_to_cpu_en <= '0';
						else 
							mess_not_sent(i) <= '1'; -- first interrupt when cant sent
						end if;
					end if; 
				end loop;
				if addr_main = CPU_ALLOW_MES_FROM_DPUS and cpu_out_we = '1' then
					mess_to_cpu_en <= '1';
					
					for i in 0 to PROCESSORS-1 loop
						if mess_not_sent(i) = '1' then
							mess_able_to_send(i) <= '1'; -- second interrupt when sending become posible
						end if;
					end loop;
					mess_not_sent <= (others=>'0');
				end if;
			end if;
		end if;
	end process;
	
	-- po dostaniu przewania CPU musi:
	-- wybra  stosowny DPU za pomoc  SELECT_DATA_TO_CPU
	-- odczyta  dane 
	-- Wybra  CPU_ALLOW_MES_FROM_DPUS i zapisa  tam cokolwiek
	-- czeka  na kolejne przerwanie, czyli ustawi  flag  przerwa  (
	
	-- procedura wys ania danych przez dpu do cpu
	-- wysy am dane na adress WRITE_TO_CPU
	-- Je eli otrzymam przerwanie INTER_MESS_TO_CPU_NOT_SENT, czekam a  dostanie przerwanie INTER_MESS_ABLE_TO_SENT
	-- znowu wysy am dane
	-- znowu sprawdzam czy otrzyma em przerwanie, jak tak to znowu czekam ...
	
	
	--interrupt_main_vec(0) <= '1' when 
	--dpu_in_
--	process (i_clk, dpu_input_data_select, input_data_dpu) begin
--		myloop: for i in 0 to PROCESSORS-1 loop	 
			
--			cpu_in_data <= input_data_dpu(i) when to_integer(dpu_input_data_select) = i;
			
--		end loop;
--	end process;

	-- Do cpu trafiaj  dane z wcze niej wybranego DPU. CPU nie ma wp ywu na te dane. 
	process (i_clk) begin
		if rising_edge(i_clk) then
			FIFO_write <= (others=>'0');
			input_interupt_main <= (others=>'0');
			if cpu_out_we = '1' then
				case addr_main is 
					when DPU_WRITE_GPIO=> -- xxxx_xxx gpio value, last bit for value
						if to_integer(unsigned(data_main)) < GPIOS then
							o_gpio(to_integer(unsigned(data_main(7 downto 1)))) <= addr_main(0);
						end if;
					when DPU_WRITE_LED=> --2 bit value
						o_led(to_integer(unsigned(data_main(1 downto 0)))) <= addr_main(0);
					when DPU_WRITE_SEL=>
						if to_integer(unsigned(data_main)) < PROCESSORS then
							dpu_data_sel(to_integer(unsigned(data_main)))<= '1';
						end if;
					when DPU_INTERRUPT =>
						input_interupt_main <= dpu_data_sel;
					when DPU_WRITE_DATA=>
						for i in 0 to PROCESSORS-1 loop 
							if dpu_data_sel(i) = '1' then
								FIFO_in_data(i) <= data_main;
								FIFO_write(i) <= '1';
							end if;
						end loop; 

					when DPU_WRITE_REMOVE=>
						if to_integer(unsigned(data_main)) < PROCESSORS then
							dpu_data_sel(to_integer(unsigned(data_main)))<= '0';
						end if;
					when DPU_WRITE_CLEAR=>
						dpu_data_sel <= (others=>'0');
					when others=>
					
				end case;
			end if;
		end if;
	end process;
	
	--Read data by the CPU

									
--	 when (cpu_rd = '1' and addr_main = READ_RX_DATA) --0x00
--				else output_data_dpu_to_cpu(to_integer(unsigned(addr_main))-1) when 
--				(cpu_rd = '1' and unsigned(addr_main)<PROCESSORS+1) else -- from 0x01 to PROCESSORS
--				 x"00";


	CPU_core : entity work.CPU_core(Behavioral)
		port map(
			i_clk=> i_clk,
			i_rst=> cpu_rst,
			i_rst_pm=>rst_pm,
			
			i_prog_mem_addr=>prog_mem_addr(11 downto 0),
			i_prog_mem_we=>prog_mem_we(0),
			i_prog_mem_data=>prog_mem_data,
			
			
			i_interrupt_vec => interrupt_main_vec,
			i_data => cpu_in_data,
			o_opc => opcode,
			o_pc => pc,
			o_data => data_main,
			o_addr_io(4 downto 0) => addr_main,
			o_rd_io => cpu_rd, 
			o_we_io => cpu_out_we, 
			o_inter_done=>inter_done_main);	
		
	cpu_rst <= pc_wait or i_rst;
		
			cpu_in_data <=  x"00"  			when cpu_rd = '0' else
				rx_data 			when addr_main = READ_RX_DATA_ADDRES else
				output_data_dpu_to_cpu(to_integer(unsigned(addr_main))-1)  
									when unsigned(addr_main)<PROCESSORS+1 else 
									x"00"; -- Wrong addres
									
	rx_read <= '1' when (cpu_rd = '1' and addr_main = READ_RX_DATA_ADDRES) else '0';
	
	Multiplexer :  entity work.Int_selection(Behavioral)
		port map(
			i_clk=> i_clk,
			i_rst=> cpu_rst,
			i_data_cpu=>output_data_dpu,  --data from dpu
			o_data_to_cpu=>data_from_mul_to_dpu, -- data to dpu
			i_addr_cpu=>addr_dpu,	--adress from dpu
			i_we_main=>cpu_out_we,
			
			i_addr_main=>addr_main,
			i_data_main=>data_main,
			
			i_data_from_int=>input_data_int,--data from interace to dpu
			i_interrupt_int=>output_interrupt_int,--from interface
			o_interupt_cpu=>interupt_interface_dpu,
			i_we=>we_rd_dpu,
			o_addr_int=>input_addr_int,
			o_we_int=>we_int,
			o_data_to_int=>output_data_int--data from dpu to interface
			);
		

	
	gen_uart: for i in 0 to UARTS-1 generate	
	    uart_module: entity work.uart_and_interface(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			
			--conection to cpu
			i_interupt =>'0', -- to delete
			i_reg_we =>we_int(i), 
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
			i_reg_we =>we_int(UARTS+i), -- to delete
			i_reg_addr =>input_addr_int(UARTS+i),
			i_reg_data=>output_data_int(UARTS+i),
			o_reg_data=>input_data_int(UARTS+i),
			o_intt=>output_interrupt_int(UARTS+i), 
			
			io_sda=>io_sda(i), io_scl=>io_scl(i)
			);
	end generate gen_i2c;
			
     gen_SPI: for i in 0 to SPIS-1 generate	
		spi_module: entity work.spi_and_interface(Behavioral)
			port map(	
				i_clk=>i_clk, 
				i_rst=>i_rst, 
				
				--conection to cpu
				i_interupt =>'0', -- to delete
				i_reg_we =>we_int(UARTS+I2CS+i), -- to delete
				i_reg_addr =>input_addr_int(UARTS+I2CS+i),
				i_reg_data=>output_data_int(UARTS+I2CS+i),
				o_reg_data=>input_data_int(UARTS+I2CS+i),
				o_intt=>output_interrupt_int(UARTS+I2CS+i), 
				
				o_sclk=>o_sclk(i),
				o_ss=>o_ss(i),
				i_miso=>i_miso(i),
				o_mosi=>o_mosi(i)
				);
	end generate gen_SPI;   

			
	gen_PWM: for i in 0 to PWMS-1 generate	
		pwm: entity work.pwm_module(Behavioral)
        port map(	
        	i_clk=>i_clk, 
			i_rst=>i_rst, 
			
			i_interupt =>'0', 
			i_reg_we =>we_int(UARTS+I2CS+SPIS+i), 
			i_reg_addr =>input_addr_int(UARTS+I2CS+SPIS+i),
			i_reg_data=>output_data_int(UARTS+I2CS+SPIS+i),
			
			o_pwm=>o_pwm(i)
			);
	end generate gen_PWM;

	-- programing corect program memory
	gen_pm_addr: for i in 0 to PROCESSORS generate		
		prog_mem_we(i) <= '1' when unsigned(prog_mem_addr(15+PROCESSORS downto 16)) = i and prog_mem_we_bit = '1' else '0';
	end generate gen_pm_addr; 

	prog_mem : entity work.prog_mem_module(Behavioral) 
	generic map(
		BAUD_RATE => PROG_BAUD_RATE,
		STOP_TICKS => PROG_STOP_TICKS
		)
	port map(
	        i_clk=>i_clk, 
			i_rst=>i_rst, 
			i_rx=>i_rx_pm,o_tx=>o_tx_pm,
			o_mem_addr=>prog_mem_addr,
			o_mem_wr=>prog_mem_we_bit,
			o_mem_data=>prog_mem_data,
			o_wait=>pc_wait, 
			i_data=>user_data,
			i_wr=>user_write,
			o_rx_data =>rx_data,
			i_rx_read=>rx_read,
			o_rx_not_empty=>rx_not_empty
	);

--	process(i_clk) begin
--		if rising_edge(i_clk) then
--			-- creating message that is going to be send
--			-- byte 0 is the first that is going to be send 
--			if full_sending_bytes = SEND_BYTES_ZERO then
--				if cpu_out_we = '1' then
--					if addr_main  = SEND_DATA_TO_USER then
--						full_sending_bytes(0) <= '1';
--						sending_data(0) <= data_main;
--						--not_empty_sending_frame <= '1';
--					end if;
--				end if;
--				for i in  0 to PROCESSORS-1 loop 
--					if we_dpu(i) = '1' then
--						if addr_dpu(i)  = SEND_DATA_TO_USER then
--							sending_data(1) <= DATA_SEND_MESSEGE(15 downto 8); -- starting signal signalizing that this data is from dpu
--							sending_data(2) <= DATA_SEND_MESSEGE(7 downto 0); 
--							full_sending_bytes(2 downto 1) <= "11";
							
--							sending_data(i*2+2) <= std_logic_vector(to_unsigned(i, 8));
--							sending_data(i*2+3) <= input_data_dpu(i);
--							full_sending_bytes(2*i+2) <= '1';
--							--not_empty_sending_frame <= '1';
--						end if;
--					end if;
--				end loop;
--			end if;
--			-- sending data if there is somethink to send
--			if full_sending_bytes /= SEND_BYTES_ZERO then --others=> '0'
--				user_data <= sending_data(0);
--				user_write<= full_sending_bytes(0);
--				-- move left
--				full_sending_bytes(2*PROCESSORS+1 downto 0) <= full_sending_bytes(2*PROCESSORS+2 downto 1);
--				sending_data(0 to 2*PROCESSORS+1) <= sending_data(1 to 2*PROCESSORS+2);
--				full_sending_bytes(2*PROCESSORS+2) <= '0'; 
--			else
--				user_write <= '0';
--			end if;
--		end if;
--	end process;
	
	user_write <= '1' when addr_main  = SEND_DATA_TO_USER  and cpu_out_we = '1' else '0';
	user_data <= data_main;
--	process(i_clk) begin
--		if rising_edge(i_clk) then
--			user_write <= '0';
--			if cpu_out_we = '1' then
--				if addr_main  = SEND_DATA_TO_USER then
--					user_write <= '1';
--					user_data <= data_main;
--					--not_empty_sending_frame <= '1';
--				end if;
--			end if;
--		end if;
--	end process;

end Behavioral; 