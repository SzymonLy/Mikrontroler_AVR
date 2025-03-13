library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package CPU_intruction_set is
    -- ALU operations
    constant CPU_ADC    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000"; --add with carry
    constant CPU_ADD    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00001"; --add without carry
    constant CPU_ADIW   : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00010"; --add immediate to words
    constant CPU_SUB    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "11001"; --subtract 
    constant CPU_SBIW   : STD_LOGIC_VECTOR(4 DOWNTO 0) := "10111"; -- subtract imm
    constant CPU_AND    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00011";
    constant CPU_ASR    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00100";
    constant CPU_BLD    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00101"; 
    constant CPU_BITCS 	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "00110";
    constant CPU_COM    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00111";
    constant CPU_DEC    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "01000";
    constant CPU_EOR    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "01001";
    constant CPU_MV  	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "01010";
    constant CPU_INC    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "01011";
    constant CPU_INT   	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "01100";
    constant CPU_LS    	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "01101";  
    constant CPU_MV1 	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "01110";  
    constant CPU_MV2 	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "01111";  
    constant CPU_MULT   : STD_LOGIC_VECTOR(4 DOWNTO 0) := "10000";
    constant CPU_NEG    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "10001";
    constant CPU_OR     : STD_LOGIC_VECTOR(4 DOWNTO 0) := "10010";  
    constant CPU_PC1   	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "10011";  
    constant CPU_PC2   	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "10100";  
    constant CPU_ROR    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "10101";
    constant CPU_SBC    : STD_LOGIC_VECTOR(4 DOWNTO 0) := "10110"; 
    constant CPU_SRE   	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "11000";
    constant CPU_SWA   	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "11010";



    constant MULT_UU  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
    constant MULT_SU  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
    constant MULT_SS  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
    constant MULT_FUU : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
    constant MULT_FSU : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
    constant MULT_FSS : STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";


    constant ALU_REG  : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    constant ALU_IMM  : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
    constant ALU_DATA : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
    
    
    constant PC_NEXT    : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";    -- += 1
    constant PC_CC      : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";    -- IMM
    constant PC_LD_I    : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";    -- IMM
    constant PC_LD_Z    : STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";    -- Z
    constant PC_LD_S    : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";    -- SP
    constant PC_SKIP_Z  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";    -- SKIP if Z
    constant PC_SKIP_T  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";    -- SKIP if T
 

    -- Address source
    constant AS_SP  : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";     -- sp
    constant AS_Z   : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";     -- z
    constant AS_Y   : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";     -- y
    constant AS_X   : STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";     -- x
    constant AS_IMM : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";     -- imm
    
    -- Address offset
    constant AO_0   : STD_LOGIC_VECTOR(5 DOWNTO 3) := "000";     -- 0
    constant AO_Q   : STD_LOGIC_VECTOR(5 DOWNTO 3) := "010";     -- +q
    constant AO_i   : STD_LOGIC_VECTOR(5 DOWNTO 3) := "001";     -- +1
    constant AO_ii  : STD_LOGIC_VECTOR(5 DOWNTO 3) := "011";     -- +2
    constant AO_d   : STD_LOGIC_VECTOR(5 DOWNTO 3) := "101";     -- -1
    constant AO_dd  : STD_LOGIC_VECTOR(5 DOWNTO 3) := "111";     -- -2
    
    -- Address updated                             
    constant AM_WX : STD_LOGIC_VECTOR(3 DOWNTO 0) := '1' & AS_X;  -- X ++ 
    constant AM_WY : STD_LOGIC_VECTOR(3 DOWNTO 0) := '1' & AS_Y;  -- Y ++ 
    constant AM_WZ : STD_LOGIC_VECTOR(3 DOWNTO 0) := '1' & AS_Z;  -- Z ++ 
    constant AM_WS : STD_LOGIC_VECTOR(3 DOWNTO 0) := '1' & AS_SP; -- SP ++
    -- Address modes 
    constant AMOD_ABS : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_0  & AS_IMM; -- IMM
    constant AMOD_X   : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_0  & AS_X;   -- X
    constant AMOD_Xq  : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_Q  & AS_X;   -- X+q
    constant AMOD_Xi  : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_i  & AS_X;   -- X+
    constant AMOD_dX  : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_d  & AS_X;   -- -X
    constant AMOD_Y   : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_0  & AS_Y;   -- Y
    constant AMOD_Yq  : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_Q  & AS_Y;   -- Y+q
    constant AMOD_Yi  : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_i  & AS_Y;   -- Y+
    constant AMOD_dY  : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_d  & AS_Y;   -- -Y
    constant AMOD_Z   : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_0  & AS_Z;   -- Z
    constant AMOD_Zq  : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_Q  & AS_Z;   -- Z+q
    constant AMOD_Zi  : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_i  & AS_Z;   -- Z+
    constant AMOD_dZ  : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_d  & AS_Z;   -- -Z
    constant AMOD_iSP : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_i  & AS_SP;  -- +SP
    constant AMOD_iiSP: STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_ii & AS_SP;  -- ++SP
    constant AMOD_SPd : STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_d  & AS_SP;  -- SP-
    constant AMOD_SPdd: STD_LOGIC_VECTOR(5 DOWNTO 0) := AO_dd & AS_SP;  -- SP--
 


end CPU_intruction_set;
