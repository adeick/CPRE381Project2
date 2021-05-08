-------------------------------------------------------------------------
-- Andrew Deick
-- Department of Software Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- mux32t1.vhd
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

package mypack is 
	type TwoDArray is array (31 downto 0) of std_logic_vector(31 downto 0);
end package;

library IEEE;
use IEEE.std_logic_1164.all;
use work.mypack.all;
-- use work.mypack.all;


entity mux32t1 is
  port(i_I          : in TwoDArray;     -- Data value input
	   i_S			: in std_logic_vector(4 downto 0);
       o_O          : out std_logic_vector(31 downto 0));   -- Data value output

end mux32t1;

architecture behavior of mux32t1 is
 
begin

  
  -- Create a multiplexed input to the FF based on i_WE
  with i_S select
    o_O <=  i_I(0) when "00000",
    i_I(1) when "00001",
    i_I(2) when "00010",
	i_I(3) when "00011",
	i_I(4) when "00100",
	i_I(5) when "00101",
	i_I(6) when "00110",
	i_I(7) when "00111",
	i_I(8) when "01000",
	i_I(9) when "01001",
	i_I(10) when "01010",
	i_I(11) when "01011",
	i_I(12) when "01100",
	i_I(13) when "01101",
	i_I(14) when "01110",
	i_I(15) when "01111",
	i_I(16) when "10000",
	i_I(17) when "10001",
	i_I(18) when "10010",
	i_I(19) when "10011",
	i_I(20) when "10100",
	i_I(21) when "10101",
	i_I(22) when "10110",
	i_I(23) when "10111",
	i_I(24) when "11000",
	i_I(25) when "11001",
	i_I(26) when "11010",
	i_I(27) when "11011",
	i_I(28) when "11100",
	i_I(29) when "11101",
	i_I(30) when "11110",
	i_I(31) when "11111",
    "00000000000000000000000000000000" when others;
  
  
end behavior;
