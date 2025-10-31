------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    ext_uart.vhd
-- Authors: Gabriele Montanaro
--          Andrea Galimberti
--          Davide Zoni
-- Company: Politecnico di Milano
-- Mail:    name.surname@polimi.it
--
------------------------------------------------------------------------------

-- This module has the goal of decoding the activation and release of the external reset
-- sent as uart signals by the host computer.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.uart.all;

entity ext_uart is
  generic (
    BAUDRATE            : integer := 38400;
    CLOCK_FREQ          : integer := 100000000;
    DATA_BYTES          : integer := 4;
    ADDR_BYTES          : integer := 4
  );
  port (
    clk_i               :   in  std_logic;
    rst_i               :   in  std_logic;
    addr_o              :   out std_logic_vector(8*ADDR_BYTES-1 downto 0);
    data_o              :   out std_logic_vector(8*DATA_BYTES-1 downto 0);
    valid_o             :   out std_logic;
    rx                  :   in  std_logic
  );
end ext_uart;

architecture rtl of ext_uart is

-- Output data
signal addr_r, addr_n         : std_logic_vector(8*ADDR_BYTES-1 downto 0);
signal data_r, data_n         : std_logic_vector(8*DATA_BYTES-1 downto 0);
signal valid_r, valid_n       : std_logic;

-- Signal for counting the number of received bytes
signal counter_r, counter_n   : integer;

-- Internal uart output signals
signal uart_byte              : std_logic_vector(7 downto 0);
signal uart_valid             : std_logic;

begin

  -- Output assignment
  addr_o <= addr_r;
  data_o <= data_r;
  valid_o <= valid_r;

  sequential_process: process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        addr_r <= (others => '0');
        data_r <= (others => '0');
        valid_r <= '0';
        counter_r <= 0;
      else
        addr_r <= addr_n;
        data_r <= data_n;
        valid_r <= valid_n;
        counter_r <= counter_n;
      end if;
    end if;
  end process;

  combinatorial_process: process (all)
  -- Next register states variables
  variable addr_v         : std_logic_vector(8*ADDR_BYTES-1 downto 0);
  variable data_v         : std_logic_vector(8*DATA_BYTES-1 downto 0);
  variable valid_v        : std_logic;
  variable counter_v      : integer;

  begin
    -- Initialize all the variables
    addr_v    := addr_r;
    data_v    := data_r;
    valid_v   := '0';
    counter_v := counter_r;

    if uart_valid = '1' then
    -- This module expects a first byte in the form of [1, write_bit, data_len].
    -- Since write must be 1 and the length of the reset is just one word
    -- (written as zero, since no zero-word transactions are allowed) then the
    -- expected byte is 11000000
      if counter_r = 0 then
        if uart_byte = "11000000" then
          counter_v := counter_r + 1;
        end if;
    -- counter < 1 + ADDR_BYTES: the uart byte is a part of the address
      elsif counter_r < 1 + ADDR_BYTES then
        addr_v(8*ADDR_BYTES - 1 downto 8) := addr_r(8*(ADDR_BYTES-1) - 1 downto 0);
        addr_v(8 - 1 downto 0) := uart_byte;
        counter_v := counter_r + 1;
    -- 1 + ADDR_BYTES <= counter < 1 + ADDR_BYTES + DATA_BYTES: the uart byte is a part of the data
      elsif counter_r < 1 + ADDR_BYTES + DATA_BYTES then
        data_v(8*DATA_BYTES - 1 downto 8) := data_r(8*(DATA_BYTES-1) - 1 downto 0);
        data_v(8 - 1 downto 0) := uart_byte;
        counter_v := counter_r + 1;
        -- When the last data arrives, signal that the output is valid
        if counter_r = 1 + ADDR_BYTES + DATA_BYTES - 1 then
          valid_v := '1';
          counter_v := 0;
        end if;

      end if;

    end if;
    -- Assign the variables to the corresponding next state signals
    addr_n    <= addr_v;
    data_n    <= data_v;
    valid_n   <= valid_v;
    counter_n <= counter_v;

  end process;

  uart: basic_uart
    generic map(
      baud                => BAUDRATE,
      clock_frequency     => CLOCK_FREQ
      )
    port map (
      clock               => clk_i,
      reset               => rst_i,
      data_stream_in      => (others => '0'),
      data_stream_in_stb  => '0',
      data_stream_in_ack  => open,
      data_stream_out     => uart_byte,
      data_stream_out_stb => uart_valid,
      tx                  => open,
      rx                  => rx
    );

end rtl;
