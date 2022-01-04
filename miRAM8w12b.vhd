----------------------------------------------------------------------------------
-- Company: Universidad Complutense de Madrid, Facultad de Informática
-- Engineer:    Fabrizio Alcaraz Escobar
-- 
-- Create Date: 18.04.2021 12:43:41
-- Design Name: RAM 
-- Module Name: miRAM - Behavioral


-- Description: RAM DISTRIBUIDA de 8 palabras de 8 bits.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;


entity miRAM8w12b is
  Port ( clkFPGA: in std_logic;
            we: in std_logic;
            addr: in std_logic_vector (2 downto 0);
            data_in: in std_logic_vector (11 downto 0);
            data_out: out std_logic_vector (11 downto 0) );
end miRAM8w12b;

architecture Behavioral of miRAM8w12b is
 type ram_type is array (7 downto 0) of std_logic_vector(11 downto 0);
 signal RAM : ram_type := (
                            x"3F2",x"FFF",
                            x"FF0",x"F0F",
                            x"F00",x"0FF",
                            x"0F0",x"00F"
                            );
begin

p_ram:process(clkFPGA,we)
     begin
     if rising_edge(clkFPGA) then
             if (we = '1') then
                 RAM(conv_integer(addr)) <= data_in;
             end if;
         end if;
 end process p_ram;
 
 data_out <= RAM(conv_integer(addr));
 
end Behavioral;
