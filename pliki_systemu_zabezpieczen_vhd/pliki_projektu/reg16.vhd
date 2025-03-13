library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity reg_16 is
    port (  i_clk       	: IN  STD_LOGIC;
            i_data_a        : IN  STD_LOGIC_VECTOR (15 DOWNTO 0);
            i_we        	: IN  STD_LOGIC_VECTOR ( 1 DOWNTO 0);
            o_data          : OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
end reg_16;

architecture Behavioral of reg_16 is

signal reg                : STD_LOGIC_VECTOR (15 DOWNTO 0) := X"7777";
begin

    process(i_clk)
    begin
        if (rising_edge(i_clk)) then
            if (i_we(1) = '1') then 
                reg(15 DOWNTO 8) <= i_data_a(15 DOWNTO 8);
            end if;
            if (i_we(0) = '1') then 
                reg( 7 DOWNTO 0) <= i_data_a( 7 DOWNTO 0);
            end if;
        end if;
    end process;

    o_data <= reg;

end Behavioral;
