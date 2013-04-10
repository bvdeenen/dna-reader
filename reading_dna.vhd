--
-- Reference design - Reading device DNA on the Spartan-3A Starter Kit.
--
-- Ken Chapman - Xilinx Ltd - 2nd January 2007
--
-- PicoBlaze is used to read the device DNA and display it on the LCD display.
--
-- 8-bit communication is possible with the LCD display on the Spartan-3A Starter Kit.
--
-- 8 LEDs provide a one second 'heart beat' counter driven by PicoBlaze interrupts.
--
------------------------------------------------------------------------------------
--
-- NOTICE:
--
-- Copyright Xilinx, Inc. 2007.   This code may be contain portions patented by other 
-- third parties.  By providing this core as one possible implementation of a standard,
-- Xilinx is making no representation that the provided implementation of this standard 
-- is free from any claims of infringement by any third party.  Xilinx expressly 
-- disclaims any warranty with respect to the adequacy of the implementation, including 
-- but not limited to any warranty or representation that the implementation is free 
-- from claims of any third party.  Furthermore, Xilinx is providing this core as a 
-- courtesy to you and suggests that you contact all third parties to obtain the 
-- necessary rights to use this implementation.
--
------------------------------------------------------------------------------------
--
-- Library declarations
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
-- The Unisim Library is used to define Xilinx primitives. It is also used during
-- simulation. The source can be viewed at %XILINX%\vhdl\src\unisims\unisim_VCOMP.vhd
--
library unisim;
use unisim.vcomponents.all;
--
--
------------------------------------------------------------------------------------
--
--
entity reading_dna is
    Port (             led : out std_logic_vector(7 downto 0);
                     lcd_d : inout std_logic_vector(7 downto 0);
                    lcd_rs : out std_logic;
                    lcd_rw : out std_logic;
                     lcd_e : out std_logic;
                     j2_30 : out std_logic;
                     j2_26 : out std_logic;
                     j2_22 : out std_logic;
                     j2_14 : out std_logic;
                       clk : in std_logic);
    end reading_dna;
--
------------------------------------------------------------------------------------
--
-- Start of test architecture
--
architecture Behavioral of reading_dna is
--
------------------------------------------------------------------------------------
--
-- declaration of KCPSM3
--
  component kcpsm3 
    Port (      address : out std_logic_vector(9 downto 0);
            instruction : in std_logic_vector(17 downto 0);
                port_id : out std_logic_vector(7 downto 0);
           write_strobe : out std_logic;
               out_port : out std_logic_vector(7 downto 0);
            read_strobe : out std_logic;
                in_port : in std_logic_vector(7 downto 0);
              interrupt : in std_logic;
          interrupt_ack : out std_logic;
                  reset : in std_logic;
                    clk : in std_logic);
    end component;
--
-- declaration of program ROM
--
  component dna_ctrl
    Port (      address : in std_logic_vector(9 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                    clk : in std_logic);
    end component;
--
------------------------------------------------------------------------------------
--
-- Signals used to connect KCPSM3 to program ROM and I/O logic
--
signal  address          : std_logic_vector(9 downto 0);
signal  instruction      : std_logic_vector(17 downto 0);
signal  port_id          : std_logic_vector(7 downto 0);
signal  out_port         : std_logic_vector(7 downto 0);
signal  in_port          : std_logic_vector(7 downto 0);
signal  write_strobe     : std_logic;
signal  read_strobe      : std_logic;
signal  interrupt        : std_logic :='0';
signal  interrupt_ack    : std_logic;
signal  kcpsm3_reset     : std_logic;
--
--
-- Signals used to generate interrupt 
--
signal int_count         : integer range 0 to 49999999 :=0;
signal event_1hz         : std_logic;
--
--
-- Signals used to read device DNA 
--
signal dna_din           : std_logic;
signal dna_read          : std_logic;
signal dna_shift         : std_logic;
signal dna_dout          : std_logic;
signal dna_clk           : std_logic;
--
--
-- Signals for LCD operation
--
-- Tri-state output requires internal signals
-- 'lcd_drive' is used to differentiate between LCD and StrataFLASH communications 
-- which share the same data bits.
--
signal    lcd_rw_control : std_logic;
signal   lcd_output_data : std_logic_vector(7 downto 0);
--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Start of circuit description
--
begin
  --
  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- Instantiate the device DNA primitive 
  ----------------------------------------------------------------------------------------------------------------------------------
  --

  device_dna: dna_port
    port map(   din => dna_din,
               read => dna_read,
              shift => dna_shift,                       
               dout => dna_dout,                       
                clk => dna_clk);


  --
  -- Connect signals to test points on connector J2 for analysis
  --

  j2_30 <= dna_clk;
  j2_26 <= dna_read;  
  j2_22 <= dna_shift;
  j2_14 <= dna_dout;

  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 and the program memory 
  ----------------------------------------------------------------------------------------------------------------------------------
  --

  processor: kcpsm3
    port map(      address => address,
               instruction => instruction,
                   port_id => port_id,
              write_strobe => write_strobe,
                  out_port => out_port,
               read_strobe => read_strobe,
                   in_port => in_port,
                 interrupt => interrupt,
             interrupt_ack => interrupt_ack,
                     reset => kcpsm3_reset,
                       clk => clk);
 
  program_rom: dna_ctrl
    port map(      address => address,
               instruction => instruction,
                       clk => clk);

  kcpsm3_reset <= '0';                       
  
  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- Interrupt 
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  --
  -- Interrupt is used to provide a 1 second time reference.
  --
  --
  -- A simple binary counter is used to divide the 50MHz system clock and provide interrupt pulses.
  --

  interrupt_control: process(clk)
  begin
    if clk'event and clk='1' then

      --divide 50MHz by 50,000,000 to form 1Hz pulses
      if int_count=49999999 then
         int_count <= 0;
         event_1hz <= '1';
       else
         int_count <= int_count + 1;
         event_1hz <= '0';
      end if;

      -- processor interrupt waits for an acknowledgement
      if interrupt_ack='1' then
         interrupt <= '0';
        elsif event_1hz='1' then
         interrupt <= '1';
        else
         interrupt <= interrupt;
      end if;

    end if; 
  end process interrupt_control;

  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 input ports 
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  --
  -- The inputs connect via a pipelined multiplexer
  --

  input_ports: process(clk)
  begin
    if clk'event and clk='1' then

      case port_id(0) is

        -- read device DNA output at address 00 hex
        when '0' =>    in_port <=  "0000000" & dna_dout;

        -- read 8-bit LCD data at address 01 hex
        when '1' =>    in_port <= lcd_d;

        -- Don't care used for all other addresses to ensure minimum logic implementation
        when others =>    in_port <= "XXXXXXXX";  

      end case;

     end if;

  end process input_ports;


  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 output ports 
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  -- adding the output registers to the processor
  --
   
  output_ports: process(clk)
  begin

    if clk'event and clk='1' then
      if write_strobe='1' then

        -- Write to LEDs at address 80 hex.

        if port_id(7)='1' then
          led <= out_port;
        end if;

        -- 8-bit LCD data output address 40 hex.

        if port_id(6)='1' then
          lcd_output_data <= out_port;
        end if;

        -- LCD controls at address 20 hex.

        if port_id(5)='1' then
          lcd_rs <= out_port(2);
          lcd_rw_control <= out_port(1);
          lcd_e <= out_port(0);
        end if;

        -- Control device DNA input signals at addresses 10 hex.

        if port_id(4)='1' then
          dna_clk <= out_port(0);
          dna_shift <= out_port(1);
          dna_read <= out_port(2);
          dna_din <= out_port(3);
        end if;

      end if;

    end if; 

  end process output_ports;

  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- LCD interface  
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  -- The LCD will be accessed using the 8-bit mode.  
  -- lcd_rw is '1' for read and '0' for write 
  --
  -- Control of read and write signal
  lcd_rw <= lcd_rw_control;

  -- use read/write control to enable output buffers.
  lcd_d <= lcd_output_data when lcd_rw_control='0' else "ZZZZZZZZ";

  --
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  --
end Behavioral;

------------------------------------------------------------------------------------------------------------------------------------
--
-- END OF FILE reading_dna.vhd
--
------------------------------------------------------------------------------------------------------------------------------------

