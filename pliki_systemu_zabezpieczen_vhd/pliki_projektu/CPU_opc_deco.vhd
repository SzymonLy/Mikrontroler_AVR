
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.ALL;

use work.CPU_intruction_set.ALL;

entity CPU_opc_deco is
    port (  i_clk       		: IN  STD_LOGIC;
            i_opcode       		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_opc_h       		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_pc        		: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_first_cycle       : IN  STD_LOGIC;

            o_alu_opcode    	: OUT STD_LOGIC_VECTOR( 4 DOWNTO 0);
            o_addr_mode      	: OUT STD_LOGIC_VECTOR( 5 DOWNTO 0); --defines how to compute memory address
            o_opc_pc       		: OUT STD_LOGIC_VECTOR( 3 DOWNTO 0);
            o_reg1_addr     	: OUT STD_LOGIC_VECTOR( 4 DOWNTO 0);
            o_immidiate_data    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_opc       		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_pc        		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_pc_opcode     	: OUT STD_LOGIC_VECTOR( 2 DOWNTO 0); -- to register
            o_prog_mem_sel      : OUT STD_LOGIC;  -- program memory select, set when the address defined by AMOD is a program memory address rather than a data memory address.
            o_data_mem_read     : OUT STD_LOGIC;
            o_reg2_addr     	: OUT STD_LOGIC_VECTOR( 4 DOWNTO 0);
            o_alu_im_sel 		: OUT STD_LOGIC_VECTOR( 1 DOWNTO 0);
            
            o_jump_addr			: OUT STD_LOGIC_VECTOR( 15 DOWNTO 0);
            
            o_we_01_regs     	: OUT STD_LOGIC;
            o_we_a_regs      	: OUT STD_LOGIC_VECTOR( 1 DOWNTO 0);
            o_we_status     	: OUT STD_LOGIC;
            o_we_mem      		: OUT STD_LOGIC_VECTOR( 1 DOWNTO 0);
            o_we_xyzs   		: OUT STD_LOGIC); -- which one will be writed is defined in addr_mode
end CPU_opc_deco;

architecture Behavioral of CPU_opc_deco is
begin

    process(i_clk)
    begin
    if (rising_edge(i_clk)) then
        o_alu_opcode  		<= CPU_MV1;
        o_addr_mode    		<= AMOD_ABS;
        o_opc_pc     		<= i_opcode(10) & i_opcode(2 DOWNTO 0);
        o_reg1_addr   		<= i_opcode(8 DOWNTO 4);
        o_immidiate_data    <= X"0000";
        o_opc     			<= i_opcode(15 DOWNTO  0);
        o_pc      			<= i_pc;
        o_pc_opcode   		<= PC_NEXT;
        o_prog_mem_sel     	<= '0';
        o_data_mem_read    	<= '0';
        o_reg2_addr   		<= i_opcode(9) & i_opcode(3 DOWNTO 0);
        o_alu_im_sel <= ALU_REG;
		o_we_a_regs    		<= "00";
        o_we_01_regs   		<= '0';
        o_we_status    		<= '0';
        o_we_mem    		<= "00";
        o_we_xyzs			<= '0';
		o_jump_addr 		<= i_opc_h;
        case i_opcode(15 DOWNTO 10) is
            when "000000"=>-- 0000 00xx xxxx xxxx
                case i_opcode(9 DOWNTO 8) is
                    when "00"=> 
					-- 0000 0000 0000 0000 - NOP
					-- 0000 0000 001v vvvv - INTERRUPT
						if (i_opcode(5)) = '1' then   	-- interrupt
							o_alu_opcode <= CPU_INT;
							o_addr_mode <= AMOD_SPdd;
							o_jump_addr <= x"00" & "000" & i_opcode(4 DOWNTO 0);
							o_pc_opcode <= PC_LD_I;
							o_we_status <= '1';     -- clear I-flag
							o_we_mem <= "11";     		-- write return address
							o_we_xyzs <= '1';   		-- write new SP
						end if;
					when "01" =>
						 -- 0000 0001 dddd rrrr - MOVW
						o_reg1_addr <= i_opcode(7 downto 4) & "0";
						o_reg2_addr <= i_opcode(3 downto 0) & "0";
						o_alu_opcode <= CPU_MV;
						o_we_a_regs <= "11";
					when "10" =>
						 -- 0000 0010 dddd rrrr - MULS
						o_reg1_addr <= "1" & i_opcode(7 downto 4);
						o_reg2_addr <= "1" & i_opcode(3 downto 0);
						o_alu_opcode <= CPU_MULT;
						o_immidiate_data(7 downto 5) <= MULT_SS;
						o_we_01_regs <= '1';
						o_we_status <= '1';
					when others =>
						 -- 0000 0011 0ddd 0rrr - _MULSU SU "010"
						 -- 0000 0011 0ddd 1rrr - FMUL UU "100"
						 -- 0000 0011 1ddd 0rrr - FMULS SS "111"
						 -- 0000 0011 1ddd 1rrr - FMULSU SU "110"
						o_reg1_addr(4 downto 3) <= "10"; -- regs 16 to 23
						o_reg2_addr(4 downto 3) <= "10"; -- regs 16 to 23
						o_alu_opcode <= CPU_MULT;
						if i_opcode(7) = '0' then
							if i_opcode(3) = '0' then
								o_immidiate_data(7 downto 5) <= MULT_SU;
							else
								o_immidiate_data(7 downto 5) <= MULT_FUU;
							end if;
						else
							if i_opcode(3) = '0' then
								o_immidiate_data(7 downto 5) <= MULT_FSS;
							else
								o_immidiate_data(7 downto 5) <= MULT_FSU;
							end if;
						end if;
						o_we_01_regs <= '1';
						o_we_status <= '1';
					end case;


            when "000001" | "000010"=>
                -- 0000 01rd dddd rrrr - CPC = SBC without o_we_a_regs
                -- 0000 10rd dddd rrrr - SBC
                o_alu_opcode <= CPU_SBC;
                o_we_a_regs <= '0' & i_opcode(11);  -- write Rd if SBC.
                o_we_status <= '1';

            when "000011"=>                      
                -- 0000 11rd dddd rrrr - ADD
                o_alu_opcode <= CPU_ADD;
                o_we_a_regs <= "01";
                o_we_status <= '1';

            when "000101" | "000110"=>
                -- 0001 01rd dddd rrrr - CP = SUB without o_we_a_regs
                -- 0000 10rd dddd rrrr - SUB
                o_alu_opcode <= CPU_SUB;
                o_we_a_regs <= '0' & i_opcode(11);  -- write Rd if SUB.
                o_we_status <= '1';

            when "000111"=>-- 0001 11rd dddd rrrr - ADC
                o_alu_opcode <= CPU_ADC;
                o_we_a_regs <= "01";
                o_we_status <= '1';

            when "001000"=>-- 0010 00rd dddd rrrr - AND
                o_alu_opcode <= CPU_AND;
                o_we_a_regs <= "01";
                o_we_status <= '1';

            when "001001"=>-- 0010 01rd dddd rrrr - EOR
                o_alu_opcode <= CPU_EOR;
                o_we_a_regs <= "01";
                o_we_status <= '1';

            when "001010"=>-- 0010 10rd dddd rrrr - OR
                o_alu_opcode <= CPU_OR;
                o_we_a_regs <= "01";
                o_we_status <= '1';

            when "001011"=>-- 0010 11rd dddd rrrr - MOV
                o_alu_opcode <= CPU_MV2;
                o_we_a_regs <= "01";

            when "001100" | "001101" | "001110" | "001111"
               | "010100" | "010101" | "010110" | "010111"=>
                -- 0011 KKKK dddd KKKK - CPI
                -- 0101 KKKK dddd KKKK - SUBI
                o_alu_opcode <= CPU_SUB;
                o_immidiate_data(7 DOWNTO 0) <= i_opcode(11 DOWNTO 8) & i_opcode(3 DOWNTO 0);
                o_alu_im_sel <= ALU_IMM;
                o_reg1_addr(4) <= '1';    -- Rd = 16...31
                o_we_a_regs <= '0' & i_opcode(14);
                o_we_status <= '1';
            
            when "010000" | "010001" | "010010" | "010011"=> -- 0100 KKKK dddd KKKK - SBCI
                o_alu_opcode <= CPU_SBC;
                o_immidiate_data(7 DOWNTO 0) <= i_opcode(11 DOWNTO 8) & i_opcode(3 DOWNTO 0);
                o_alu_im_sel <= ALU_IMM;
                o_reg1_addr(4) <= '1';    -- Rd = 16...31
                o_we_a_regs <= "01";
                o_we_status <= '1';

            when "011000" | "011001" | "011010" | "011011"=>-- 0110 KKKK dddd KKKK - ORI
                o_alu_opcode <= CPU_OR;
                o_immidiate_data(7 DOWNTO 0) <= i_opcode(11 DOWNTO 8) & i_opcode(3 DOWNTO 0);
                o_alu_im_sel <= ALU_IMM;
                o_reg1_addr(4) <= '1';    -- Rd = 16...31
                o_we_a_regs <= "01";
                o_we_status <= '1';

            when "011100" | "011101" | "011110" | "011111"=>-- 0111 KKKK dddd KKKK - ANDI
                o_alu_opcode <= CPU_AND;
                o_immidiate_data(7 DOWNTO 0) <= i_opcode(11 DOWNTO 8) & i_opcode(3 DOWNTO 0);
                o_alu_im_sel <= ALU_IMM;
                o_reg1_addr(4) <= '1';    -- Rd = 16...31
                o_we_a_regs <= "01";
                o_we_status <= '1';
			when "100000" | "100001" | "100010" | "100011"
| "101000" | "101001" | "101010" | "101011" =>
                            
				-- 10q0 qq0d dddd 1qqq LDD (Y + q)          
				-- 10q0 qq0d dddd 0qqq LDD (Z + q)          
				-- 10q0 qq1d dddd 1qqq SDD (Y + q)          
				-- 10q0 qq1d dddd 0qqq SDD (Z + q)                                         
				o_immidiate_data(5) <= i_opcode(13);                      
				o_immidiate_data(4 downto 3) <= i_opcode(11 downto 10);   
				o_immidiate_data(2 downto 0) <= i_opcode( 2 downto 0);    
				if (i_opcode(3) = '0') then 
					o_addr_mode <= AMOD_Zq; 
				else 
					o_addr_mode <= AMOD_Yq;                     
				end if;                                     
				o_we_xyzs <= not i_opcode(9);       
				o_we_mem <= '0' & i_opcode(9); 
				

            when "100100"=>                           			-- 1001 00xx xxxx xxxx
                o_immidiate_data <= i_opc_h;   	-- absolute address for LDS/STS
                if (i_opcode(9) = '0') then        				-- LDD / POP
                    -- 1001 00-0d dddd 0000 - LDS
                    -- 1001 00-0d dddd 0001 - LD   Rd, Z+
                    -- 1001 00-0d dddd 0010 - LD   Rd, -Z
                    -- 1001 00-0d dddd 0100 - LPM  Rd, (Z)      
                    -- 1001 00-0d dddd 0101 - LPM  Rd, (Z+)      
                    -- 1001 00-0d dddd 1001 - LD   Rd, Y+
                    -- 1001 00-0d dddd 1010 - LD   Rd, -Y
                    -- 1001 00-0d dddd 1100 - LD   Rd, X
                    -- 1001 00-0d dddd 1101 - LD   Rd, X+
                    -- 1001 00-0d dddd 1110 - LD   Rd, -X
                    -- 1001 00-0d dddd 1111 - POP  Rd
                    o_alu_im_sel <= ALU_DATA;
                    o_data_mem_read <= i_first_cycle;
                    o_we_a_regs <= '0' & not i_first_cycle;
                    o_we_xyzs <= not i_first_cycle;
                    o_prog_mem_sel <= (not i_opcode(3)) and i_opcode(2) and (not i_opcode(1));
                    case i_opcode(3 DOWNTO 0) is
                        when "0000"=>o_addr_mode <= AMOD_ABS;  
                        				o_we_xyzs <= '0';
                        when "0001"=>o_addr_mode <= AMOD_Zi;
                        when "0100"=>o_addr_mode <= AMOD_Z;    
                        				o_we_xyzs <= '0';
                        when "0101"=>o_addr_mode <= AMOD_Zi;
                        when "1001"=>o_addr_mode <= AMOD_Yi;
                        when "1010"=>o_addr_mode <= AMOD_dY;
                        when "1100"=>o_addr_mode <= AMOD_X;    
                        				o_we_xyzs <= '0';
                        when "1101"=>o_addr_mode <= AMOD_Xi;
                        when "1110"=>o_addr_mode <= AMOD_dX;
                        when "1111"=>o_addr_mode <= AMOD_iSP;
                        when others=>     o_we_xyzs <= '0';
                    end case;
                else                        
                	-- STD / PUSH
                    -- 1001 00-1r rrrr 0000 - STS
                    -- 1001 00-1r rrrr 0001 - ST Z+. Rr
                    -- 1001 00-1r rrrr 0010 - ST -Z. Rr
                    -- 1001 00-1r rrrr 1000 - ST Y. Rr
                    -- 1001 00-1r rrrr 1001 - ST Y+. Rr
                    -- 1001 00-1r rrrr 1010 - ST -Y. Rr
                    -- 1001 00-1r rrrr 1100 - ST X. Rr
                    -- 1001 00-1r rrrr 1101 - ST X+. Rr
                    -- 1001 00-1r rrrr 1110 - ST -X. Rr
                    -- 1001 00-1r rrrr 1111 - PUSH Rr
                    --o_alu_im_sel <= ALU_DATA;
                    --o_data_mem_read <= i_first_cycle;
                    --o_we_a_regs <= '0' & not i_first_cycle;
                   
                   -- o_prog_mem_sel <= (not i_opcode(3)) and i_opcode(2) and (not i_opcode(1));
                    
                    o_we_xyzs <= not i_first_cycle;
                    o_alu_opcode <= CPU_MV1;
                    o_we_mem <= "01";
                    --o_we_xyzs <= '1';
                    case i_opcode(3 DOWNTO 0) is
                        when "0000"=>o_addr_mode <= AMOD_ABS;  
                        o_we_xyzs <= '0';
                        when "0001"=>o_addr_mode <= AMOD_Zi;
                        when "0010"=>o_addr_mode <= AMOD_dZ;
                        when "1001"=>o_addr_mode <= AMOD_Yi;
                        when "1010"=>o_addr_mode <= AMOD_dY;
                        when "1100"=>o_addr_mode <= AMOD_X;    
                        o_we_xyzs <= '0';
                        when "1101"=>o_addr_mode <= AMOD_Xi;
                        when "1110"=>o_addr_mode <= AMOD_dX;
                        when "1111"=>o_addr_mode <= AMOD_SPd;
                        when others=>
                    end case;
                end if;

            when "100101"=>                           		-- 1001 01xx xxxx xxxx
                if (i_opcode(9) = '0') then                	-- 1001 010
                    case i_opcode(3 DOWNTO 0) is
                        when "0000"=>--  1001 010d dddd 0000 - COM Rd
                            o_alu_opcode <= CPU_COM;
                            o_we_a_regs <= "01";
                            o_we_status <= '1';

                        when "0001"=>--  1001 010d dddd 0001 - NEG Rd
                            o_alu_opcode <= CPU_NEG;
                            o_we_a_regs <= "01";
                            o_we_status <= '1';

                        when "0010"=>--  1001 010d dddd 0010 - SWAP Rd
                            o_alu_opcode <= CPU_SWA;
                            o_we_a_regs <= "01";
                            o_we_status <= '1';

                        when "0011"=>--  1001 010d dddd 0011 - INC Rd
                            o_alu_opcode <= CPU_INC;
                            o_we_a_regs <= "01";
                            o_we_status <= '1';

                        when "0101"=>--  1001 010d dddd 0101 - ASR Rd
                            o_alu_opcode <= CPU_ASR;
                            o_we_a_regs <= "01";
                            o_we_status <= '1';

                        when "0110"=>--  1001 010d dddd 0110 - LSR Rd
                            o_alu_opcode <= CPU_LS;
                            o_we_a_regs <= "01";
                            o_we_status <= '1';

                        when "0111"=>--  1001 010d dddd 0111 - ROR Rd
                            o_alu_opcode <= CPU_ROR;
                            o_we_a_regs <= "01";
                            o_we_status <= '1';
                            
                        when "1000" =>            			-- 1001 010x xxxx 1000
                            if i_opcode(8) = '0' then  		-- 1001 0100 xxxx 1000
                                --  1001 0100 0sss 1000 - BSET
                                --  1001 0100 1sss 1000 - BCLR
                                    o_opc_pc(3 DOWNTO 0) <= i_opcode(7 DOWNTO 4);
                                    o_alu_opcode <= CPU_SRE;
                                    o_we_status <= '1';
                            else--  1001 0101 xxxx 1000
                                --  1001 0101 0000 1000 - RET
                                --  1001 0101 0001 1000 - RETI
                                --  1001 0101 1000 1000 - SLEEP
                                --  1001 0101 1001 1000 - BREAK
                                --  1001 0101 1100 1000 - LPM     [ R0,(Z) ]
                                --  1001 0101 1101 1000 - ELPM    not mega8
                                --  1001 0101 1110 1000 - SPM
                                --  1001 0101 1111 1000 - SPM #2
                                --  1001 0101 1010 1000 - WDR
                                case i_opcode(7 DOWNTO 4) is
                                    when "0000"=> -- RET
                                        o_addr_mode <= AMOD_iiSP;
                                        o_data_mem_read <= i_first_cycle;
                                        o_we_xyzs <= not i_first_cycle;
                                        if (i_first_cycle = '0') then
                                            o_pc_opcode <= PC_LD_S;
                                        end if;
                                    when "0001"=> -- RETI
                                        o_alu_opcode <= CPU_INT;
                                        o_immidiate_data(6) <= '1';
                                        o_addr_mode <= AMOD_iiSP;
                                        o_data_mem_read <= i_first_cycle;
                                        o_we_status    <= not i_first_cycle;  -- I flag
                                        o_we_xyzs <= not i_first_cycle;
                                        if (i_first_cycle = '0') then
                                            o_pc_opcode <= PC_LD_S;
                                        end if;
                                    when "1100"=> -- (i) LPM R0, (Z)
                                        o_reg1_addr <= "00000";
                                        o_addr_mode <= AMOD_Z;
                                        o_prog_mem_sel <= '1';
                                        o_we_a_regs <= '0' & not i_first_cycle;
                                    when "1110"=> -- SPM
                                        o_alu_opcode <= CPU_MV1;
                                        o_reg1_addr <= "00000";
                                        o_addr_mode <= AMOD_Z;
                                        o_prog_mem_sel <= '1';
                                        o_we_mem <= "01";
                                    when "1111"=> -- SPM #2
                                    when others=>
                                end case;
                            end if;

                        when "1001"=>-- 1001 010x xxxx 1001
                            --  1001 0100 0000 1001 IJMP
                            --  1001 0100 0001 1001 EIJMP   -- not on mega8
                            --  1001 0101 0000 1001 ICALL
                            --  1001 0101 0001 1001 EICALL   -- not on mega8
                            
                            o_pc_opcode <= PC_LD_Z;
                            if (i_opcode(8) = '1') then        -- ICALL
                                o_alu_opcode <= CPU_PC1;
                                o_addr_mode <= AMOD_SPdd;
                                o_we_mem <= "11";
                                o_we_xyzs <= '1';
                            end if;
                            
                        when "1010" => -- 1001 010x xxxx 1010
                            --  1001 010d dddd 1010 - DEC Rd
                            o_alu_opcode <= CPU_DEC;
                            o_we_a_regs <= "01";
                            o_we_status <= '1';
                        when "1011" =>-- 1001 010x xxxx 1011
                            --  1001 0100 KKKK 1011 - DES   -- not mega8
                                
                        when "1100" | "1101" =>
                            --  1001 010k kkkk 110k - JMP (k = 0 for 16 bit)
                            --  kkkk kkkk kkkk kkkk
                            o_pc_opcode <= PC_LD_I;
                        when "1110" | "1111" =>  	-- 1001 010x xxxx 111x
                            --  1001 010k kkkk 111k - CALL (k = 0)
                            --  kkkk kkkk kkkk kkkk
                            o_alu_opcode <= CPU_PC2;
                            o_addr_mode <= AMOD_SPdd;
                            o_pc_opcode <= PC_LD_I;
                            o_we_mem <= "11";     -- both PC bytes
                            o_we_xyzs <= '1';

                        when others=>
                    end case;
                else -- i_opcode(9) = 0/1
                
                 
                
				 -- 1001 0110 KKdd KKKK - ADIW
				 -- 1001 0111 KKdd KKKK - SBIW
				 if (i_opcode(8) = '0') then 
				 	o_alu_opcode <= CPU_ADIW;
				 else 
				 	o_alu_opcode <= CPU_SBIW;
				 end if;
				 o_immidiate_data(5 downto 4) <= i_opcode(7 downto 6);
				 o_immidiate_data(3 downto 0) <= i_opcode(3 downto 0);
				 o_alu_im_sel <= ALU_IMM;
				 o_reg1_addr <= "11" & i_opcode(5 downto 4) & "0";
				
				 o_we_a_regs <= "11";
				 o_we_status <= '1';
				 end if; -- I_OPC(9) = 0/1
				 
            when "000100"=>-- 0001 00rd dddd rrrr - CPSE
                o_alu_opcode <= CPU_SUB;
                if (i_first_cycle = '0') then        -- second cycle.
                    o_pc_opcode <= PC_SKIP_Z;
                end if;
            when "100110"=> -- 1001 10xx xxxx xxxx
                --  1001 1000 AAAA Abbb - CBI  - Clear Bit in I/O Register
                --  1001 1001 AAAA Abbb - SBIS - Subtract Immediate with Carry SBI - Set Bit in I/O Registe
                --  1001 1010 AAAA Abbb - SBI  - Set Bit in I/O Registe
                --  1001 1001 AAAA Abbb - SBIC - Skip if Bit in I/O Register is Cleared
                o_alu_opcode <= CPU_BITCS;
                o_addr_mode <= AMOD_ABS;
                o_opc_pc(3) <= i_opcode(9);   -- set/clear
                -- IMM = AAAAAA + 0x20
                o_immidiate_data(4 DOWNTO 0) <= i_opcode(7 DOWNTO 3);
                o_immidiate_data(6 DOWNTO 5) <= "01";

                o_data_mem_read <= i_first_cycle;
                if ((i_opcode(8) = '0') ) then     	-- CBI or SBI
                    o_we_mem(0) <= '1';
					else                            -- SBIC or SBIS
                    if (i_first_cycle = '0') then   -- second cycle.
                        o_pc_opcode <= PC_SKIP_T;
                    end if;
                end if;
			when "100111" => -- MUL
			 -- 1001 11rd dddd rrrr - MU
				 o_alu_opcode <= CPU_MULT;
				 o_immidiate_data(7 downto 5) <= "000"; -- -MUL UU;
				 o_we_01_regs <= '1';
				 o_we_status <= '1';

            when "101100" | "101101"=> -- 1011 0AAd dddd AAAA IN
                o_alu_im_sel <= ALU_DATA;
                o_addr_mode <= AMOD_ABS;
                -- IMM = AAAAAA
                -- + 010000 (0x20)
                o_immidiate_data(3 DOWNTO 0) <= i_opcode(3 DOWNTO 0);
                o_immidiate_data(4) <= i_opcode(9);
                -- '0' &  is for making it 2 bite width
 				o_immidiate_data(6 DOWNTO 5) <=  std_logic_vector(1 + unsigned('0' & i_opcode(10 downto 10)));
                o_data_mem_read <= '1';
                o_we_a_regs <= "01";

            when "101110" | "101111"=>--1011 1AAr rrrr AAAA - OUT 
                o_alu_opcode <= CPU_MV1;
                o_addr_mode <= AMOD_ABS;
                -- IMM = AAAAAA
                -- + 010000 (0x20) -- ofset
                o_immidiate_data(3 DOWNTO 0) <= i_opcode(3 DOWNTO 0);
                o_immidiate_data(4) <= i_opcode(9);
                o_immidiate_data(6 DOWNTO 5) <= std_logic_vector(1 + unsigned('0' & i_opcode(10 downto 10)));
                o_we_mem <= "01";

		    when "111000" | "111001" | "111010" | "111011"=>-- LDI	1110 KKKK dddd KKKK 
                o_alu_opcode <= CPU_MV2;
                o_alu_im_sel <= ALU_IMM;
                o_reg1_addr <= '1' & i_opcode(7 DOWNTO 4);     -- 16..31
                o_immidiate_data(7 DOWNTO 0) <= i_opcode(11 DOWNTO 8) & i_opcode(3 DOWNTO 0);
                o_we_a_regs <= "01";
                
            when "110000" | "110001" | "110010" | "110011"=>-- 1100 kkkk kkkk kkkk - RJMP
                o_jump_addr <= std_logic_vector(unsigned(i_pc) +1 + unsigned(i_opcode(11 downto 0)));
                o_pc_opcode <= PC_LD_I;

            when "110100" | "110101" | "110110" | "110111"=>-- 1101 kkkk kkkk kkkk - RCALL
                o_jump_addr <= std_logic_vector(unsigned(i_pc) +1 + unsigned(i_opcode(11 downto 0)));
                o_pc_opcode <= PC_LD_I;
                
                o_alu_opcode <= CPU_PC1;
                o_addr_mode <= AMOD_SPdd;
                o_we_mem <= "11";     -- both PC bytes
                o_we_xyzs <= '1';

            when "111100" | "111101"=>
                -- 1111 00kk kkkk kbbb - BRBS  Branch if Bit in SREG is Set
                -- 1111 01kk kkkk kbbb - BRBC  Branch if Bit in SREG is Cleared
                -- bbb	 	status register bit
                -- v 		value (set/cleared) of status register bit
                -- k 		value of the jump PC = PC+k+1.
                -- k integer from -63 to 64, should be signed
                -- Addition is the same regardless of whether it's signed or unsigned, at least when you're letting it overflow
                -- But it has to be resized to size of pc such as overflow will work. Highest bit has to be replicated to all new bits
                --k_vector(15 downto 7) 	<= (others => i_opcode(9));
               -- k_vector(6 downto 0) 	<= i_opcode(9 DOWNTO 3);
                --resize(signed(i_opcode(9 DOWNTO 3)), 15)
--              k_vector <= i_opcode(9) & i_opcode(9) & i_opcode(9) & i_opcode(9)
--                                & i_opcode(9) & i_opcode(9) & i_opcode(9) & i_opcode(9)
--                                & i_opcode(9) & i_opcode(9 DOWNTO 3))
				--from numeric std documentation:
			 -- Id: R.1
			 -- function RESIZE (ARG: SIGNED; NEW_SIZE: NATURAL) return SIGNED;
			  -- Result subtype: SIGNED(NEW_SIZE-1 downto 0)
			  -- Result: Resizes the SIGNED vector ARG to the specified size.
			  --         To create a larger vector, the new [leftmost] bit positions
			  --         are filled with the sign bit (ARG'LEFT). When truncating,
			  --         the sign bit is retained along with the rightmost part.
			
			  -- Id: R.2
			  --function RESIZE (ARG: UNSIGNED; NEW_SIZE: NATURAL) return UNSIGNED;
			  -- Result subtype: UNSIGNED(NEW_SIZE-1 downto 0)
			  -- Result: Resizes the SIGNED vector ARG to the specified size.
			  --         To create a larger vector, the new [leftmost] bit positions
			  --         are filled with '0'. When truncating, the leftmost bits
			  --         are dropped
			  
			  	-- i_pc can be signed, that shouldnt be important
                o_jump_addr <= std_logic_vector(signed(i_pc) +1 + resize(signed(i_opcode(9 DOWNTO 3)), 15));
                o_pc_opcode <= PC_CC;

            when "111110"=>-- 1111 10xx xxxx xxxx
                -- 1111 100d dddd 0bbb - BLD
                -- 1111 101d dddd 0bbb - BST
                if i_opcode(9) = '0' then  	-- BLD: T flag to register
                    o_alu_opcode <= CPU_BLD;
                    o_we_a_regs <= "01";
                else                    	-- BST: register to T flag
                    o_addr_mode <= AMOD_ABS;
                    o_opc_pc(3) <= i_opcode(10);
                    o_immidiate_data(4 DOWNTO 0) <= i_opcode(8 DOWNTO 4);
                    o_alu_opcode <= CPU_BITCS;
                    o_we_status <= '1';
                end if;

            when "111111"=>
                -- 1111 110r rrrr 0bbb - SBRC
                -- 1111 111r rrrr 0bbb - SBRS
                -- like SBIC, but and general purpose regs instead of I/O regs.
                o_alu_opcode <= CPU_BITCS;
                o_addr_mode <= AMOD_ABS;
                o_opc_pc(3) <= i_opcode(9);   -- set/clear bit
                o_immidiate_data(4 DOWNTO 0) <= i_opcode(8 DOWNTO 4);
                if (i_first_cycle = '0') then
                    o_pc_opcode <= PC_SKIP_T;
                end if;

            when others=>
        end case;
    end if;
    end process;
end Behavioral;