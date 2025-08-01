library IEEE;
---------------------------------
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
---------------------------------
entity UART_rx is
port(
    sclk     : in  std_logic;
    rst_n    : in  std_logic;
    UART_RXD : in  std_logic;
    rx_data  : out std_logic_vector(7 downto 0);
    rx_valid : out std_logic
);
end UART_rx;
---------------------------------
architecture beh of UART_rx is
---------------------------------
signal rx_din  : std_logic_vector(7 downto 0) := (others => '0');
signal rx_sync : std_logic_vector(3 downto 0) := (others => '1');
signal rx_tick : integer range 0 to 433 := 0;
signal bit_cnt : integer range 0 to 7   := 0;
signal FSM     : integer range 0 to 5   := 0;
---------------------------------
begin
---------------------------------
--RXD sync & sample point per 20%
---------------------------------
process(sclk, rst_n)
begin
     if (rst_n = '0')          then rx_sync    <= (others => '1');
     elsif rising_edge(sclk) then
        if    (FSM=0)          then rx_sync    <= rx_sync(2 downto 0) & UART_RXD;
        elsif ((FSM=1)or(FSM=2)or(FSM=3)) then
           if    (rx_tick= 86) then rx_sync(0) <= UART_RXD;--20% => 433*0.2 = 86.6
           elsif (rx_tick=172) then rx_sync(1) <= UART_RXD;--40% => 433*0.4 = 173.2
           elsif (rx_tick=258) then rx_sync(2) <= UART_RXD;--60% => 433*0.6 = 259.8
           elsif (rx_tick=344) then rx_sync(3) <= UART_RXD;--80% => 433*0.8 = 346.4
           else 		               rx_sync    <= rx_sync;  
           end if;
        else                        rx_sync    <= (others => '1');
        end if;
     end if;
end process;
---------------------------------
--Receive FSM
---------------------------------
process(sclk, rst_n)
---------------------------------
--voter
---------------------------------
function vote(input : std_logic_vector(3 downto 0)) return std_logic is
variable ones : integer := 0;
---------------------------------
begin
    for i in 0 to 3 loop
        if input(i) = '1' then
            ones := ones + 1;
        end if;
    end loop;
---------------------------------	 
    if ones >= 3 then
        return '1';
    else
        return '0';
    end if;
---------------------------------	 
end function;
---------------------------------	 
begin
---------------------------------
--Async Reset
---------------------------------
    if (rst_n = '0') then
        FSM      <= 0;
        rx_tick  <= 0;
        bit_cnt  <= 0;
        rx_valid <= '0';
        rx_data  <= (others => '0');
---------------------------------		  
    elsif rising_edge(sclk) then
        case (FSM) is
---------------------------------
--Wait start bit falling edge
---------------------------------
        when 0 =>
            if (rx_sync = "1110") then--falling edge detect
                FSM      <= 1;
                rx_tick  <= 0;
                rx_valid <= '0';
            else
                FSM      <= FSM;
                rx_tick  <= 0;
                rx_valid <= '0';
            end if;
---------------------------------
--Check start bit
---------------------------------
        when 1 =>
            if (rx_tick = 432) then
                if (vote(rx_sync) = '0') then--vote
                    FSM     <= 2;
                    bit_cnt <= 0;
                    rx_tick <= 0;
                else
                    FSM <= 0;--Start bit invalid
                end if;
            else
                rx_tick <= rx_tick + 1;
            end if;
---------------------------------
--Receive data
---------------------------------
        when 2 =>
            if (rx_tick = 432) then
                rx_din(bit_cnt) <= vote(rx_sync);--vote
                rx_tick <= 0;
                if (bit_cnt = 7) then
                    FSM <= 3;
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            else
                rx_tick <= rx_tick + 1;
            end if;
---------------------------------
--Check Stop bit
---------------------------------
        when 3 =>
            if (rx_tick = 432) then
                if (vote(rx_sync) = '1') then--vote
                    FSM <= 4;
                else
                    FSM <= 0; -- Framing error
                end if;
                rx_tick <= 0;
            else
                rx_tick <= rx_tick + 1;
            end if;
---------------------------------
--Receive complete
---------------------------------
        when 4 =>
            rx_data  <= rx_din;
            rx_valid <= '1';
            FSM      <= 0;
---------------------------------
        when others =>
            FSM <= 0;
---------------------------------				
        end case;
    end if;
end process;
---------------------------------
end beh;
