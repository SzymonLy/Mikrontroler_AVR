----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.05.2024 12:44:35
-- Design Name: 
-- Module Name: prog_mem_writing2 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity prog_mem_writing2 is
--  Port ( );
end prog_mem_writing2;

architecture Behavioral of prog_mem_writing2 is

	signal send_tx, tx_sending:std_logic;
	signal tx_mess : std_logic_vector(127 downto 0);
	signal sent_bytes : unsigned(4 downto 0);
	
begin
	process(i_clk) begin
		if rising_edge(i_clk) then
			if checksum_valid = '1' then
				if sent_count /= max_bytes then -- not readed whole temp memory
					sent_count_next <= sent_count + 1; --increment counter and address
					addr_temp_next <= sent_count(3 downto 0) +1;--address of readed temp memory. Starts from 0 to sent_size-1
					
					--first_byte <= not first_byte; -
					byte_count_next <= byte_count - 1;
					-- bytes are always parity, and the par has to reversed before writing it to the memory
					if sent_count(0) = '0' then -- first byte become lower one
						mem_data(7 downto 0) <= temp_out;
					else -- second byte is higher one
						mem_data(15 downto 8) <= temp_out;
						
						case record_type is
							when x"00" =>
								if mem_offset_en= '1' then
									mem_addr(19 downto 0) <= sending_address + mem_addr_offset + sent_count; -- writing to external memory
									mem_addr(31 downto 20) <= (others=>'0'); -- writing to external memory
								else
									mem_addr(15 downto 0) <= sending_address + sent_count(7 downto 1);
								end if;
								if second_clock_cycle = '1' then
									o_mem_wr <= '1';
									second_clock_cycle <= '0' ;
								else
									o_mem_wr <= '0';
									second_clock_cycle <= '1' ;
								end if;
							when x"02" =>-- not used but implemented for compatibility with varius compilers
								mem_addr_offset(19 downto 4) <= unsigned(mem_data);
								mem_addr_offset(3 downto 0) <= (others=>'0');
								mem_offset_en <= '1';
							when x"03" => -- this function is not implemented
								--sets new pc value from 4 data bytes
								--o_pc(15 downto 0) <= mem_data;
								--o_pc_enabled
							when x"04" =>
								mem_offset_en <= '0';
								mem_addr(23 downto 16) <= unsigned(temp_out);
								mem_addr(31 downto 24) <= unsigned(mem_data(7 downto 0));
							when x"05" =>-- not implemented
							-- Start Linear Address Records. 
							-- Explanation https://developer.arm.com/documentation/ka003292/latest
							when others =>
							
						end case;
					end if; 
				else --all temp memory has ben read					
					checksum_valid <= '0';
				end if;
				
			end if;--checksum valid
			
			
			o_tx_write <= '0';
			if send_tx = '1' then
				tx_sending <= '1';
				--o_tx_write <= '1';
				o_tx_data <= tx_mess(tx_mess'length-1 downto tx_mess'length -8);
				sent_bytes <= (others=>'0');
			end if;
			if tx_sending = '1'  then
				--if i_read_tx = '1' then
					if sent_bytes < MESS_SIZE then
						o_tx_write <= '1';
						o_tx_data <= tx_mess(tx_mess'length-1 downto tx_mess'length -8);
						tx_mess(tx_mess'length-1 downto 8) <= tx_mess(tx_mess'length-9 downto 0); --rotate left
						sent_bytes <= sent_bytes + 1;
					else
						sent_bytes <= (others=>'0');
						tx_sending <= '0';
					end if;
				--elsif i_read_mem = '1' then
				--	tx_mess(tx_mess'length-1 downto 8) <= tx_mess(tx_mess'length-9 downto 0); --rotate left
				--end if;
			end if;
		end if;
	end process;
end Behavioral;
