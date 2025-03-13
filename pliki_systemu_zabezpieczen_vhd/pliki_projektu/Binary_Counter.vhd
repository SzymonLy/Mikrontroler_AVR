----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/27/2023 12:38:22 PM
-- Design Name: 
-- Module Name: Binary_Counter - Behavioral
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
use ieee.numeric_std. all;

-- This module is responsible for deviding input clock's frequeny to a new one.

entity Binary_Counter is
    Generic(
    
        BAUD_RATE_DIV_LOG: integer := 16; -- number of bits, log of BAUD_RATE_DIV
       -- FREQUENCY: integer := 10e6; -- division of the clock signal 
        RST_POL: STD_LOGIC := '1'
    ); 
    Port ( i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_baud_rate : in unsigned(15 downto 0);
           o_max_ticks : out STD_LOGIC := '0'
           );
end Binary_Counter;

architecture Behavioral of Binary_Counter is
    signal counter: unsigned(BAUD_RATE_DIV_LOG-1 downto 0) := (others=>'0');
    --signal baud_rate: unsigned(BAUD_RATE_DIV_LOG-1 downto 0) := (others=>'0');
begin
	-- baud rate divisor =frequency/(baud_rate * 16) where 16=boud_rate/sampling_rate
	-- lets asume, that the lowes posible baud rate is 1. The next is 2. 2
	-- lowest possible value is 4800. Next one is 2 times bigger, and so on, lets say max 15 times. 15 options. Lowest give 4800
	-- my incput clock frequency is 9216000 because its good for uart. As good as any multiplication of 16*115200
    process(i_clk, i_rst)
    begin
		if (rising_edge(i_clk)) then
            if(counter >= i_baud_rate-1) then 
                counter <= (others=>'0'); 
                o_max_ticks <= '1';
            else 
            	if i_rst = '1' then
            		counter <= (others=>'0');
            	else
                	counter <= counter + 1; 
                end if;
                o_max_ticks <= '0';
            end if;
        end if;
    end process;
end Behavioral;
