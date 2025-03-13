library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.INTERFACE_regs.ALL;

entity Interface is
	Port(
        i_clk, i_rst: 	in std_logic;
        i_interupt : 	in std_logic;
        i_reg_we : 		in std_logic;
        i_reg_addr : 	in std_logic_vector(4 downto 0);
        i_reg_data : 	in std_logic_vector(7 downto 0);
      
        o_reg_data : 	out std_logic_vector(7 downto 0);
        o_intt :		out std_logic;
        
       -- out1 : 			in std_logic;--i_rx
       -- out2 : 			out std_logic;--i_tx
       --out 
		 o_uart_tx_enable:	out std_logic;
		 o_uart_read_rx	: 	out std_logic;
		 o_uart_write_tx  : out std_logic;
		 o_uart_write_data: out std_logic_vector (7 downto 0);
		 o_rewrite_fifo : 	out std_logic; 
		 o_rst_tx : 		out std_logic; 
		-- o_int_sett_we: 	out std_logic; 
		 i_tx_finish:		in std_logic;
		 i_rx_finish:		in std_logic;
		 i_data_mem:		in std_logic_vector (7 downto 0);
		 i_uart_read_data:	in std_logic_vector (7 downto 0)
       );
end Interface;

architecture Behavioral of Interface is
	signal tx_full	: 		std_logic;
	signal rx_empty 	: 	std_logic;
	signal wait_for_intt:	std_logic;
	signal interrupt:		std_logic;
	signal intt_enable:		std_logic;
	--signal send_bit: 		std_logic; 
begin


	o_intt <= i_rx_finish;
	process(i_clk, i_rst) 
	begin
		if i_rst = '1' then
			o_uart_read_rx <= '1';
			o_uart_tx_enable <= '0';
		elsif rising_edge(i_clk) then
			o_rst_tx <= '0';
			--o_int_sett_we <= '0';
--			send_bit <= '0';
			o_uart_write_tx <= '0';
			--o_rewrite_fifo <= '0';
			
			-- after finishing sending all the data, tx will send for one clock cycle i_tx_finish signal high. intt_enable = '1', wait_for_intt = '0'
			--Then immidietly the o_uart_tx_enable has to go low until next intterupt signal. wait_for_intt = '1'
			--After that o_uart_tx_enable will go high and wait until next i_tx_finish signal.
			if 	intt_enable = '1' then
				o_rewrite_fifo <= '1';
				if wait_for_intt = '0' then	-- tx is sending
					o_uart_tx_enable <= '1';
					if i_tx_finish = '1' then
						o_uart_tx_enable <= '0';
						wait_for_intt <= '1';
					end if;
				else 
					if interrupt ='1' then
						wait_for_intt <= '0';
						interrupt <='1';
					end if;
				end if;
			end if;
					
				
			if(i_reg_we = '1') then
				case i_reg_addr is
            		when INT_DATA_IN => 
            			o_uart_write_data <= i_reg_data;
            			o_uart_write_tx <= '1';
            		when INT_SENDING_MODE => 
            			intt_enable <= '0';

						case i_reg_data(2 downto 0) is 
							when INT_SINGLE_MODE => 
								-- simple write to memory. The old data is replaced by new one, and no byte is sended two times
								o_rewrite_fifo <= '0';
								o_uart_tx_enable <= '1'; -- send everything it has in memory
							when INT_CONTINUE_MODE => -- After sending all the data it send it again from the begining.
								o_rewrite_fifo <= '1';
								-- some system to rewrite new data to memory
								o_uart_tx_enable <= '1';
							when INT_RESET_MODE => -- After sending all the data it send it again from the begining.
								o_rst_tx <= '1'; -- only this mode clears the memory when its set to loop mode. 
								o_rewrite_fifo <= '0';
								-- some system to rewrite new data to memory
								o_uart_tx_enable <= '0';
							when INT_INTT_START_MODE => -- After setting this mode the data will be send and then it waits for interrupt
								o_uart_tx_enable <= '1';-- start from sending data
								wait_for_intt <= '0';
								intt_enable <= '1';
							when INT_INTT_WAIT_MODE => -- After setting this mode the data will be stored but send after interrupt
								o_uart_tx_enable <= '0';-- wait for sending data from sending data
								wait_for_intt <= '1';
								intt_enable <= '1';
							when INT_BIT_SEND_MODE =>

							when OTHERS =>
						end case;

					when INT_SET_INTT => 
						interrupt <= i_reg_data(0); -- the last bit of the i_reg_data has to be 1 to set interrupt
					when INT_READ_DATA =>
						o_reg_data <= i_uart_read_data;
						o_uart_read_rx <= i_reg_we; --<='1';
					when INT_READ_MEMORY_STATUS=>
						o_reg_data(0)<=tx_full;
						o_reg_data(1)<=rx_empty; 
					when INT_READ_CURRENT_STATUS=>
						o_reg_data<=i_data_mem;
					when INT_READ_RX_STACK_HEAD=>
						o_reg_data <= i_uart_read_data;
					when OTHERS =>
						--o_int_sett_we <= '1';
				end case;
			end if;
		end if;
	end process;
end Behavioral;
