library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CPU_status_regs is
    port (  i_clk       		: IN  STD_LOGIC;

            i_status_reg_addr   : IN  STD_LOGIC_VECTOR ( 3 DOWNTO 0);
            i_data_mem       : IN  STD_LOGIC_VECTOR ( 7 DOWNTO 0);
            i_flag_data     	: IN  STD_LOGIC_VECTOR ( 7 DOWNTO 0);
            i_we_flag      		: IN  STD_LOGIC;
            i_status_we     	: IN  STD_LOGIC;

            o_data           	: OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0);
            o_opc_2        	: OUT STD_LOGIC);
end CPU_status_regs;

architecture Behavioral of CPU_status_regs is

signal reg                : STD_LOGIC_VECTOR ( 7 DOWNTO 0);
begin

    process(i_clk)
    begin
        if (rising_edge(i_clk)) then
            if (i_we_flag = '1') then          -- write flags (from ALU)
                reg <= i_flag_data;
            elsif (i_status_we = '1') then      -- write I/O
                reg <= i_data_mem;
            end if;
        end if;
    end process;

    cond: process(i_status_reg_addr, reg)
    begin
        case i_status_reg_addr(2 DOWNTO 0) is
            when "000" =>o_opc_2 <= reg(0) xor i_status_reg_addr(3);
            when "001" =>o_opc_2 <= reg(1) xor i_status_reg_addr(3);
            when "010" =>o_opc_2 <= reg(2) xor i_status_reg_addr(3);
            when "011" =>o_opc_2 <= reg(3) xor i_status_reg_addr(3);
            when "100" =>o_opc_2 <= reg(4) xor i_status_reg_addr(3);
            when "101" =>o_opc_2 <= reg(5) xor i_status_reg_addr(3);
            when "110" =>o_opc_2 <= reg(6) xor i_status_reg_addr(3);
            when others=>o_opc_2 <= reg(7) xor i_status_reg_addr(3);
        end case;
    end process;

    o_data <= reg;

end Behavioral;