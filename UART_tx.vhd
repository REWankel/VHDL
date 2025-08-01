library IEEE;
---------------------------------
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
---------------------------------
entity UART_tx is
port(
    sclk     : in  std_logic;
    rst_n    : in  std_logic;
    UART_TXD : out std_logic;
    tx_data  : in  std_logic_vector(7 downto 0);
    tx_valid : in  std_logic;
    tx_ready : out std_logic
);
end UART_tx;
---------------------------------
architecture beh of UART_tx is
---------------------------------
signal tx_dout : std_logic_vector(7 downto 0) := (others => '0');
signal bit_cnt : integer range 0 to 9   := 0;
signal tx_tick : integer range 0 to 433 := 0;
signal FSM     : integer range 0 to 2   := 0;
---------------------------------
begin
---------------------------------
--Transmit FSM
---------------------------------
process(sclk, rst_n)
begin
---------------------------------
--Async Reset
---------------------------------
    if (rst_n = '0') then
        FSM      <= 0;
        bit_cnt  <= 0;
        tx_ready <= '1';
        tx_tick  <= 0;
---------------------------------		  
    elsif rising_edge(sclk) then
        case (FSM) is
---------------------------------
--Idle state
---------------------------------
        when 0 =>
            FSM      <= 1;
            bit_cnt  <= 0;
            tx_ready <= '1';
            tx_tick  <= 0;
            tx_dout  <= x"00";
---------------------------------
--Wait for tx_valid
---------------------------------
        when 1 =>
            if (tx_valid = '1') then
                FSM      <= 2;
                bit_cnt  <= 0;
                tx_ready <= '0';
                tx_tick  <= 0;
                tx_dout  <= tx_data;
            end if;
---------------------------------
--Transmit bits
---------------------------------
        when 2 =>
            if (tx_tick = 433) then
                if (bit_cnt < 9) then
                    bit_cnt <= bit_cnt + 1;
                    tx_tick <= 0;
                else
                    bit_cnt <= 0;
                    tx_tick <= 0;
                    FSM     <= 0;
                end if;
            else
                tx_tick <= tx_tick + 1;
            end if;
---------------------------------
        when others =>
            FSM <= 0;
---------------------------------				
        end case;
    end if;
end process;
---------------------------------
-- UART_TXD output logic
---------------------------------
process(sclk,rst_n)
begin
    if (rst_n = '0') then
        UART_TXD <= '1';
    elsif rising_edge(sclk) then
        case (bit_cnt) is
        when 0      => UART_TXD <= '1';--stop bit
        when 1      => UART_TXD <= '0';--start bit
        when 2      => UART_TXD <= tx_dout(0);
        when 3      => UART_TXD <= tx_dout(1);
        when 4      => UART_TXD <= tx_dout(2);
        when 5      => UART_TXD <= tx_dout(3);
        when 6      => UART_TXD <= tx_dout(4);
        when 7      => UART_TXD <= tx_dout(5);
        when 8      => UART_TXD <= tx_dout(6);
        when 9      => UART_TXD <= tx_dout(7);
        when others => UART_TXD <= '1';
        end case;
    end if;
end process;
---------------------------------
end beh;
