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
----------------------------------------------------------------------------------
  signal s_PCPlusFour_IF, s_normAddress   : std_logic_vector(N-1 downto 0);
  signal s_InstOrNOP : std_logic_vector(31 downto 0);
  signal s_stall : std_logic;

----------------------------- ID STAGE signals -----------------------------------
----------------------------------------------------------------------------------
  signal s_PCPlusFour_ID   : std_logic_vector(N-1 downto 0);
  signal s_Inst_ID         : std_logic_vector(N-1 downto 0);
  signal s_imm16_ID : std_logic_vector(15 downto 0); --instruction bits [15-0]
  signal s_imm32_ID : std_logic_vector(31 downto 0); --after extension
  signal s_jumpAddress_ID  : std_logic_vector(N-1 downto 0);

  --control unit signals
  signal s_Ctrl_ID  : std_logic_vector(14 downto 0); --Control Brick Output, each bit is a different switch
  signal s_opCode   : std_logic_vector(5 downto 0);--instruction bits[31-26] 
  signal s_funcCode : std_logic_vector(5 downto 0);--instruction bits[5-0]

  -- reg file signals
  signal s_RegOutReadData1 : std_logic_vector(N-1 downto 0);
  signal s_RegOutReadData2 : std_logic_vector(N-1 downto 0);
  signal s_RegWrAddr_ID      : std_logic_vector(4 downto 0);

  -- forwarding signals
  signal s_fwdSwitch1, s_fwdSwitch2 : std_logic;

  --final signals
  signal s_DecodeData1_ID, s_DecodeData2_ID : std_logic_vector(31 downto 0);

----------------------------- EX STAGE signals -----------------------------------
----------------------------------------------------------------------------------
  signal s_PCPlusFour_EX   : std_logic_vector(N-1 downto 0);
  signal s_RegOutReadData1_EX : std_logic_vector(N-1 downto 0);
  signal s_RegOutReadData2_EX : std_logic_vector(N-1 downto 0);
  signal s_imm32_EX : std_logic_vector(31 downto 0); --after extension
  signal s_jumpAddress_EX  : std_logic_vector(N-1 downto 0);
  signal s_Ctrl_EX  : std_logic_vector(14 downto 0); --Control Brick Output, each bit is a different switch

  signal s_rt_EX, s_rd_EX : std_logic_vector(4 downto 0);
  signal s_finalJumpAddress_EX : std_logic_vector(31 downto 0);
  signal s_branchAddress_EX : std_logic_vector(31 downto 0);
  signal s_imm32x4 : std_logic_vector(31 downto 0); --after multiplication
  signal s_RegDst0      : std_logic_vector(4 downto 0);
  signal s_RegWrAddr_EX      : std_logic_vector(4 downto 0);

  
  --alu
  signal s_ALUSrc    : std_logic; 
  signal s_immMuxOut : std_logic_vector(N-1 downto 0); --Output of Immediate Mux (ALU 2nd input)
  signal s_shamt: std_logic_vector(4 downto 0);
  signal s_ALUOp     : std_logic_vector(3 downto 0); --ALU Code
  signal s_aluOut_EX : std_logic_vector(31 downto 0);
  signal s_ALUBranch_EX, s_Ovfl_EX: std_logic;

  --control signals
  signal s_jal_EX, s_RegDst_EX, s_MemtoReg_EX, s_DMemWr_EX, s_RegWr_EX, s_Branch_EX, s_jump_EX, s_Halt_EX : std_logic; 
  signal s_jr    : std_logic; 


----------------------------- MEM STAGE signals ----------------------------------
----------------------------------------------------------------------------------
  signal s_PCPlusFour_MEM   : std_logic_vector(N-1 downto 0);
  signal s_finalJumpAddress_MEM : std_logic_vector(31 downto 0);
  signal s_branchAddress_MEM : std_logic_vector(31 downto 0);
  signal s_RegOutReadData2_MEM : std_logic_vector(N-1 downto 0);
  signal s_aluOut_MEM : std_logic_vector(31 downto 0);
  signal s_ALUBranch_MEM, s_Ovfl_MEM: std_logic;
  signal s_RegWrAddr_MEM      : std_logic_vector(4 downto 0);

 --control signals
  signal s_jal_MEM, s_MemtoReg_MEM, s_DMemWr_MEM, s_RegWr_MEM, s_Branch_MEM, s_jump_MEM, s_Halt_MEM, s_branch_check_MEM    : std_logic; 


----------------------------- WB STAGE signals ----------------------------------
----------------------------------------------------------------------------------
  signal s_PCPlusFour_WB   : std_logic_vector(N-1 downto 0);
  signal s_aluOut_WB, s_finalJumpAddress_WB, s_branchAddress_WB, s_memReadData_WB : std_logic_vector(31 downto 0);
  signal s_MemToReg0    : std_logic_vector(31 downto 0);
  signal s_normalOrBranch  : std_logic_vector(31 downto 0);
  signal s_inputPC: std_logic_vector(31 downto 0); --wire from the jump mux

  --control signals
  signal s_jal_WB, s_MemtoReg_WB, s_jump_WB, s_branch_check_WB    : std_logic; 

----------------------------------------------------------------------------------

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

  component forwarding_unit is
	port(i_readAddr1  	  	: in std_logic_vector(4 downto 0);
	     i_readAddr2	  	: in std_logic_vector(4 downto 0);
	     i_writeAddr	  	: in std_logic_vector(4 downto 0);
         i_writeEnable      : in std_logic;
         o_fwdSwitch1		: out std_logic; --1 if forwarding should be used, 0 otherwise
         o_fwdSwitch2		: out std_logic);
    end component;

    component hazard_detector is
        port(   i_jump_ID          : in std_logic; --Control Hazards
                i_jump_EX          : in std_logic;
                i_jump_MEM         : in std_logic;
                i_jump_WB          : in std_logic;
                i_branch_ID        : in std_logic;
                i_branch_EX        : in std_logic;
                i_branch_MEM       : in std_logic;
                i_branch_WB        : in std_logic;
        
                i_readAddr1  	  	: in std_logic_vector(4 downto 0); --Data Hazards
                i_readAddr2	  	    : in std_logic_vector(4 downto 0);
                i_writeAddr_ID      : in std_logic_vector(4 downto 0);
                i_writeAddr_EX      : in std_logic_vector(4 downto 0);--Forwarding can handle if in WB stage
                i_writeEnable_ID    : in std_logic;
                i_writeEnable_EX    : in std_logic;
        
                o_stall    		: out std_logic); --1 if stalling, 0 otherwise
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
	     --i_instr_20_16 	: in std_logic_vector(4 downto 0);
	     --i_instr_15_11 	: in std_logic_vector(4 downto 0);
       i_regDst 	: in std_logic_vector(4 downto 0);
       i_control_bits 	: in std_logic_vector(14 downto 0);

	     o_PC_4		: out std_logic_vector(31 downto 0);
	     o_readData1 	: out std_logic_vector(31 downto 0);
	     o_readData2 	: out std_logic_vector(31 downto 0);
	     o_signExtImmed 	: out std_logic_vector(31 downto 0);
	     o_jumpAddress 	: out std_logic_vector(31 downto 0);
	     --o_instr_20_16 	: out std_logic_vector(4 downto 0);
	     --o_instr_15_11 	: out std_logic_vector(4 downto 0);
       o_regDst 	: out std_logic_vector(4 downto 0);
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
	     o_zero		  : out std_logic;
	     o_overflow	: out std_logic;
	     o_jal		  : out std_logic;
	     o_MemtoReg	: out std_logic;
	     o_weMem		: out std_logic;
	     o_weReg		: out std_logic;
	     o_branch		: out std_logic;
	     o_j		    : out std_logic;
	     o_halt		  : out std_logic);
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

 -- added by professor in original code
  with iInstLd select
    s_IMemAddr <= s_NextInstAddr when '0',
      iInstAddr when others;

  pcReg: MIPS_pc
    port map(i_CLK => iClk,
    	     i_RST => iRST,
             i_D   => s_inputPC, 
             o_Q   => s_NextInstAddr);

  IMem: mem
    generic map(ADDR_WIDTH => 10,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(11 downto 2),
             data => iInstExt,
             we   => iInstLd,
             q    => s_Inst);

  addFour: addersubtractor
    generic map(N => 32)
    port map(nAdd_Sub => '0',--in std_logic;
             i_A      => s_IMemAddr,--in std_logic_vector(N-1 downto 0);
             i_B      => x"00000004",--in std_logic_vector(N-1 downto 0);
             o_Y      => s_PCPlusFour_IF,--out std_logic_vector(N-1 downto 0);
             o_Cout   => s1);--out std_logic);

    hazardDetection: hazard_detector 
    port map(   
        i_jump_ID        => s_Ctrl_ID(1),  --: in std_logic; --Control Hazards
        i_jump_EX        => s_Ctrl_EX(1),  --: in std_logic;
        i_jump_MEM       => s_jump_MEM,  --: in std_logic;
        i_jump_WB        => s_jump_WB,  --: in std_logic;
        i_branch_ID      => s_Ctrl_ID(3),  --: in std_logic;
        i_branch_EX      => s_Ctrl_EX(3),  --: in std_logic;
        i_branch_MEM     => s_Branch_MEM,  --: in std_logic;
        i_branch_WB      => s_branch_check_WB,  --: in std_logic; --Named different because we know if we are 
                                                                    --branching or not
        i_readAddr1  	   => s_Inst(25 downto 21),	--: in std_logic_vector(4 downto 0); --Data Hazards
        i_readAddr2	  	 => s_Inst(20 downto 16),  --: in std_logic_vector(4 downto 0);
        i_writeAddr_ID   => s_RegWrAddr_ID,  --: in std_logic_vector(4 downto 0);
        i_writeAddr_EX   => s_RegWrAddr_EX,  --: in std_logic_vector(4 downto 0); --Forwarding can handle if in MEM stage
        i_writeEnable_ID => s_Ctrl_ID(5),  --: in std_logic;                    --If in WB stage, it won't need forwarding
        i_writeEnable_EX => s_RegWr_EX,  --: in std_logic;

        o_stall    		 =>  s_stall); --: out std_logic); --1 if stalling, 0 otherwise


    stallAddressing : mux2t1_N
    generic map(N => 32) 
    port map(i_S  => s_stall,
            i_D0 => s_PCPlusFour_IF, --PC+4
            i_D1 => s_IMemAddr, --PC
            o_O  => s_normAddress); --input to branch Mux

    stallInstruction : mux2t1_N 
    generic map(N => 32) 
    port map(i_S  => s_stall,
            i_D0 => s_Inst, --Normal Instruction if no stall
            i_D1 => x"00000000", --nop
            o_O  => s_InstOrNOP); --input to branch Mux

  IF_ID: IF_ID_reg
    port map(i_CLK	   => iCLK,
	     i_RST	   => iRST,
	     i_PC_4	   => s_PCPlusFour_IF,
	     i_instruction => s_InstOrNOP,
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
             o_Ctrl_Unt => s_Ctrl_ID); --out std_logic_vector(11 downto 0));

  -- shift two and put instruction and PC+4 into s_jumpAddress
  s_jumpAddress_ID(0) <= '0';
  s_jumpAddress_ID(1) <= '0'; --Set first two bits to zero
  s_jumpAddress_ID(27 downto 2) <= s_Inst_ID(25 downto 0); --Instruction bits[25-0] into bits[27-2] of jumpAddr
  s_jumpAddress_ID(31 downto 28) <= s_PCPlusFour_ID(31 downto 28); --PC+4 bits[31-28] into bits[31-28] of jumpAddr

    --Forwarding Unit--
    forward: forwarding_unit
    port map(i_readAddr1  	  	=>  s_Inst_ID(25 downto 21),--in std_logic_vector(4 downto 0);
             i_readAddr2	  	=>  s_Inst_ID(20 downto 16),--in std_logic_vector(4 downto 0);
             i_writeAddr	  	=>  s_RegWrAddr,--in std_logic_vector(4 downto 0);
             i_writeEnable      =>  s_RegWr,--in std_logic;
             o_fwdSwitch1		=>  s_fwdSwitch1,--out std_logic; --1 if forwarding should be used, 0 otherwise
             o_fwdSwitch2		=>  s_fwdSwitch2);--out std_logic);

  --RegFile: --
  registers: regfile 
    port map(clk   => iCLK,--std_logic;
	    i_wA  => s_RegWrAddr ,--std_logic_vector(4 downto 0);
	    i_wD  => s_RegWrData ,--std_logic_vector(31 downto 0);
	    i_wC  => s_RegWr ,--std_logic;
	    i_r1  => s_Inst_ID(25 downto 21),-- rs;
	    i_r2  => s_Inst_ID(20 downto 16),-- rt;
	    reset => iRST,--std_logic;
    	o_d1  => s_RegOutReadData1,-- std_logic_vector(31 downto 0);
    	o_d2  => s_RegOutReadData2);-- std_logic_vector(31 downto 0));

    --Forwarding Muxes
    fwdMux1: mux2t1_N
    generic map(N => 32) 
    port map(i_S  => s_fwdSwitch1,
          i_D0 => s_RegOutReadData1,
          i_D1 => s_RegWrData,
          o_O  => s_DecodeData1_ID);

    fwdMux2: mux2t1_N
    generic map(N => 32) 
    port map(i_S  => s_fwdSwitch2,
          i_D0 => s_RegOutReadData2,
          i_D1 => s_RegWrData,
          o_O  => s_DecodeData2_ID);


  signExtender: extender
    port map(i_I => s_imm16_ID, --in std_logic_vector(15 downto 0);     -- Data value input
	     i_C => s_Ctrl_ID(2), -- signExt control bit; --0 for zero, 1 for sign-extension
             o_O => s_imm32_ID); --out std_logic_vector(31 downto 0));   -- Data value output);

  jalAddr: mux2t1_N
    generic map(N => 5) 
    port map(i_S  => s_Ctrl_ID(4),
             i_D0 => s_Inst_ID(20 downto 16), --rt is taking the place of rd,
             i_D1 => "11111", -- register 31
             o_O  => s_RegDst0);

  RegDst: mux2t1_N
    generic map(N => 5) -- Generic of type integer for input/output data width. Default value is 32.
    port map(i_S  => s_Ctrl_ID(13),
             i_D0 => s_RegDst0, --output of jalAddr mux
             i_D1 => s_Inst_ID(15 downto 11), --rd
             o_O  => s_RegWrAddr_ID);

  ID_EX: ID_EX_reg
    port map(i_CLK	    => iCLK,
	     i_RST	    => iRST,

	     i_PC_4	    => s_PCPlusFour_ID,
	     i_readData1    => s_DecodeData1_ID, --s_RegOutReadData1, 
	     i_readData2    => s_DecodeData2_ID, --s_RegOutReadData2, 
	     i_signExtImmed => s_imm32_ID,
	     i_jumpAddress  => s_jumpAddress_ID,
	     --i_instr_20_16  => s_Inst_ID(20 downto 16), -- rt
	     --i_instr_15_11  => s_Inst_ID(15 downto 11), -- rd
	     i_regDst => s_RegWrAddr_ID,
       i_control_bits => s_Ctrl_ID,

	     o_PC_4	        => s_PCPlusFour_EX,
	     o_readData1    => s_RegOutReadData1_EX,
	     o_readData2    => s_RegOutReadData2_EX,
	     o_signExtImmed => s_imm32_EX,
	     o_jumpAddress  => s_jumpAddress_EX,
	     --o_instr_20_16  => s_rt_EX,--
	     --o_instr_15_11  => s_rd_EX,--remove
       o_regDst => s_RegWrAddr_EX,
	     o_control_bits => s_Ctrl_EX);

------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--------------------------------- EX STAGE -----------------------------------------
------------------------------------------------------------------------------------

  -- control bits used in EX stage
  s_jr 		      <= s_Ctrl_EX(14);
  s_ALUOp(3 downto 0) <= s_Ctrl_EX(11 downto 8);
  s_ALUSrc 	      <= s_Ctrl_EX(12);
  s_jal_EX 	      <= s_Ctrl_EX(13);
  s_RegDst_EX     <= s_Ctrl_EX(4);

  -- s_shamt <= s_imm32_EX(4 downto 0);
  s_shamt <= s_imm32_EX(10 downto 6);

  -- control signals passed on
  s_MemtoReg_EX <= s_Ctrl_EX(7);
  s_DMemWr_EX   <= s_Ctrl_EX(6); 
  s_RegWr_EX    <= s_Ctrl_EX(5);
  s_Branch_EX   <= s_Ctrl_EX(3);
  s_jump_EX     <= s_Ctrl_EX(1);
  s_Halt_EX     <= s_Ctrl_EX(0);


  jumpReg: mux2t1_N
  generic map(N => 32) 
  port map(i_S  => s_jr,
           i_D0 => s_jumpAddress_EX,
           i_D1 => s_RegOutReadData1_EX,
           o_O  => s_finalJumpAddress_EX);

  --Calculate Branch Address Offset
  s_imm32x4(0) <= '0';
  s_imm32x4(1) <= '0'; --Set first two bits to zero
  s_imm32x4(31 downto 2) <= s_imm32_EX(29 downto 0); --imm32 bits[29-0] into bits[31-2] of jumpAddr

  branchAdder: addersubtractor
    generic map(N => 32)
    port map(nAdd_Sub => '0',--in std_logic;
             i_A      => s_PCPlusFour_EX,--in std_logic_vector(N-1 downto 0);
             i_B      => s_imm32x4,--in std_logic_vector(N-1 downto 0);
             o_Y      => s_branchAddress_EX,--out std_logic_vector(N-1 downto 0);
             o_Cout   => s2);--out std_logic);

  mainALU: alu
    port map(i_A        => s_RegOutReadData1_EX, -- in std_logic_vector(31 downto 0);
             i_B        => s_immMuxOut, -- in std_logic_vector(31 downto 0);
             i_aluOp    => s_ALUOp, -- in std_logic_vector(3 downto 0);
             i_shamt    => s_shamt, -- in std_logic_vector(4 downto 0);
             o_F        => s_aluOut_EX, -- out std_logic_vector(31 downto 0);
             overFlow   => s_Ovfl_EX, -- out std_logic;
             zero       => s_ALUBranch_EX);-- out std_logic);

  -- Muxes
  ALUSrc: mux2t1_N
    generic map(N => 32) -- Generic of type integer for input/output data width. Default value is 32.
    port map(i_S  => s_ALUSrc,
             i_D0 => s_RegOutReadData2_EX,
             i_D1 => s_imm32_EX,
             o_O  => s_immMuxOut);
----------------------------------------v
  --Moved these Muxes to Decode stage
  -- RegDst: mux2t1_N
  --   generic map(N => 5) -- Generic of type integer for input/output data width. Default value is 32.
  --   port map(i_S  => s_RegDst_EX,
  --            i_D0 => s_RegDst0, --output of jalAddr mux
  --            i_D1 => s_rd_EX, --rd
  --            o_O  => s_RegWrAddr_EX);

  -- jalAddr: mux2t1_N
  --   generic map(N => 5) 
  --   port map(i_S  => s_jal_EX,
  --            i_D0 => s_rt_EX, --rt is taking the place of rd,
  --            i_D1 => "11111", -- register 31
  --            o_O  => s_RegDst0);
-----------------------------------------^

  EX_MEM: EX_MEM_reg
    port map(i_CLK	     => iCLK,
	     i_RST	     => iRST,

	     i_PC_4	     => s_PCPlusFour_EX,
	     i_finalJumpAddr => s_finalJumpAddress_EX,
	     i_branchAddr    => s_branchAddress_EX,
	     i_readData2     => s_RegOutReadData2_EX,
	     i_aluOut	     => s_aluOut_EX,

	     i_writeReg      => s_RegWrAddr_EX,

	-- one bit inputs
	     i_zero	     => s_ALUBranch_EX,
	     i_overflow	     => s_Ovfl_EX,
	     i_jal	     => s_jal_EX,
	     i_MemtoReg	     => s_MemtoReg_EX,
	     i_weMem	     => s_DMemWr_EX,
	     i_weReg	     => s_RegWr_EX,
	     i_branch	     => s_Branch_EX,
	     i_j	     => s_jump_EX,
	     i_halt	     => s_Halt_EX,

	     o_PC_4	     => s_PCPlusFour_MEM,
	     o_finalJumpAddr => s_finalJumpAddress_MEM,
	     o_branchAddr    => s_branchAddress_MEM,
	     o_readData2     => s_RegOutReadData2_MEM,
	     o_aluOut	     => s_aluOut_MEM,

	     o_writeReg      => s_RegWrAddr_MEM,

	-- one bit outputs
	     o_zero	     => s_ALUBranch_MEM,
	     o_overflow	     => s_Ovfl_MEM,
	     o_jal	     => s_jal_MEM,
	     o_MemtoReg	     => s_MemtoReg_MEM,
	     o_weMem	     => s_DMemWr_MEM,
	     o_weReg	     => s_RegWr_MEM,
	     o_branch	     => s_Branch_MEM,
	     o_j	     => s_jump_MEM,
	     o_halt	     => s_Halt_MEM);

------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--------------------------------- MEM STAGE ----------------------------------------
------------------------------------------------------------------------------------
  s_branch_check_MEM <= s_Branch_MEM AND s_ALUBranch_MEM;
  s_DMemAddr <= s_aluOut_MEM;
  s_DMemData <= s_RegOutReadData2_MEM;
  s_DMemWr   <= s_DMemWr_MEM;


  DMem: mem
    generic map(ADDR_WIDTH => 10,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(11 downto 2),
             data => s_DMemData,
             we   => s_DMemWr,
             q    => s_DMemOut);

  MEM_WB: MEM_WB_reg
    port map(i_CLK	     => iCLK,
	     i_RST	     => iRST,

	     i_PC_4	     => s_PCPlusFour_MEM,
	     i_finalJumpAddr => s_finalJumpAddress_MEM,
	     i_branchAddr    => s_branchAddress_MEM,
	     i_memReadData   => s_DMemOut,
	     i_aluOut	     => s_aluOut_MEM,

	     i_writeReg      => s_RegWrAddr_MEM,

	-- one bit inputs
	     i_branchCheck   => s_branch_check_MEM,
	     i_overflow      => s_Ovfl_MEM,
	     i_jal	     => s_jal_MEM,
	     i_MemtoReg	     => s_MemtoReg_MEM,
	     i_weReg	     => s_RegWr_MEM,
	     i_j	     => s_jump_MEM,
	     i_halt	     => s_Halt_MEM,

	     o_PC_4	     => s_PCPlusFour_WB,
	     o_finalJumpAddr => s_finalJumpAddress_WB ,
	     o_branchAddr    => s_branchAddress_WB,
	     o_memReadData   => s_memReadData_WB,
	     o_aluOut	     => s_aluOut_WB,

	     o_writeReg      => s_RegWrAddr,

	-- one bit outputs
	     o_branchCheck   => s_branch_check_WB,
	     o_overflow      => s_Ovfl,
	     o_jal	     => s_jal_WB,
	     o_MemtoReg	     => s_MemtoReg_WB,
	     o_weReg	     => s_RegWr,
	     o_j	     => s_jump_WB,
	     o_halt	     => s_Halt);
        
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--------------------------------- WB STAGE -----------------------------------------
------------------------------------------------------------------------------------
  oALUOut <= s_aluOut_WB; --oALU is for synthesis

  -- write back muxes
  jalData: mux2t1_N
    generic map(N => 32) 
    port map(i_S  => s_jal_WB,
             i_D0 => s_aluOut_WB, --This is the ALU Output
             i_D1 => s_PCPlusFour_WB,
             o_O  => s_MemToReg0);

  MemtoReg: mux2t1_N
    generic map(N => 32) 
    port map(i_S  => s_MemtoReg_WB,
             i_D0 => s_MemToReg0, 
             i_D1 => s_memReadData_WB,
             o_O  => s_RegWrData);

  -- branch/jump muxes
  Branch: mux2t1_N
    generic map(N => 32) 
    port map(i_S  => s_branch_check_WB,
             i_D0 => s_normAddress, --PC+4, or PC if stalled 
             i_D1 => s_branchAddress_WB,
             o_O  => s_normalOrBranch);
  Jump: mux2t1_N
    generic map(N => 32) 
    port map(i_S  => s_jump_WB,
             i_D0 => s_normalOrBranch, 
             i_D1 => s_finalJumpAddress_WB,
             o_O  => s_inputPC);

  
        
------------------------------------------------------------------------------------

end structure;
