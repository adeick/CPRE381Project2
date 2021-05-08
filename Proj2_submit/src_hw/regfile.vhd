-------------------------------------------------------------------------
-- Andrew Deick
-- Department of Software Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- regfile.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: 
--
--
-- NOTES:
-- 8/19/16 by JAZ::Design created.
-- 11/25/19 by H3:Changed name to avoid name conflict with Quartus
--          primitives.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

use work.mypack.all;



entity regfile is
  port(clk			: in std_logic;
		i_wA		: in std_logic_vector(4 downto 0);
		i_wD		: in std_logic_vector(31 downto 0);
		i_wC		: in std_logic;
		i_r1		: in std_logic_vector(4 downto 0);
		i_r2		: in std_logic_vector(4 downto 0);
		reset		: in std_logic;
        o_d1        : out std_logic_vector(31 downto 0);
        o_d2        : out std_logic_vector(31 downto 0));

end regfile;

architecture structural of regfile is
 
	component mux32t1
	 port(i_I       : in TwoDArray;     -- Data value input
	   i_S			: in std_logic_vector(4 downto 0);
       o_O          : out std_logic_vector(31 downto 0));
	end component;
	
	component decoder5t32
	 port(i_I          : in std_logic_vector(4 downto 0);     -- Data value input
       o_O          : out std_logic_vector(31 downto 0));   -- Data value output
	end component;

	component dffg_n
	 port(i_CLK     : in std_logic;     -- Clock input
       i_RST        : in std_logic;     -- Reset input
       i_WE         : in std_logic;     -- Write enable input
       i_D          : in std_logic_vector(31 downto 0);     -- Data value input
       o_Q          : out std_logic_vector(31 downto 0));   -- Data value output
	end component;
	
	signal s1, s3 : std_logic_vector(31 downto 0);
	signal s2 : TwoDArray;
	
begin 
	
	writeDecoder: decoder5t32
    port MAP(i_wA, s1);
			 
	REG0: dffg_n port map(
			i_CLK	=> clk,
			i_RST 	=> reset,
			i_WE 	=> '0',
			i_D		=> x"00000000",
			o_Q		=> s2(0));
		
	ANDGATE: process (s1, i_wC)
	begin
		for i in 0 to 31 loop
			s3(i) <= s1(i) and i_wC;
		end loop;
	end process;
	
	RegisterList: for i in 1 to 31 generate
		REGI: dffg_n port map(
			i_CLK	=> clk,
			i_RST 	=> reset,
			i_WE 	=> s3(i),
			i_D		=> i_wD,
			o_Q		=> s2(i));
	end generate RegisterList;
	
	Read1: mux32t1
	port MAP(s2, i_r1, o_d1);
	
	Read2: mux32t1
	port MAP(s2, i_r2, o_d2);

end structural;
