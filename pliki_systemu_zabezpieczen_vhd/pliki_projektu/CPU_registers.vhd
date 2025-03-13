-------------------------------------------------------------------------------
--
-- Copyright (C) 2009, 2010 Dr. Juergen Sauermann
--
-- This code is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This code is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this code (see the file named COPYING).
-- If not, see http://www.gnu.org/licenses/.
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Module Name: RegisterFile - Behavioral
-- Create Date: 12:43:34 10/28/2009
-- Description: a register file (16 register pairs) of a CPU.
-- Create Date: 13:51:24 11/07/2009
--
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.CPU_intruction_set.ALL;

entity CPU_registers is
    port (  i_clk       		: IN  STD_LOGIC ;
            i_addr_mode    : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0);
            i_status_reg_addr   : IN  STD_LOGIC_VECTOR( 3 DOWNTO 0);
            i_input_data        : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_flag_data     	: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_data_imm       	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_addr_a     		: IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_addr_b      		: IN  STD_LOGIC_VECTOR( 4 DOWNTO 1);
            
            i_we_reg_01     	: IN  STD_LOGIC;
            i_we_reg_a      	: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            i_we_flag      		: IN  STD_LOGIC;
            i_we_dm      		: IN  STD_LOGIC;
            i_we_xyzs   		: IN  STD_LOGIC;

            o_addr       		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_opc_2        		: OUT STD_LOGIC;
            o_data_a         	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_flags_data     	: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_data_b         	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_c_data         	: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_z_data         	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
end CPU_registers;

architecture Behavioral of CPU_registers is

component reg_16
    port (  i_clk		: IN    STD_LOGIC;
            i_data_a    : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_we        : IN    STD_LOGIC_VECTOR( 1 DOWNTO 0);
            o_data      : OUT   STD_LOGIC_VECTOR(15 DOWNTO 0));
end component;

component CPU_regs is
  Port ( 
    a 		: IN STD_LOGIC_VECTOR ( 3 DOWNTO 0 );
    d 		: IN STD_LOGIC_VECTOR ( 15 DOWNTO 0 );
    dpra 	: IN STD_LOGIC_VECTOR ( 3 DOWNTO 0 ); --
    clk 	: IN STD_LOGIC;
    we 		: IN STD_LOGIC;
    spo 	: OUT STD_LOGIC_VECTOR ( 15 DOWNTO 0 );
    dpo 	: OUT STD_LOGIC_VECTOR ( 15 DOWNTO 0 )
  );
end component;

signal reg0            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg2            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg4            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg6            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg8            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg10            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg12            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg14            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg16            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg18            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg20            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg22            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg24            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg26            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg28            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg30            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal reg_sp           : STD_LOGIC_VECTOR(15 DOWNTO 0);    -- stack pointer

component CPU_status_regs is
    port (  i_clk       		: IN  STD_LOGIC;
            i_status_reg_addr  	:  IN  STD_LOGIC_VECTOR ( 3 DOWNTO 0);
            i_data_mem       : IN  STD_LOGIC_VECTOR ( 7 DOWNTO 0);
            i_flag_data     	: IN  STD_LOGIC_VECTOR ( 7 DOWNTO 0);
            i_we_flag      		: IN  STD_LOGIC;
            i_status_we     	: IN  STD_LOGIC;
            o_data           	: OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0);
            o_opc_2        	: OUT STD_LOGIC);
end component;

signal flags_data          		: STD_LOGIC_VECTOR( 7 DOWNTO 0);

signal addr_c_reg            	: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal base_value           	: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal addr_a_reg           	: STD_LOGIC_VECTOR( 4 DOWNTO 1);
signal sp_input_data            : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal x_input_data             : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal y_input_data             : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal z_input_data             : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal preicrementation_value   : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal postincrementation_value : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal data_c_reg              	: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal sp_we_mode     			: STD_LOGIC;
signal reg_we             		: STD_LOGIC_VECTOR(31 DOWNTO 0);
signal a_we           			: STD_LOGIC;
signal we_8bit_reg           	: STD_LOGIC_VECTOR(31 DOWNTO 0);
signal regs_we          		: STD_LOGIC_VECTOR( 1 DOWNTO 0);
signal we_16bit_reg          	: STD_LOGIC_VECTOR(31 DOWNTO 0);
signal we_8bit_reg_from_io      : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal xyzs_we        			: STD_LOGIC_VECTOR(31 DOWNTO 0);
signal x_we           			: STD_LOGIC;
signal y_we           			: STD_LOGIC;
signal z_we           			: STD_LOGIC;
signal we_sp          			: STD_LOGIC_VECTOR( 1 DOWNTO 0);
signal status_we         		: STD_LOGIC;
signal xyzs_value           	: STD_LOGIC_VECTOR(15 DOWNTO 0);

begin

	r0:  reg_16 port map(i_clk=>i_clk, i_we=>reg_we(1 DOWNTO 0), i_data_a=>i_input_data, o_data=>reg0);
    r2:  reg_16 port map(i_clk=>i_clk, i_we=>reg_we(3 DOWNTO 2), i_data_a=>i_input_data, o_data=>reg2);
    r4:  reg_16 port map(i_clk=>i_clk, i_we=>reg_we(5 DOWNTO 4), i_data_a=>i_input_data, o_data=>reg4);
    r6:  reg_16 port map(i_clk=>i_clk, i_we=>reg_we(7 DOWNTO 6), i_data_a=>i_input_data, o_data=>reg6);
    r8:  reg_16 port map(i_clk=>i_clk, i_we=>reg_we(9 DOWNTO 8), i_data_a=>i_input_data, o_data=>reg8);
    r10: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(11 DOWNTO 10), i_data_a=>i_input_data,  o_data=>reg10);
    r12: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(13 DOWNTO 12), i_data_a=>i_input_data,  o_data=>reg12);
    r14: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(15 DOWNTO 14), i_data_a=>i_input_data,  o_data=>reg14);
    r16: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(17 DOWNTO 16), i_data_a=>i_input_data, o_data=>reg16);
    r18: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(19 DOWNTO 18), i_data_a=>i_input_data, o_data=>reg18);
    r20: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(21 DOWNTO 20), i_data_a=>i_input_data, o_data=>reg20);
    r22: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(23 DOWNTO 22), i_data_a=>i_input_data, o_data=>reg22);
    r24: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(25 DOWNTO 24), i_data_a=>i_input_data, o_data=>reg24);
    r26: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(27 DOWNTO 26), i_data_a=>x_input_data,  o_data=>reg26);
    r28: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(29 DOWNTO 28), i_data_a=>y_input_data,  o_data=>reg28);
    r30: reg_16 port map(i_clk=>i_clk, i_we=>reg_we(31 DOWNTO 30), i_data_a=>z_input_data,  o_data=>reg30);
    sp:  reg_16 port map(i_clk=>i_clk, i_we=>we_sp,            i_data_a=>sp_input_data, o_data=>reg_sp);

    sr: CPU_status_regs
    port map(   i_clk      			=>i_clk,
                i_status_reg_addr   =>i_status_reg_addr,
                i_data_mem      	=>i_input_data(7 DOWNTO 0),
                i_flag_data    		=>i_flag_data,
                i_we_flag     		=>i_we_flag,
                i_status_we    		=>status_we,
                o_data          	=>flags_data,
                o_opc_2       	=>o_opc_2);

    -- The output of the register selected by addr_c_reg.
    process(reg0, reg2, reg4, reg6, reg8, reg10, reg12, reg14,
    		reg16, reg18, reg20, reg22, reg24, reg26, reg28, reg30,
            reg_sp, flags_data, addr_c_reg(6 DOWNTO 1))
    begin
        case addr_c_reg(6 DOWNTO 1) is
        	when "000000"=>data_c_reg <= reg0;
            when "000001"=>data_c_reg <= reg2;
            when "000010"=>data_c_reg <= reg4;
            when "000011"=>data_c_reg <= reg6;
            when "000100"=>data_c_reg <= reg8;
            when "000101"=>data_c_reg <= reg10;
            when "000110"=>data_c_reg <= reg12;
            when "000111"=>data_c_reg <= reg14;
            when "001000"=>data_c_reg <= reg16;
            when "001001"=>data_c_reg <= reg18;
            when "001010"=>data_c_reg <= reg20;
            when "001011"=>data_c_reg <= reg22;
            when "001100"=>data_c_reg <= reg24;
            when "001101"=>data_c_reg <= reg26;
            when "001110"=>data_c_reg <= reg28;
            when "001111"=>data_c_reg <= reg30;
            when "101110"=>data_c_reg <= reg_sp ( 7 DOWNTO 0) & X"00";     -- SPL
            when others  =>data_c_reg <= flags_data & reg_sp (15 DOWNTO 8);   -- SR/SPH
        end case;
    end process;
    o_c_data <= data_c_reg( 7 DOWNTO 0) when (addr_c_reg(0) = '0') else data_c_reg(15 DOWNTO 8);
    
    
    -- The output of the register pair selected by i_addr_a.
    process(reg0, reg2, reg4, reg6, reg8, reg10, reg12, reg14,
    		reg16, reg18, reg20, reg22, reg24, reg26, reg28, reg30,
            i_addr_a(4 DOWNTO 1))
    begin
        case i_addr_a(4 DOWNTO 1) is
            when "0000"=>o_data_a <= reg0;
            when "0001"=>o_data_a <= reg2;
            when "0010"=>o_data_a <= reg4;
            when "0011"=>o_data_a <= reg6;
            when "0100"=>o_data_a <= reg8;
            when "0101"=>o_data_a <= reg10;
            when "0110"=>o_data_a <= reg12;
            when "0111"=>o_data_a <= reg14;
            when "1000"=>o_data_a <= reg16;
            when "1001"=>o_data_a <= reg18;
            when "1010"=>o_data_a <= reg20;
            when "1011"=>o_data_a <= reg22;
            when "1100"=>o_data_a <= reg24;
            when "1101"=>o_data_a <= reg26;
            when "1110"=>o_data_a <= reg28;
            when others=>o_data_a <= reg30;
        end case;
    end process;

    -- The output of the register pair selected by i_addr_b.
    process(reg0, reg2, reg4, reg6, reg8, reg10, reg12, reg14,
    		reg16, reg18, reg20, reg22, reg24, reg26, reg28, reg30, i_addr_b)
    begin
        case i_addr_b is
        	when "0000"=>o_data_b <= reg0;
            when "0001"=>o_data_b <= reg2;
            when "0010"=>o_data_b <= reg4;
            when "0011"=>o_data_b <= reg6;
            when "0100"=>o_data_b <= reg8;
            when "0101"=>o_data_b <= reg10;
            when "0110"=>o_data_b <= reg12;
            when "0111"=>o_data_b <= reg14;
            when "1000"=>o_data_b <= reg16;
            when "1001"=>o_data_b <= reg18;
            when "1010"=>o_data_b <= reg20;
            when "1011"=>o_data_b <= reg22;
            when "1100"=>o_data_b <= reg24;
            when "1101"=>o_data_b <= reg26;
            when "1110"=>o_data_b <= reg28;
            when others=>o_data_b <= reg30;
        end case;
    end process;

    -- the base value of the X/Y/Z/SP register as per i_addr_mode
    process(i_addr_mode(2 DOWNTO 0), i_data_imm, reg_sp, reg26, reg28, reg30)
    begin
        case i_addr_mode(2 DOWNTO 0) is
            when AS_SP =>base_value <= reg_sp;
            when AS_Z  =>base_value <= reg30;
            when AS_Y  =>base_value <= reg28;
            when AS_X  =>base_value <= reg26;
            when AS_IMM=>base_value <= i_data_imm;
            when others=>base_value <= X"0000";
        end case;
    end process;

    process(i_addr_mode, i_data_imm)
    begin
        case i_addr_mode is
            when AMOD_Xq | AMOD_Yq | AMOD_Zq =>
             	preicrementation_value 		<= i_data_imm;   
            	postincrementation_value 	<= X"0000";
            when AMOD_Xi | AMOD_Yi | AMOD_Zi =>
                preicrementation_value 		<= X"0000";    
                postincrementation_value 	<= X"0001";
            when AMOD_dX  | AMOD_dY  | AMOD_dZ =>
                preicrementation_value 		<= X"FFFF";  -- -1
                postincrementation_value 	<= X"FFFF";
            when AMOD_iSP=>
                preicrementation_value 		<= X"0001";    
                postincrementation_value 	<= X"0001";
            when AMOD_iiSP=>
                preicrementation_value 		<= X"0002";    
                postincrementation_value 	<= X"0002";
            when AMOD_SPd=>
                preicrementation_value 		<= X"0000";    
                postincrementation_value	<= X"FFFF";
            when AMOD_SPdd=>
                preicrementation_value 		<= X"0000";    
                postincrementation_value 	<= X"FFFE";-- -2
            when others=>
                preicrementation_value	 	<= X"0000";    
                postincrementation_value 	<= X"0000";
        end case;
    end process;

    xyzs_value <= base_value + postincrementation_value;--posticremenctation
    addr_c_reg <= base_value + preicrementation_value;--preincrementation
    
    a_we <= i_we_dm when (addr_c_reg(15 DOWNTO 5) = "00000000000") else '0';
    status_we    <= i_we_dm when (addr_c_reg = X"005F") else '0';
    sp_we_mode <= i_we_xyzs when (i_addr_mode(2 DOWNTO 0) = AS_SP) else '0';
    we_sp(1) <= i_we_dm when (addr_c_reg = X"005E") else sp_we_mode;
    we_sp(0) <= i_we_dm when (addr_c_reg = X"005D") else sp_we_mode;

    x_input_data  <= xyzs_value when (xyzs_we(26) = '1')        else i_input_data;
    y_input_data  <= xyzs_value when (xyzs_we(28) = '1')        else i_input_data;
    z_input_data  <= xyzs_value when (xyzs_we(30) = '1')        else i_input_data;
    sp_input_data <= xyzs_value when (i_addr_mode(3 DOWNTO 0) = AM_WS) else i_input_data;
    
    we_8bit_reg( 0) <= i_we_reg_a(0) when (i_addr_a = "00000") else '0';
    we_8bit_reg( 1) <= i_we_reg_a(0) when (i_addr_a = "00001") else '0';
    we_8bit_reg( 2) <= i_we_reg_a(0) when (i_addr_a = "00010") else '0';
    we_8bit_reg( 3) <= i_we_reg_a(0) when (i_addr_a = "00011") else '0';
    we_8bit_reg( 4) <= i_we_reg_a(0) when (i_addr_a = "00100") else '0';
    we_8bit_reg( 5) <= i_we_reg_a(0) when (i_addr_a = "00101") else '0';
    we_8bit_reg( 6) <= i_we_reg_a(0) when (i_addr_a = "00110") else '0';
    we_8bit_reg( 7) <= i_we_reg_a(0) when (i_addr_a = "00111") else '0';
    we_8bit_reg( 8) <= i_we_reg_a(0) when (i_addr_a = "01000") else '0';
    we_8bit_reg( 9) <= i_we_reg_a(0) when (i_addr_a = "01001") else '0';
    we_8bit_reg(10) <= i_we_reg_a(0) when (i_addr_a = "01010") else '0';
    we_8bit_reg(11) <= i_we_reg_a(0) when (i_addr_a = "01011") else '0';
    we_8bit_reg(12) <= i_we_reg_a(0) when (i_addr_a = "01100") else '0';
    we_8bit_reg(13) <= i_we_reg_a(0) when (i_addr_a = "01101") else '0';
    we_8bit_reg(14) <= i_we_reg_a(0) when (i_addr_a = "01110") else '0';
    we_8bit_reg(15) <= i_we_reg_a(0) when (i_addr_a = "01111") else '0';
    we_8bit_reg(16) <= i_we_reg_a(0) when (i_addr_a = "10000") else '0';
    we_8bit_reg(17) <= i_we_reg_a(0) when (i_addr_a = "10001") else '0';
    we_8bit_reg(18) <= i_we_reg_a(0) when (i_addr_a = "10010") else '0';
    we_8bit_reg(19) <= i_we_reg_a(0) when (i_addr_a = "10011") else '0';
    we_8bit_reg(20) <= i_we_reg_a(0) when (i_addr_a = "10100") else '0';
    we_8bit_reg(21) <= i_we_reg_a(0) when (i_addr_a = "10101") else '0';
    we_8bit_reg(22) <= i_we_reg_a(0) when (i_addr_a = "10110") else '0';
    we_8bit_reg(23) <= i_we_reg_a(0) when (i_addr_a = "10111") else '0';
    we_8bit_reg(24) <= i_we_reg_a(0) when (i_addr_a = "11000") else '0';
    we_8bit_reg(25) <= i_we_reg_a(0) when (i_addr_a = "11001") else '0';
    we_8bit_reg(26) <= i_we_reg_a(0) when (i_addr_a = "11010") else '0';
    we_8bit_reg(27) <= i_we_reg_a(0) when (i_addr_a = "11011") else '0';
    we_8bit_reg(28) <= i_we_reg_a(0) when (i_addr_a = "11100") else '0';
    we_8bit_reg(29) <= i_we_reg_a(0) when (i_addr_a = "11101") else '0';
    we_8bit_reg(30) <= i_we_reg_a(0) when (i_addr_a = "11110") else '0';
    we_8bit_reg(31) <= i_we_reg_a(0) when (i_addr_a = "11111") else '0';

    addr_a_reg <= i_addr_a(4 DOWNTO 1);
    regs_we <= i_we_reg_a(1) & i_we_reg_a(1);
    we_16bit_reg( 1 DOWNTO  0) <= regs_we when (addr_a_reg = "0000") else "00";
    we_16bit_reg( 3 DOWNTO  2) <= regs_we when (addr_a_reg = "0001") else "00";
    we_16bit_reg( 5 DOWNTO  4) <= regs_we when (addr_a_reg = "0010") else "00";
    we_16bit_reg( 7 DOWNTO  6) <= regs_we when (addr_a_reg = "0011") else "00";
    we_16bit_reg( 9 DOWNTO  8) <= regs_we when (addr_a_reg = "0100") else "00";
    we_16bit_reg(11 DOWNTO 10) <= regs_we when (addr_a_reg = "0101") else "00";
    we_16bit_reg(13 DOWNTO 12) <= regs_we when (addr_a_reg = "0110") else "00";
    we_16bit_reg(15 DOWNTO 14) <= regs_we when (addr_a_reg = "0111") else "00";
    we_16bit_reg(17 DOWNTO 16) <= regs_we when (addr_a_reg = "1000") else "00";
    we_16bit_reg(19 DOWNTO 18) <= regs_we when (addr_a_reg = "1001") else "00";
    we_16bit_reg(21 DOWNTO 20) <= regs_we when (addr_a_reg = "1010") else "00";
    we_16bit_reg(23 DOWNTO 22) <= regs_we when (addr_a_reg = "1011") else "00";
    we_16bit_reg(25 DOWNTO 24) <= regs_we when (addr_a_reg = "1100") else "00";
    we_16bit_reg(27 DOWNTO 26) <= regs_we when (addr_a_reg = "1101") else "00";
    we_16bit_reg(29 DOWNTO 28) <= regs_we when (addr_a_reg = "1110") else "00";
    we_16bit_reg(31 DOWNTO 30) <= regs_we when (addr_a_reg = "1111") else "00";
    
    -- write to an 8-bit register pair which are addressed by addr_c_reg
    -- a_we = '1' and addr_c_reg(4 DOWNTO 0) matches
    we_8bit_reg_from_io( 0) <= a_we when (addr_c_reg(4 DOWNTO 0) = "00000") else '0';
    we_8bit_reg_from_io( 1) <= a_we when (addr_c_reg(4 DOWNTO 0) = "00001") else '0';
    we_8bit_reg_from_io( 2) <= a_we when (addr_c_reg(4 DOWNTO 0) = "00010") else '0';
    we_8bit_reg_from_io( 3) <= a_we when (addr_c_reg(4 DOWNTO 0) = "00011") else '0';
    we_8bit_reg_from_io( 4) <= a_we when (addr_c_reg(4 DOWNTO 0) = "00100") else '0';
    we_8bit_reg_from_io( 5) <= a_we when (addr_c_reg(4 DOWNTO 0) = "00101") else '0';
    we_8bit_reg_from_io( 6) <= a_we when (addr_c_reg(4 DOWNTO 0) = "00110") else '0';
    we_8bit_reg_from_io( 7) <= a_we when (addr_c_reg(4 DOWNTO 0) = "00111") else '0';
    we_8bit_reg_from_io( 8) <= a_we when (addr_c_reg(4 DOWNTO 0) = "01000") else '0';
    we_8bit_reg_from_io( 9) <= a_we when (addr_c_reg(4 DOWNTO 0) = "01001") else '0';
    we_8bit_reg_from_io(10) <= a_we when (addr_c_reg(4 DOWNTO 0) = "01010") else '0';
    we_8bit_reg_from_io(11) <= a_we when (addr_c_reg(4 DOWNTO 0) = "01011") else '0';
    we_8bit_reg_from_io(12) <= a_we when (addr_c_reg(4 DOWNTO 0) = "01100") else '0';
    we_8bit_reg_from_io(13) <= a_we when (addr_c_reg(4 DOWNTO 0) = "01101") else '0';
    we_8bit_reg_from_io(14) <= a_we when (addr_c_reg(4 DOWNTO 0) = "01110") else '0';
    we_8bit_reg_from_io(15) <= a_we when (addr_c_reg(4 DOWNTO 0) = "01111") else '0';
    we_8bit_reg_from_io(16) <= a_we when (addr_c_reg(4 DOWNTO 0) = "10000") else '0';
    we_8bit_reg_from_io(17) <= a_we when (addr_c_reg(4 DOWNTO 0) = "10001") else '0';
    we_8bit_reg_from_io(18) <= a_we when (addr_c_reg(4 DOWNTO 0) = "10010") else '0';
    we_8bit_reg_from_io(19) <= a_we when (addr_c_reg(4 DOWNTO 0) = "10011") else '0';
    we_8bit_reg_from_io(20) <= a_we when (addr_c_reg(4 DOWNTO 0) = "10100") else '0';
    we_8bit_reg_from_io(21) <= a_we when (addr_c_reg(4 DOWNTO 0) = "10101") else '0';
    we_8bit_reg_from_io(22) <= a_we when (addr_c_reg(4 DOWNTO 0) = "10110") else '0';
    we_8bit_reg_from_io(23) <= a_we when (addr_c_reg(4 DOWNTO 0) = "10111") else '0';
    we_8bit_reg_from_io(24) <= a_we when (addr_c_reg(4 DOWNTO 0) = "11000") else '0';
    we_8bit_reg_from_io(25) <= a_we when (addr_c_reg(4 DOWNTO 0) = "11001") else '0';
    we_8bit_reg_from_io(26) <= a_we when (addr_c_reg(4 DOWNTO 0) = "11010") else '0';
    we_8bit_reg_from_io(27) <= a_we when (addr_c_reg(4 DOWNTO 0) = "11011") else '0';
    we_8bit_reg_from_io(28) <= a_we when (addr_c_reg(4 DOWNTO 0) = "11100") else '0';
    we_8bit_reg_from_io(29) <= a_we when (addr_c_reg(4 DOWNTO 0) = "11101") else '0';
    we_8bit_reg_from_io(30) <= a_we when (addr_c_reg(4 DOWNTO 0) = "11110") else '0';
    we_8bit_reg_from_io(31) <= a_we when (addr_c_reg(4 DOWNTO 0) = "11111") else '0';

    x_we <= i_we_xyzs when (i_addr_mode(3 DOWNTO 0) = AM_WX) else '0';
    y_we <= i_we_xyzs when (i_addr_mode(3 DOWNTO 0) = AM_WY) else '0';
    z_we <= i_we_xyzs when (i_addr_mode(3 DOWNTO 0) = AM_WZ) else '0';
    xyzs_we <= z_we & z_we & y_we & y_we & x_we & x_we & X"000000" & i_we_reg_01 & i_we_reg_01;  

    reg_we <= we_8bit_reg or we_16bit_reg or we_8bit_reg_from_io or xyzs_we;
    
    o_flags_data <= flags_data;
    o_z_data <= reg30;
    o_addr <= addr_c_reg;

end Behavioral;
