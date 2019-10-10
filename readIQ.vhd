library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.radio_utils.all;

entity readIQ is
port (
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (7 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal r_real_din : out std_logic_vector (31 downto 0);
	signal r_real_full : in std_logic;
	signal r_real_wr_en : out std_logic;
	signal r_imag_din : out std_logic_vector (31 downto 0);
	signal r_imag_full : in std_logic;
	signal r_imag_wr_en : out std_logic
);
end entity readIQ;

architecture behavior of readIQ is 

	TYPE state_type is (s0,s1, s2);
	signal state, next_state : state_type;
	signal i, i_c : signed(15 downto 0);
	signal q, q_c : signed(15 downto 0);
	signal cnt, cnt_c : integer;
		
begin
	readIQ_fsm_process : process(state, r_real_full, r_imag_full, x_empty, x_dout, cnt)
	begin
		next_state <= state;
		x_rd_en <= '0';
		r_real_din <= (others => '0');
		r_real_wr_en <= '0';
		r_imag_din <= (others => '0');
		r_imag_wr_en <= '0';
		cnt_c <= cnt;
		i_c <= i;
		q_c <= q;
		
		case ( state ) is 
			when s0 =>
				if(x_empty = '0') then
					x_rd_en <= '1';
					i_c((cnt+1)*8-1 downto cnt*8) <= signed(x_dout);
					cnt_c <= (cnt + 1) mod 2;
					if(cnt = 1) then 
						next_state <= s1;
					end if;
				end if;
						
			when s1 =>
				if(x_empty = '0') then
					x_rd_en <= '1';
					--q_c <= signed((unsigned(q) sll 8) or resize(unsigned(x_dout), 16));
					q_c((cnt+1)*8-1 downto cnt*8) <= signed(x_dout);
					cnt_c <= (cnt + 1) mod 2;
					if(cnt = 1) then 
						next_state <= s2;
					end if;
				end if;
				
			when s2 =>
				if ( r_real_full = '0' and r_imag_full = '0' ) then
					r_real_wr_en <= '1';
					r_imag_wr_en <= '1';
					r_real_din <= std_logic_vector(to_signed(QUANTIZE_I(to_integer(i)), 32));
					r_imag_din <= std_logic_vector(to_signed(QUANTIZE_I(to_integer(q)), 32));
 					next_state <= s0;
				end if;
				
			when OTHERS =>
				next_state <= s0;
		end case;
	end process readIQ_fsm_process;

	reg_process : process(reset, clock)
	begin
		if ( reset = '1' ) then
			state <= s0;
			cnt <= 0;
			i <= (others => '0');
			q <= (others => '0');
		elsif ( rising_edge(clock) ) then
			state <= next_state;
			cnt <= cnt_c;
			i <= i_c;
			q <= q_c;
		end if;
	end process reg_process;
	
end architecture behavior;