library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sub_op is
port
(
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal x_dout : in std_logic_vector (31 downto 0);
	signal x_empty : in std_logic;
	signal x_rd_en : out std_logic;
	signal y_dout : in std_logic_vector (31 downto 0);
	signal y_empty : in std_logic;
	signal y_rd_en : out std_logic;
	signal z_din : out std_logic_vector (31 downto 0);
	signal z_full : in std_logic;
	signal z_wr_en : out std_logic
);
end entity sub_op;


architecture behavior of sub_op is 

	TYPE state_type is (s0,s1);
	signal state, next_state : state_type;
	signal result, result_c : integer;
	
begin
	
	sub_fsm_process : process(state, z_full, x_empty, x_dout, y_empty, y_dout, result )
	begin
		next_state <= state;
		x_rd_en <= '0';
		y_rd_en <= '0';
		z_wr_en <= '0';
		z_din <= (others => '0');
		result_c <= result;
		
		case ( state ) is 
			when s0 =>
				if(x_empty = '0' and y_empty = '0') then
					x_rd_en <= '1';
					y_rd_en <= '1';
					result_c <= to_integer(signed(x_dout)) - to_integer(signed(y_dout));
					next_state <= s1;
				end if;
								
			when s1 =>
				if ( z_full = '0' ) then
					z_wr_en <= '1';
					z_din <= std_logic_vector(to_signed(result, 32));
					next_state <= s0;
				end if;
				
			when OTHERS =>
				next_state <= s0;
		end case;
	end process sub_fsm_process;

	reg_process : process(reset, clock)
	begin
		if ( reset = '1' ) then
			state <= s0;
			result <= 0;
		elsif ( rising_edge(clock) ) then
			state <= next_state;
			result <= result_c;
		end if;
	end process reg_process;

end architecture behavior;
