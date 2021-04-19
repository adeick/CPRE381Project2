-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- MIPS_Processor.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a pipelined MIPS_Processor  
-- implementation.

-- 01/29/2019 by H3::Design created.
-------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

entity MIPS_processor is
  generic(N : integer := 32);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0)); 
end  MIPS_processor;


architecture structure of MIPS_processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic; -- TODO: use this signal as the final active high data memory write enable signal
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
  signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
  signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output
 
  -- Required register file signals 
  signal s_RegWr        : std_logic; -- TODO: use this signal as the final active high write enable input to the register file
  signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- TODO: use this signal as the final destination register address input
  signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_NextInstAddr instead
  signal s_NextInstAddr : std_logic_vector(N-1 downto 0); -- TODO: use this signal as your intended final instruction memory address input.
  signal s_Inst         : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the instruction signal 

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. (Opcode: 01 0100)

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;  -- TODO: this signal indicates an overflow exception would have been initiated


---------------------------- Added Signals ---------------------------------------

----------------------------- IF STAGE signals -----------------------------------
  signal s_PCPlusFour_IF   : std_logic_vector(N-1 downto 0);
  signal s_Inst_IF         : std_logic_vector(N-1 downto 0);
----------------------------------------------------------------------------------

----------------------------- ID STAGE signals -----------------------------------
  signal s_PCPlusFour_ID   : std_logic_vector(N-1 downto 0);
  signal s_Inst_ID         : std_logic_vector(N-1 downto 0);
  signal s_imm16_ID : std_logic_vector(15 downto 0); --instruction bits [15-0]
  signal s_imm32_ID : std_logic_vector(31 downto 0); --after extension
  signal s_jumpAddress_ID  : std_logic_vector(N-1 downto 0);
  signal s_Ctrl_ID  : std_logic_vector(14 downto 0); --Control Brick Output, each bit is a different switch

  -- reg file signals
  signal s_RegOutReadData1_ID : std_logic_vector(N-1 downto 0);
  signal s_RegOutReadData2_ID : std_logic_vector(N-1 downto 0);

----------------------------------------------------------------------------------

----------------------------- EX STAGE signals -----------------------------------
  signal s_PCPlusFour_EX   : std_logic_vector(N-1 downto 0);
  signal s_RegOutReadData1_EX : std_logic_vector(N-1 downto 0);
  signal s_RegOutReadData2_EX : std_logic_vector(N-1 downto 0);
  signal s_imm32_EX : std_logic_vector(31 downto 0); --after extension
  signal s_jumpAddress_EX  : std_logic_vector(N-1 downto 0);
  signal s_Ctrl_EX  : std_logic_vector(14 downto 0); --Control Brick Output, each bit is a different switch

  signal s_rt_EX, s_rd_EX : std_logic_vector(4 downto 0);
----------------------------------------------------------------------------------

----------------------------- MEM STAGE signals ----------------------------------
  signal s_PCPlusFour_MEM   : std_logic_vector(N-1 downto 0);

----------------------------------------------------------------------------------

----------------------------- WB STAGE signals ----------------------------------
  signal s_PCPlusFour_WB   : std_logic_vector(N-1 downto 0);

----------------------------------------------------------------------------------


  signal s_shamt: std_logic_vector(4 downto 0);


  signal s_imm32x4 : std_logic_vector(31 downto 0); --after multiplication
  signal s_immMuxOut : std_logic_vector(N-1 downto 0); --Output of Immediate Mux (ALU 2nd input)

  signal s_opCode   : std_logic_vector(5 downto 0);--instruction bits[31-26] 
  signal s_funcCode : std_logic_vector(5 downto 0);--instruction bits[5-0]
  
  signal s_inputPC: std_logic_vector(31 downto 0); --wire from the jump mux


  --Control Signals
  signal s_ALUSrc    : std_logic; 
  signal s_jr    : std_logic; 
  signal s_jal    : std_logic; 
  signal s_ALUOp     : std_logic_vector(3 downto 0); --ALU Code
  signal s_MemtoReg    : std_logic; 
  signal s_RegDst       : std_logic;
  signal s_Branch        : std_logic;

  signal s_jump     : std_logic; 

  --Addressing Signals
  signal s_PCPlusFour   : std_logic_vector(N-1 downto 0);

  signal s_branchAddress: std_logic_vector(N-1 downto 0);
  signal s_MemToReg0    : std_logic_vector(31 downto 0);
  signal s_RegDst0      : std_logic_vector(4 downto 0);

  signal s_normalOrBranch,s_finalJumpAddress : std_logic_vector(31 downto 0);
  
--ALU Items
--Inputs:
  -- s_RegOutReadData1 and s_immMuxOut
  -- s_ALUOp
--Outputs:
signal s_ALUBranch: std_logic;
--  s_ALUResult is named s_DMemAddr

signal s1, s2, s3 : std_logic; --don't care output from adder and ALU

----------------------------------------------------------------------------------------------------
--------------------------------- Component Decleration --------------------------------------------
----------------------------------------------------------------------------------------------------
  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
          data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
          we           : in std_logic := '1';
          q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
    end component;

  -- TODO: You may add any additional signals or components your implementation 
  --       requires below this comment
  component control_unit is
    port( i_opcode  	: in std_logic_vector(5 downto 0);
	        i_funct	  	: in std_logic_vector(5 downto 0);
	        o_Ctrl_Unt	: out std_logic_vector(14 downto 0));
  end component;

  component regfile is 
  port(clk			: in std_logic;
      i_wA		: in std_logic_vector(4 downto 0); --Write Address
      i_wD		: in std_logic_vector(31 downto 0); --Write Data
      i_wC		: in std_logic; --WriteControl aka RegWrite
      i_r1		: in std_logic_vector(4 downto 0); --Read 1
      i_r2		: in std_logic_vector(4 downto 0); --Read 2
      reset		: in std_logic;           --Reset
      o_d1        : out std_logic_vector(31 downto 0); --Output Data 1
      o_d2        : out std_logic_vector(31 downto 0)); --Output Data 2
  end component; --Andrew's component

  component extender is
  port(i_I          : in std_logic_vector(15 downto 0);     -- Data value input
	     i_C		      : in std_logic; --0 for zero, 1 for signextension
       o_O          : out std_logic_vector(31 downto 0));   -- Data value output
  end component; --Andrew's component

  component mux2t1_N is
    generic(N : integer := 16); -- Generic of type integer for input/output data width. Default value is 32.
    port(i_S          : in std_logic;
       i_D0         : in std_logic_vector(N-1 downto 0);
       i_D1         : in std_logic_vector(N-1 downto 0);
       o_O          : out std_logic_vector(N-1 downto 0));
  end component;

  component addersubtractor is
    generic(N : integer := 32); -- Generic of type integer for input/output data width. Default value is 32.
    port( nAdd_Sub: in std_logic;
	        i_A 	  : in std_logic_vector(N-1 downto 0);
		      i_B		  : in std_logic_vector(N-1 downto 0);
		      o_Y		  : out std_logic_vector(N-1 downto 0);
		      o_Cout	: out std_logic);
  end component;

  component alu is
    port(i_A    : in std_logic_vector(31 downto 0);
           i_B        : in std_logic_vector(31 downto 0);
           i_aluOp    : in std_logic_vector(3 downto 0);
           i_shamt    : in std_logic_vector(4 downto 0);
           o_F        : out std_logic_vector(31 downto 0);
           overFlow   : out std_logic;
           zero       : out std_logic);
  end component;

  component MIPS_pc is 
  port(
    i_CLK : in std_logic; --=> iClk,
    i_RST : in std_logic; --=> iRST,
    i_D   : in std_logic_vector(31 downto 0); --s_inputPC, 
    o_Q   : out std_logic_vector(31 downto 0));--=> s_NextInstAddr);
  end component;

------------- Stages Components --------------------
  component IF_ID_reg is 
	port(i_CLK		: in std_logic;
	     i_RST		: in std_logic; -- (1 sets reg to 0)
	     i_PC_4		: in std_logic_vector(31 downto 0);
	     i_instruction  	: in std_logic_vector(31 downto 0);
	     o_PC_4	  	: out std_logic_vector(31 downto 0);
	     o_instruction	: out std_logic_vector(31 downto 0));
  end component;

  component ID_EX_reg is 
	port(i_CLK		: in std_logic;
	     i_RST		: in std_logic; -- (1 sets reg to 0)

	     i_PC_4		: in std_logic_vector(31 downto 0);
	     i_readData1 	: in std_logic_vector(31 downto 0);
	     i_readData2 	: in std_logic_vector(31 downto 0);
	     i_signExtImmed 	: in std_logic_vector(31 downto 0);
	     i_jumpAddress 	: in std_logic_vector(31 downto 0);
	     i_instr_20_16 	: in std_logic_vector(4 downto 0);
	     i_instr_15_11 	: in std_logic_vector(4 downto 0);
	     i_control_bits 	: in std_logic_vector(14 downto 0);

	     o_PC_4		: out std_logic_vector(31 downto 0);
	     o_readData1 	: out std_logic_vector(31 downto 0);
	     o_readData2 	: out std_logic_vector(31 downto 0);
	     o_signExtImmed 	: out std_logic_vector(31 downto 0);
	     o_jumpAddress 	: out std_logic_vector(31 downto 0);
	     o_instr_20_16 	: out std_logic_vector(4 downto 0);
	     o_instr_15_11 	: out std_logic_vector(4 downto 0);
	     o_control_bits 	: out std_logic_vector(14 downto 0));
  end component;

  component EX_MEM_reg is 
	port(i_CLK		: in std_logic;
	     i_RST		: in std_logic; -- (1 sets reg to 0)

	     i_PC_4		: in std_logic_vector(31 downto 0);
	     i_finalJumpAddr	: in std_logic_vector(31 downto 0);
	     i_branchAddr	: in std_logic_vector(31 downto 0);
	     i_readData2 	: in std_logic_vector(31 downto 0);
	     i_aluOut	 	: in std_logic_vector(31 downto 0);

	     i_writeReg 	: in std_logic_vector(4 downto 0);

	-- one bit inputs
	     i_zero		: in std_logic;
	     i_overflow		: in std_logic;
	     i_jal		: in std_logic;
	     i_MemtoReg		: in std_logic;
	     i_weMem		: in std_logic;
	     i_weReg		: in std_logic;
	     i_branch		: in std_logic;
	     i_j		: in std_logic;
	     i_halt		: in std_logic;

	     o_PC_4		: out std_logic_vector(31 downto 0);
	     o_finalJumpAddr	: out std_logic_vector(31 downto 0);
	     o_branchAddr	: out std_logic_vector(31 downto 0);
	     o_readData2 	: out std_logic_vector(31 downto 0);
	     o_aluOut	 	: out std_logic_vector(31 downto 0);

	     o_writeReg 	: out std_logic_vector(4 downto 0);

	-- one bit outputs
	     o_zero		: out std_logic;
	     o_overflow		: out std_logic;
	     o_jal		: out std_logic;
	     o_MemtoReg		: out std_logic;
	     o_weMem		: out std_logic;
	     o_weReg		: out std_logic;
	     o_branch		: out std_logic;
	     o_j		: out std_logic;
	     o_halt		: out std_logic);
  end component;

  component MEM_WB_reg is 
	port(i_CLK		: in std_logic;
	     i_RST		: in std_logic; -- (1 sets reg to 0)

	     i_PC_4		: in std_logic_vector(31 downto 0);
	     i_finalJumpAddr	: in std_logic_vector(31 downto 0);
	     i_branchAddr	: in std_logic_vector(31 downto 0);
	     i_memReadData 	: in std_logic_vector(31 downto 0);
	     i_aluOut	 	: in std_logic_vector(31 downto 0);

	     i_writeReg 	: in std_logic_vector(4 downto 0);

	-- one bit inputs
	     i_branchCheck	: in std_logic;
	     i_overflow		: in std_logic;
	     i_jal		: in std_logic;
	     i_MemtoReg		: in std_logic;
	     i_weReg		: in std_logic;
	     i_j		: in std_logic;
	     i_halt		: in std_logic;

	     o_PC_4		: out std_logic_vector(31 downto 0);
	     o_finalJumpAddr	: out std_logic_vector(31 downto 0);
	     o_branchAddr	: out std_logic_vector(31 downto 0);
	     o_memReadData 	: out std_logic_vector(31 downto 0);
	     o_aluOut	 	: out std_logic_vector(31 downto 0);

	     o_writeReg 	: out std_logic_vector(4 downto 0);

	-- one bit outputs
	     o_branchCheck	: out std_logic;
	     o_overflow		: out std_logic;
	     o_jal		: out std_logic;
	     o_MemtoReg		: out std_logic;
	     o_weReg		: out std_logic;
	     o_j		: out std_logic;
	     o_halt		: out std_logic);
  end component;

----------------------------------------------------------------------------------------------------
--------------------------------- Hardware Definiton -----------------------------------------------
----------------------------------------------------------------------------------------------------
begin
  
------------------------------------------------------------------------------------
--------------------------------- IF STAGE -----------------------------------------
------------------------------------------------------------------------------------

 -- added by professor in orginial code
  with iInstLd select
    s_IMemAddr <= s_NextInstAddr when '0',
      iInstAddr when others;

  pcReg: MIPS_pc
    port map(i_CLK => iClk,
    	     i_RST => iRST,
             i_D   => -- TODO, 
             o_Q   => s_NextInstAddr);

  IMem: mem
    generic map(ADDR_WIDTH => 10,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(11 downto 2),
             data => iInstExt,
             we   => iInstLd,
             q    => s_Inst_IF);

  addFour: addersubtractor
    generic map(N => 32)
    port map(nAdd_Sub => '0',--in std_logic;
             i_A      => s_IMemAddr,--in std_logic_vector(N-1 downto 0);
             i_B      => x"00000004",--in std_logic_vector(N-1 downto 0);
             o_Y      => s_PCPlusFour_IF,--out std_logic_vector(N-1 downto 0);
             o_Cout   => s1);--out std_logic);

  IF_ID: IF_ID_reg
    port map(i_CLK	   => iCLK,
	     i_RST	   => iRST,
	     i_PC_4	   => s_PCPlusFour_IF,
	     i_instruction => s_Inst_IF,
	     o_PC_4	   => s_PCPlusFour_ID,
	     o_instruction => s_Inst_ID);

------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--------------------------------- ID STAGE -----------------------------------------
------------------------------------------------------------------------------------

  -- instruction decode
  s_imm16_ID(15 downto 0) <= s_Inst_ID(15 downto 0); --bits[15-0] into Sign Extender
  s_funcCode(5 downto 0) <= s_Inst_ID(5 downto 0); --bits[5-0] into ALU Control 
  s_opCode(5 downto 0) <= s_Inst_ID(31 downto 26); --bits[26-31] into Control Brick (bits[5-0)

  control: control_unit
    port map(i_opcode   => s_opCode, --in std_logic_vector(5 downto 0);
             i_funct    => s_funcCode, --in std_logic_vector(5 downto 0);
             o_Ctrl_Unt => s_Ctrl); --out std_logic_vector(11 downto 0));

  -- shift two and put instruction and PC+4 into s_jumpAddress
  s_jumpAddress_ID(0) <= '0';
  s_jumpAddress_ID(1) <= '0'; --Set first two bits to zero
  s_jumpAddress_ID(27 downto 2) <= s_Inst_ID(25 downto 0); --Instruction bits[25-0] into bits[27-2] of jumpAddr
  s_jumpAddress_ID(31 downto 28) <= s_PCPlusFour(31 downto 28); --PC+4 bits[31-28] into bits[31-28] of jumpAddr

  --RegFile: --
  registers: regfile 
    port map(clk   => iCLK,--std_logic;
	     i_wA  => --TODO ,--std_logic_vector(4 downto 0);
	     i_wD	 => --TODO ,--std_logic_vector(31 downto 0);
	     i_wC	 => --TODO ,--std_logic;
	     i_r1	 => s_Inst_ID(25 downto 21),-- rs;
	     i_r2	 => s_Inst_ID(20 downto 16),-- rt;
	     reset => iRST,--std_logic;
    	     o_d1  => s_RegOutReadData1_ID,-- std_logic_vector(31 downto 0);
    	     o_d2  => s_RegOutReadData2_ID);-- std_logic_vector(31 downto 0));

  signExtender: extender
    port map(i_I => s_imm16_ID, --in std_logic_vector(15 downto 0);     -- Data value input
	     i_C => s_Ctrl_ID(2), -- signExt control bit; --0 for zero, 1 for sign-extension
             o_O => s_imm32_ID); --out std_logic_vector(31 downto 0));   -- Data value output);

  ID_EX: ID_EX_reg
    port map(i_CLK	    => iCLK,
	     i_RST	    => iRST,

	     i_PC_4	    => s_PCPlusFour_ID,
	     i_readData1    => s_RegOutReadData1_ID,
	     i_readData2    => s_RegOutReadData2_ID,
	     i_signExtImmed => s_imm32_ID,
	     i_jumpAddress  => s_jumpAddress_ID,
	     i_instr_20_16  => s_Inst_ID(20 downto 16), -- rt
	     i_instr_15_11  => s_Inst_ID(15 downto 11), -- rd
	     i_control_bits => s_Ctrl_ID,

	     o_PC_4	    => s_PCPlusFour_EX,
	     o_readData1    => s_RegOutReadData1_EX,
	     o_readData2    => s_RegOutReadData2_EX,
	     o_signExtImmed => s_imm32_EX,
	     o_jumpAddress  => s_jumpAddress_EX,
	     o_instr_20_16  => s_rt_EX,
	     o_instr_15_11  => s_rd_EX,
	     o_control_bits => s_Ctrl_EX);

------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--------------------------------- EX STAGE -----------------------------------------
------------------------------------------------------------------------------------

  controlSlice: process(s_Ctrl)
  begin
    --Control Signals
    s_jr <= s_Ctrl(14);
    s_jal <= s_Ctrl(13);
    s_ALUSrc <= s_Ctrl(12);
    s_ALUOp(3 downto 0) <= s_Ctrl(11 downto 8);
    s_MemtoReg <= s_Ctrl(7);
    s_DMemWr <= s_Ctrl(6); 
    s_RegWr <= s_Ctrl(5);
    s_RegDst   <= s_Ctrl(4);
    s_Branch    <= s_Ctrl(3);
    s_SignExt  <= s_Ctrl(2);
    s_jump     <= s_Ctrl(1);

    s_Halt <= s_Ctrl(0);
  end process;



  jumpAddresses: process(s_PCPlusFour_ID, s_imm32_ID)
  begin
    --Calculate Branch Address Offset
    s_imm32x4(0) <= '0';
    s_imm32x4(1) <= '0'; --Set first two bits to zero
    s_imm32x4(31 downto 2) <= s_imm32_ID(29 downto 0); --imm32 bits[29-0] into bits[31-2] of jumpAddr
	end process;


  branchAdder: addersubtractor
  generic map(N => 32)
  port map( nAdd_Sub => '0',--in std_logic;
            i_A 	   => s_PCPlusFour,--in std_logic_vector(N-1 downto 0);
            i_B		   => s_imm32x4,--in std_logic_vector(N-1 downto 0);
            o_Y		   => s_branchAddress,--out std_logic_vector(N-1 downto 0);
            o_Cout	 => s2);--out std_logic);


  mainALU: alu
    port map( i_A        => s_RegOutReadData1, -- in std_logic_vector(31 downto 0);
              i_B        => s_immMuxOut, -- in std_logic_vector(31 downto 0);
              i_aluOp    => s_ALUOp, -- in std_logic_vector(3 downto 0);
              i_shamt    => s_shamt, -- in std_logic_vector(4 downto 0);
              o_F        => s_DMemAddr, -- out std_logic_vector(31 downto 0);
              overFlow   => s_Ovfl, -- out std_logic;
              zero       => s_ALUBranch);-- out std_logic);

  -- Muxes
  ALUSrc: mux2t1_N
  generic map(N => 32) -- Generic of type integer for input/output data width. Default value is 32.
  port map(i_S   => s_ALUSrc,
        i_D0      => s_DMemData,
        i_D1      => s_imm32,
        o_O       => s_immMuxOut);

  jumpReg: mux2t1_N
  generic map(N => 32) 
  port map(i_S   => s_jr,
        i_D0      => s_jumpAddress,
        i_D1      => s_RegOutReadData1,
        o_O       => s_finalJumpAddress);
        
  jalData: mux2t1_N
  generic map(N => 32) 
  port map(i_S   => s_jal,
        i_D0      => s_DMemAddr, --This is the ALU Output
        i_D1      => s_PCPlusFour,
        o_O       => s_MemToReg0);
        
  jalAddr: mux2t1_N
  generic map(N => 5) 
  port map(i_S   => s_jal,
        i_D0      => s_RegInReadData2, --rt is taking the place of rd,
        i_D1      => "11111", -- register 31
        o_O       => s_RegDst0);

  RegDst: mux2t1_N
  generic map(N => 5) -- Generic of type integer for input/output data width. Default value is 32.
  port map(i_S   => s_RegDst,
        i_D0      => s_RegDst0, --output of jalAddr mux
        i_D1      => s_RegD, --rd
        o_O       => s_RegWrAddr);
  Branch: mux2t1_N
  generic map(N => 32) 
  port map(i_S    => (s_Branch AND s_ALUBranch),
        i_D0      => s_PCPlusFour, 
        i_D1      => s_branchAddress,
        o_O       => s_normalOrBranch);
  Jump: mux2t1_N
  generic map(N => 32) 
  port map(i_S    => s_jump,
        i_D0      => s_normalOrBranch, 
        i_D1      => s_finalJumpAddress,
        o_O       => s_inputPC);
  MemtoReg: mux2t1_N
  generic map(N => 32) 
  port map(i_S    => s_MemtoReg,
        i_D0      => s_MemToReg0, 
        i_D1      => s_DMemOut,
        o_O       => s_RegWrData);
  

  DMem: mem
    generic map(ADDR_WIDTH => 10,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(11 downto 2),
             data => s_DMemData,
             we   => s_DMemWr,
             q    => s_DMemOut);

   oALUOut <= s_DMemAddr; --oALU is for synthesis
  -- TODO: Ensure that s_Halt is connected to an output control signal produced from decoding the Halt instruction (Opcode: 01 0100)
  -- TODO: Ensure that s_Ovfl is connected to the overflow output of your ALU

  -- TODO: Implement the rest of your processor below this comment! 

end structure;
