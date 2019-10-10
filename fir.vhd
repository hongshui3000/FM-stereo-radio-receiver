library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.radio_utils.all;

entity fir is
generic (
	constant SAMPLE : integer := 1024; 
	constant TAPS : integer := 20;
	constant COEF : ARRAY_SLV32;
	constant DECIM : integer := 8
);
port (
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (31 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal r_din : out std_logic_vector (31 downto 0);
	signal r_full : in std_logic;
	signal r_wr_en : out std_logic
);
end entity fir;

architecture behavior of fir is 
--varibale declarations
signal shift_reg, shift_reg_c : ARRAY_SLV32 (0 to MAX_TAPS-1);
signal decim_cnt, decim_cnt_c : integer;
signal tap_cnt, tap_cnt_c : integer;
signal y, y_c : signed(31 downto 0);

TYPE state_type is (s0,s1,s2,s3);
signal state : state_type;
signal next_state : state_type;

begin
fir_fsm_process : process(y, decim_cnt, tap_cnt, x_empty, x_dout, r_full, shift_reg, state)
variable tmp : signed(63 downto 0) := (others => '0');
begin
x_rd_en <= '0';
r_din <= (others => '0');
r_wr_en <= '0';
decim_cnt_c <= decim_cnt;
tap_cnt_c <= tap_cnt;
next_state <= state;
shift_reg_c <= shift_reg;
y_c <= y;

case ( state ) is
when s0 =>
	shift_reg_c <= (others => (others => '0'));
	next_state <= s1;
	decim_cnt_c <= 0;

when s1 =>
	if(x_empty = '0') then
		x_rd_en <= '1';
		for i in (TAPS-1) downto 1 loop
			shift_reg_c(i) <= shift_reg(i - 1);
		end loop;

		shift_reg_c(0) <= x_dout;
		if(decim_cnt = (DECIM - 1)) then
			next_state <= s2;
		else
			next_state <= s1;
		end if;
		decim_cnt_c <= (decim_cnt + 1) mod DECIM;
	end if;

when s2 =>
	tmp := signed(COEF(TAPS - tap_cnt - 1)) * signed(shift_reg(tap_cnt));
	y_c <= y + signed(DEQUANTIZE(std_logic_vector(tmp(31 downto 0))));
	if(tap_cnt = (TAPS - 1)) then
			next_state <= s3;
		else
			next_state <= s2;
		end if;
	tap_cnt_c <= (tap_cnt + 1) mod TAPS;

when s3 =>
	if ( r_full = '0' ) then
		r_din <= std_logic_vector(y);
		r_wr_en <= '1';
		next_state <= s1;
		y_c <= (others => '0');
	end if;

when OTHERS =>
	r_din <= (others => 'X');
	r_wr_en <= 'X';
	shift_reg_c <= (others => (others => 'X'));
	next_state <= s0;
end case;
end process fir_fsm_process;

reg_process : process(reset, clock)
begin
if ( reset = '1' ) then
	state <= s0;
	shift_reg <= (others => (others => '0'));
	decim_cnt <= 0;
	tap_cnt <= 0;
	y <= (others => '0');
elsif ( rising_edge(clock) ) then
	state <= next_state;
	shift_reg <= shift_reg_c;
	decim_cnt <= decim_cnt_c;
	tap_cnt <= tap_cnt_c;
	y <= y_c;
end if;

end process reg_process;

end architecture behavior;
