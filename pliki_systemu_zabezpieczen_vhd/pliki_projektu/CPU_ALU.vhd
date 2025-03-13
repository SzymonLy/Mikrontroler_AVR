library IEEE;
use IEEE.std_logic_1164.ALL;
--use IEEE.std_logic_ARITH.ALL;
--use IEEE.std_logic_UNSIGNED.ALL;
use IEEE.numeric_std.ALL;

use work.CPU_intruction_set.ALL;

entity CPU_ALU is
    Port (  i_alu_opcode    : IN  STD_LOGIC_VECTOR( 4 DOWNTO 0);
            i_opc_2       	: IN  STD_LOGIC_VECTOR( 3 DOWNTO 0);
            i_data_a        : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_addr_a_0      : IN  STD_LOGIC;
            i_data_mem   	: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_flag_data     : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_data_imm     	: IN  STD_LOGIC_VECTOR( 7 DOWNTO 0);
            i_pc        	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_data_b        : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_addr_b_0      : IN  STD_LOGIC;
            o_inter_done    : out  STD_LOGIC;
            i_alu_imm_sel 	: IN  STD_LOGIC_VECTOR( 1 DOWNTO 0); -- selects the source of the second operand in the ALU

            o_flags_data    : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
            o_skip_SBIS     : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0);
            o_data      	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
end CPU_ALU;

architecture Behavioral of CPU_ALU is
	-- funkcje czêsto u¿ywane do obliczenia nowych bitów rejestru stanu.
	function zero(byte: STD_LOGIC_VECTOR(7 DOWNTO 0)) return STD_LOGIC is
	begin
		return not (byte(0) or byte(1) or byte(2) or byte(3) or
					byte(4) or byte(5) or byte(6) or byte(7));
		--return nor byte; -- works only in vhdl 2008
		--return nor(byte);-- works only in vhdl 2008 and with std_logic_1164
	end;
	
	function carry_add(Rd, Rr, R: STD_LOGIC) return STD_LOGIC is
	begin
		return (Rd and Rr) or (Rd and (not R)) or ((not R) and Rr);
	end;
	
	function carry_sub(Rd, Rr, R: STD_LOGIC) return STD_LOGIC is
	begin
		return ((not Rd) and Rr) or (Rr and R) or (R and (not Rd));
	end;
	
	function cy(Rd, Rr, R: std_logic) return std_logic is
	begin
	  return (Rd and Rr) or (Rd and not R) or (Rr and not R);
	end;
 
	
	function over_add(Rd, Rr, R: STD_LOGIC) return STD_LOGIC is
	begin
		return (Rd and Rr and (not R)) or ((not Rd) and (not Rr) and R);
	end;
	
	function over_sub(Rd, Rr, R: STD_LOGIC) return STD_LOGIC is
	begin
		return (Rd and (not Rr) and (not R)) or ((not Rd) and Rr and R);
	end;
	
	
	function signed_add(Rd, Rr, R: STD_LOGIC) return STD_LOGIC is
	begin
		return R xor over_add(Rd, Rr, R);
	end;

	function signed_sub(Rd, Rr, R: STD_LOGIC) return STD_LOGIC is
	begin
    	return R xor over_sub(Rd, Rr, R);
	end;



signal data_a       : STD_LOGIC_VECTOR( 7 DOWNTO 0);    
signal data_b       : STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- odd or even R
signal data_imm		: STD_LOGIC_VECTOR( 7 DOWNTO 0);    
signal data_out     : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal bit_b        : STD_LOGIC;
signal signed_a     : STD_LOGIC; 
signal signed_b     : STD_LOGIC;

signal flag_0_vec     : STD_LOGIC_VECTOR(0 downto 0);

signal adc_value    	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D + R + Carry
signal add_value    	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D + R
signal sbc_value     	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D - R - Carry
signal sub_value     	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D - R

signal adiw_value     	: STD_LOGIC_VECTOR( 15 DOWNTO 0);    
signal subi_value     	: STD_LOGIC_VECTOR( 15 DOWNTO 0);    

signal and_value     	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D and R
signal asr_value      	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- (signed D) >> 1
signal dec_value      	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D - 1
signal inc_value      	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D + 1
signal lsr_value      	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- (unsigned) D >> 1
signal mask_value     	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- 1 << IMM
signal neg_value      	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- 0 - D
signal not_value      	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- 0 not D
signal or_value      	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D or R
signal mul_value       	: STD_LOGIC_VECTOR(17 DOWNTO 0);    -- D * R
signal ror_value      	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D rotated right

signal swap_value     	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D swapped
signal xor_value     	: STD_LOGIC_VECTOR( 7 DOWNTO 0);    -- D xor R
signal bit_number     	: integer range 0 to 7;    -- D xor R

begin
	bit_number <= to_integer(unsigned(i_opc_2(2 DOWNTO 0)));
	-- select value of bit number b for instruction that use single bit
	-- set bit mask which can be used to determined value of a bit
    d_bit: process(bit_number, i_data_mem)
    begin
    	bit_b <= i_data_mem(bit_number);
    	mask_value <= (others=>'0');
    	mask_value(bit_number) <= '1';

    end process;
    -- SBIS - Skip if Bit in I/O Register is Set
    -- SBIC  Skip if Bit in I/O Register is Cleared
    -- i_opc_2(3) = set/clear
    -- high when it should skip intruction
    o_skip_SBIS(0) <= bit_b xor not i_opc_2(3);
    -- CPSE - Compare Skip if Equal
    -- high if 2 register are equal
	o_skip_SBIS(1) <= zero(sub_value);                 -- D == R for CPSE

    -- Input multiplexing. Input is double register
    data_a 		<= i_data_a(15 DOWNTO 8) when (i_addr_a_0 = '1') else i_data_a(7 DOWNTO 0);
    data_b 		<= i_data_b(15 DOWNTO 8) when (i_addr_b_0 = '1') else i_data_b(7 DOWNTO 0);
    data_imm 	<= i_data_imm           when (i_alu_imm_sel = ALU_IMM) else data_b;
    
    process(adc_value, add_value, i_alu_opcode, and_value, asr_value,
            i_opc_2, i_data_a, data_a, dec_value, i_data_mem, i_flag_data, i_data_imm, mask_value,
            inc_value, lsr_value, neg_value, not_value, or_value, i_pc, mul_value,
            i_data_b, data_imm, bit_b, ror_value, sub_value, sbc_value,
            signed_a, signed_b, swap_value, xor_value, flag_0_vec, adiw_value, subi_value, bit_number)
    begin

	-- Czêsto u¿ywane unckje arytmetyczne Obliczenie wybranych funkcji arytmetycznych wczeœniej 
	-- pomaga w przypadku, w którym s¹ one u¿ywane dla ró¿nych funkcji w nieznacznie ró¿ny sposób

 	flag_0_vec <= (others => i_flag_data(0)); -- make a vector to use in numeric operation, -- only used to caluculate adc_value and sbc_value
    add_value  <= std_logic_vector ( unsigned(data_a) 	+ unsigned(data_imm));
    adc_value  <= std_logic_vector ( unsigned(add_value)+ unsigned(flag_0_vec));
    sub_value  <= std_logic_vector ( unsigned(data_a) 	- unsigned(data_imm));
    sbc_value  <= std_logic_vector ( unsigned(sub_value)- unsigned(flag_0_vec));
    -- only 2 16 bit operation. Thet have to use input data 
    adiw_value <= std_logic_vector ( unsigned(i_data_a)+ unsigned(i_data_imm(5 downto 0)));
    subi_value <= std_logic_vector ( unsigned(i_data_a)- unsigned(i_data_imm(5 downto 0)));
    
    
    inc_value   <= std_logic_vector(unsigned(data_a) + 1);
    dec_value   <= std_logic_vector(unsigned(data_a) - 1);
    
   
    and_value  <= data_a and data_imm;
    neg_value   <= std_logic_vector(0 - unsigned(data_a));
    not_value   <= not data_a;
    or_value   <= data_a or data_imm;
    xor_value  <= data_a xor data_imm;
    
    asr_value   <= data_a(7) & data_a(7 DOWNTO 1);
    lsr_value   <= '0' & data_a(7 DOWNTO 1);
    ror_value   <= i_flag_data(0) &  data_a(7 DOWNTO 1);
    swap_value  <= data_a(3 DOWNTO 0) & data_a(7 DOWNTO 4);
    
    --zero for unsigned operations
    signed_a<= data_a(7) and i_data_imm(6); -- only used to caluculate mul_value
    signed_b<= data_imm(7) and i_data_imm(5); -- only used to caluculate mul_value
    mul_value    <= std_logic_vector(  unsigned(signed_a & data_a) * unsigned(signed_b & data_imm));
    
    

	-- Default values 

	o_flags_data(7 DOWNTO 0) <= i_flag_data;
	data_out <= X"0000";
	o_inter_done <= '0';
		
	-- Output and flag multiplexing
	    case i_alu_opcode is
            when CPU_ADC=> -- Add with Carry, Rd ? Rd + Rr + C
                data_out <= adc_value & adc_value;
                o_flags_data(0) <= carry_add(data_a(7), data_imm(7), adc_value(7));		-- Carry
                o_flags_data(1) <= zero(adc_value);                          			-- Zero
                o_flags_data(2) <= adc_value(7);                           				-- Negative
                o_flags_data(3) <= over_add(data_a(7), data_imm(7), adc_value(7));		-- Overflow
                o_flags_data(4) <= signed_add(data_a(7), data_imm(7), adc_value(7));	-- Signed
                o_flags_data(5) <= carry_add(data_a(3), data_imm(3), adc_value(3));		-- Halfcarry

            when CPU_ADD=> -- Add without Carry
                data_out <= add_value & add_value;
                o_flags_data(0) <= carry_add(data_a(7), data_imm(7), add_value(7));		-- Carry
                o_flags_data(1) <= zero(add_value);                          			-- Zero
                o_flags_data(2) <= add_value(7);                           				-- Negative
                o_flags_data(3) <= over_add(data_a(7), data_imm(7), add_value(7));		-- Overflow
                o_flags_data(4) <= signed_add(data_a(7), data_imm(7), add_value(7));	-- Signed
                o_flags_data(5) <= carry_add(data_a(3), data_imm(3), add_value(3));		-- Halfcarry

             when CPU_ADIW => -- add imidiate
				data_out <=  adiw_value;
				o_flags_data(0) <= adiw_value(15) and not i_data_a(15); 			-- Carry
				o_flags_data(1) <= zero(adiw_value(15 downto 8)) and zero(adiw_value(7 downto 0)); -- Zero
				o_flags_data(2) <= adiw_value(15); 								-- Negative
				o_flags_data(3) <= i_data_a(15) and not adiw_value(15); 			-- Overflow
				o_flags_data(4) <= (adiw_value(15) and not i_data_a(15)) xor (i_data_a(15) and not adiw_value(15)); -- Signed
				
			when CPU_SBIW =>
				data_out <= subi_value;
				o_flags_data(0) <= subi_value(15) and not i_data_a(15); 	-- Carry
				o_flags_data(1) <= zero(subi_value(15 downto 8)) and zero(subi_value(7 downto 0)); -- Zero
				o_flags_data(2) <= subi_value(15); 						-- Negative
				o_flags_data(3) <= i_data_a(15) and not subi_value(15); 	-- Overflow
				o_flags_data(4) <= (subi_value(15) and not i_data_a(15)) xor (i_data_a(15) and not subi_value(15)); 	-- Signed
				    

				    
            when CPU_SUB=>
                data_out 		<= sub_value & sub_value;
                o_flags_data(0) <= cy(data_a(7), data_imm(7), sub_value(7));		-- Carry
                o_flags_data(1) <= zero(sub_value);                          			-- Zero
                o_flags_data(2) <= sub_value(7);                           				-- Negative
                o_flags_data(3) <= over_sub(data_a(7), data_imm(7), sub_value(7));		-- Overflow
                o_flags_data(4) <= signed_sub(data_a(7), data_imm(7), sub_value(7));	-- Signed
                o_flags_data(5) <= cy(data_a(3), data_imm(3), sub_value(3));		-- Halfcarry
                

            when CPU_AND=>
                data_out 		<= and_value & and_value;
                o_flags_data(1) <= zero(and_value);                         	-- Zero
                o_flags_data(2) <= and_value(7);                          		-- Negative
                o_flags_data(3) <= '0';                                  		-- Overflow
                o_flags_data(4) <= and_value(7);                          		-- Signed

            when CPU_ASR=>
                data_out 		<= asr_value & asr_value;
                o_flags_data(0) <= data_a(0);                              	-- Carry
                o_flags_data(1) <= zero(asr_value);                         -- Zero
                o_flags_data(2) <= data_a(7);                              	-- Negative
                o_flags_data(3) <= data_a(0) xor data_a(7);                 -- Overflow
                o_flags_data(4) <= data_a(0);                              	-- Signed
                
            when CPU_BLD=>    --Bit Load from the T Flag in SREG to a Bit in Register
            -- copies the T Flag in the SREG (Status Register) to bit b in register Rd
                    data_out(bit_number) 	<= i_flag_data(6);
                	data_out(bit_number+8)  <= i_flag_data(6);

            when CPU_BITCS=> -- copy i_data_mem to T flag
            
            	--  1001 1000 AAAA Abbb -  CBI - Clear Bit in I/O Register
                --  1001 1001 AAAA Abbb - SBIC - Subtract Immediate with Carry SBI - Set Bit in I/O Registe
                --  1001 1010 AAAA Abbb - SBI - Set Bit in I/O Registe
                --  1001 1011 AAAA Abbb - SBIC - Skip if Bit in I/O Register is Cleared
                 -- i_opc_2(3) = set/clear
                o_flags_data(6) <= bit_b xor not i_opc_2(3);
                if (i_opc_2(3) = '0') then    -- clear
                    data_out(15 DOWNTO 8) <= i_data_mem and not mask_value;
                    data_out( 7 DOWNTO 0) <= i_data_mem and not mask_value;
                else                        -- set
                    data_out(15 DOWNTO 8) <= i_data_mem or mask_value;
                    data_out( 7 DOWNTO 0) <= i_data_mem or mask_value;
                end if;
                
            when CPU_COM=>
                data_out <= not_value & not_value;
                o_flags_data(0) <= '1';                                -- Carry
                o_flags_data(1) <= zero(not data_a);                   -- Zero
                o_flags_data(2) <= not data_a(7);                      -- Negative
                o_flags_data(3) <= '0';                                -- Overflow
                o_flags_data(4) <= not data_a(7);                      -- Signed

            when CPU_DEC=>
                data_out <= dec_value & dec_value;
                o_flags_data(1) <= zero(dec_value);                    -- Zero
                o_flags_data(2) <= dec_value(7);                       -- Negative
                if (data_a = X"80") then
                    o_flags_data(3) <= '1';                            -- Overflow
                    o_flags_data(4) <= not dec_value(7);               -- Signed
                else
                    o_flags_data(3) <= '0';                            -- Overflow
                    o_flags_data(4) <= dec_value(7);                   -- Signed
                end if;

            when CPU_EOR=>
                data_out <= xor_value & xor_value;
                o_flags_data(1) <= zero(xor_value);                     -- Zero
                o_flags_data(2) <= xor_value(7);                        -- Negative
                o_flags_data(3) <= '0';                                	-- Overflow
                o_flags_data(4) <= xor_value(7);                      	-- Signed

            when CPU_INC=>
                data_out <= inc_value & inc_value;
                o_flags_data(1) <= zero(inc_value);                   -- Zero
                o_flags_data(2) <= inc_value(7);                       -- Negative
                if (data_a = X"7F") then
                    o_flags_data(3) <= '1';                            -- Overflow
                    o_flags_data(4) <= not inc_value(7);               -- Signed
                else
                    o_flags_data(3) <= '0';                            -- Overflow
                    o_flags_data(4) <= inc_value(7);                   -- Signed
                end if;

            when CPU_INT=>
                data_out <= i_pc;
                o_flags_data(7) <= i_data_imm(6);    					-- ena/disable interrupts
                o_inter_done <= '1';

            when CPU_LS =>
                data_out <= lsr_value & lsr_value;
                o_flags_data(0) <= data_a(0);                          	-- Carry
                o_flags_data(1) <= zero(lsr_value);                     -- Zero
                o_flags_data(2) <= '0';                                	-- Negative
                o_flags_data(3) <= data_a(0);                           -- Overflow
                o_flags_data(4) <= data_a(0);                           -- Signed

            when CPU_MV1=>
                data_out <= data_a & data_a;
                
            when CPU_MV2=>
                data_out <= data_imm & data_imm;

            when CPU_MV=>
                data_out <= i_data_b(15 DOWNTO 8) & data_imm;
                         
            when CPU_NEG=>
                data_out <= neg_value & neg_value;
                o_flags_data(0) <= not zero(data_a);          		 -- Carry
                o_flags_data(1) <= zero(neg_value);           		 -- Zero
                o_flags_data(2) <= neg_value(7);              		 -- Negative
                if (data_a = X"80") then
                    o_flags_data(3) <= '1';                   		 -- Overflow
                    o_flags_data(4) <= not neg_value(7);      		 -- Signed
                else
                    o_flags_data(3) <= '0';                   		 -- Overflow
                    o_flags_data(4) <= neg_value(7);          		 -- Signed
                end if;
                o_flags_data(5) <= data_a(3) or neg_value(3); 		-- Halfcarry

			
			when CPU_MULT =>
				o_flags_data(0) <= mul_value(15); 					-- Carry
				if i_data_imm(7) = '0' then 						-- MUL
					data_out <= mul_value(15 downto 0);
					o_flags_data(1) <= zero(mul_value(15 downto 8)) -- Zero
				and zero(mul_value( 7 downto 0));
				else -- FMUL
					data_out <= mul_value(14 downto 0) & "0";
					o_flags_data(1) <= zero(mul_value(14 downto 7)) -- Zero
					and zero(mul_value( 6 downto 0) & "0");
				end if;

            when CPU_OR=>
                data_out <= or_value & or_value;
                o_flags_data(1) <= zero(or_value);                          -- Zero
                o_flags_data(2) <= or_value(7);                           	-- Negative
                o_flags_data(3) <= '0';                                		-- Overflow
                o_flags_data(4) <= or_value(7);                           	-- Signed

            when CPU_PC1=>   -- ICALL, RCALL
               -- data_out <= i_pc + X"0001";
                data_out <= std_logic_vector(signed(i_pc) + x"0001");

            when CPU_PC2=>   -- CALL
                --data_out <= i_pc + X"0002";
                data_out <= std_logic_vector(signed(i_pc) + x"0002");

            when CPU_ROR=>
                data_out <= ror_value & ror_value;
                o_flags_data(0) <= data_a(0);                         	-- Carry
                o_flags_data(1) <= zero(ror_value);                     -- Zero
                o_flags_data(2) <= i_flag_data(0);                      -- Negative
                o_flags_data(3) <= i_flag_data(0) xor data_a(0);        -- Overflow
                o_flags_data(4) <= i_flag_data(0);                      -- Signed

--TODO
            when CPU_SBC=>
                data_out <= sbc_value & sbc_value;
                o_flags_data(0) <= carry_sub(data_a(7), data_imm(7), sbc_value(7));		-- Carry
                o_flags_data(1) <= zero(sbc_value) and i_flag_data(1);           		-- Zero
                o_flags_data(2) <= sbc_value(7);                           				-- Negative
                o_flags_data(3) <= over_sub(data_a(7), data_imm(7), sbc_value(7));		-- Overflow
                o_flags_data(4) <= signed_sub(data_a(7), data_imm(7), sbc_value(7));	-- Signed
                o_flags_data(5) <= carry_sub(data_a(3), data_imm(3), sbc_value(3));		-- Halfcarry



            when CPU_SRE=>
            	o_flags_data(bit_number) 	<= not i_opc_2(3);
            when CPU_SWA=>
            	data_out <= swap_value & swap_value;

            when others=>
        end case;
    end process;
    
	-- Final output multiplexing
    o_data <= (i_data_mem & i_data_mem) when (i_alu_imm_sel = ALU_DATA) else data_out;

end Behavioral;

