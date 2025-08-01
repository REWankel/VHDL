library IEEE;
---------------------------------
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
---------------------------------
entity fre_div is
port(
     sclk    : in  std_logic;
     rst_n   : in  std_logic;
     div_clk : out std_logic
);
end fre_div;
---------------------------------
architecture beh of fre_div is
---------------------------------
signal cnt : integer range 0 to 433 := 0;
---------------------------------
begin
---------------------------------
process(sclk,rst_n)
begin
    if (rst_n='0') then   cnt     <= 0; 
                          div_clk <= '0';
    elsif rising_edge(sclk) then
        if (cnt=433) then cnt     <= 0;
        else              cnt     <= cnt + 1;
        end if;
        if (cnt<217) then div_clk <= '1';
        else              div_clk <= '0';
        end if;
    end if;
end process;
---------------------------------
end beh;
