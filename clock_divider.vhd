----------------------------------------------------------------------------------
-- Company: Universidad Complutense de Madrid, Facultad de Informática
-- Engineer: Fabrizio Alcaraz Escobar
-- 
-- Create Date: 11.04.2021 22:26:27
-- Design Name: 
-- Module Name: clock_divider_25Hz - Behavioral
-- Project Name: Divisor de frecuencia
-- Target Devices: 
-- Tool Versions: 
-- Description: Divide una señal de reloj de 100 MHz a cualquier frecuencia divisor.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_divider is
  Port ( clock_100MHz: in STD_LOGIC;
            reset: in STD_LOGIC;
            dividendo : in STD_LOGIC_VECTOR (25 downto 0);
            clock_out: out STD_LOGIC );
end clock_divider;

architecture Behavioral of clock_divider is
signal retardo: STD_LOGIC_VECTOR(25 downto 0);
begin
p_retardo:process(clock_100MHZ, reset)
begin
if reset = '1' then
    retardo <= (others => '0');
elsif rising_edge(clock_100MHZ) then
    if retardo < dividendo then
        retardo <= retardo + 1;
        clock_out <= '0';
    else 
        retardo <= (others => '0');
        clock_out <= '1';
    end if;
end if;  
end process p_retardo;

end Behavioral;
