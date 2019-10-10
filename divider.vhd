

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity divider is
generic(
    constant DWIDTH     : integer := 32
);
port(
    --Inputs
    signal clk          : in std_logic;
    signal reset        : in std_logic;
    signal start        : in std_logic;
    signal dividend     : in std_logic_vector(DWIDTH-1 downto 0);
    signal divisor      : in std_logic_vector(DWIDTH-1 downto 0);
    
    --Outputs
    signal quotient     : out std_logic_vector(DWIDTH-1 downto 0);
    signal remainder    : out std_logic_vector(DWIDTH-1 downto 0);
    signal overflow     : out std_logic;
    signal done         : out std_logic
);
end entity divider;


architecture behavior of divider is 

    function if_cond( test : boolean; true_cond : std_logic_vector; false_cond : std_logic_vector )
    return std_logic_vector is 
    begin
        if ( test ) then
            return true_cond;
        else
            return false_cond;
        end if;
    end if_cond;

    function if_cond( test : boolean; true_cond : integer; false_cond : integer )
    return integer is 
    begin
        if ( test ) then
            return true_cond;
        else
            return false_cond;
        end if;
    end if_cond;

    function get_msb_pos( val : std_logic_vector)
    return integer is 
        variable msb : integer;
    begin
        msb := 0;
        for i in 0 to (val'length - 1) loop
            if ( val(i) = '1' ) then
                msb := i;
            end if;
        end loop;
        return msb;
    end get_msb_pos;

    function get_msb_pos_rec( val : std_logic_vector)
    return integer is 
        variable p1, p2 : integer;
        variable p1_low, p1_high, p2_low, p2_high : integer;
        variable msb : integer;
    begin
        if ( val'length = 1 ) then
            msb := if_cond(val(val'left) = '1', val'left, 0);
        else
            p1_low := val'right;
            p1_high := val'right + val'length/2 - 1;
            p2_low := val'right + val'length/2;
            p2_high := val'left;
            p1 := get_msb_pos_rec( val(p1_high downto p1_low) );
            p2 := get_msb_pos_rec( val(p2_high downto p2_low) );
            msb := if_cond(p2 > p1, p2, p1);
        end if;
        return msb;
    end get_msb_pos_rec;


    type states is (s0, s1, s2);
    signal state, next_state : states;

    signal a, a_c : std_logic_vector ((DWIDTH-1) downto 0);
    signal b, b_c : std_logic_vector ((DWIDTH-1) downto 0);
    signal q, q_c : std_logic_vector ((DWIDTH-1) downto 0);
    signal r, r_c : std_logic_vector ((DWIDTH-1) downto 0);
    signal o, o_c : std_logic;
    signal done_o, done_c : std_logic;
    
begin

    -- clocked process
    clock_process : process(clk, reset)
    begin
        if ( reset = '1' ) then
            a <= (others => '0');
            b <= (others => '0');
            q <= (others => '0');
            r <= (others => '0');
            o <= '0';
            done_o <= '0';
            state <= s0;
        elsif ( rising_edge(clk) ) then
            a <= a_c;
            b <= b_c;
            q <= q_c;
            r <= r_c;
            o <= o_c;
            done_o <= done_c;
            state <= next_state;
        end if;
    end process clock_process;

    
    -- combinational fsm process
    div_process : process(dividend, divisor, a, b, q, r, o, done_o, state, start)
        variable p : integer := 0;
        variable sign : std_logic := '0';
    begin
        p := 0;
        sign := '0';
        a_c <= a;
        b_c <= b;
        q_c <= q;
        r_c <= r;
        o_c <= o;
        done_c <= done_o;
        next_state <= state;

        case ( state ) is 
            when s0 =>
                -- idle: wait for reset (start)
                if ( start = '1' ) then
                    a_c <= if_cond(signed(dividend) < to_signed(0, DWIDTH), std_logic_vector(-signed(dividend)), dividend);
                    b_c <= if_cond(signed(divisor) < to_signed(0, DWIDTH), std_logic_vector(resize(-signed(divisor),DWIDTH)), std_logic_vector(resize(signed(divisor),DWIDTH)));
                    q_c <= (others => '0');
                    o_c <= '0';
                    done_c <= '0';
                    next_state <= s1;
                end if;
                
            when s1 =>
                if ( unsigned(b) = to_unsigned(0, DWIDTH) ) then
                    o_c <= '1'; -- divide by zero
                    next_state <= s2;
                elsif ( unsigned(b) = to_unsigned(1, DWIDTH) ) then
                    q_c <= a; -- divide by one
                    a_c <= (others => '0');
                    next_state <= s2;
                elsif ( (unsigned(b) /= to_unsigned(0, DWIDTH)) and (unsigned(a) >= unsigned(b)) ) then
                    p := get_msb_pos_rec(a) - get_msb_pos_rec(b);                    
                    if ( unsigned(unsigned(b) SLL p) > unsigned(a) ) then
                        p := p - 1;
                    end if;
                    q_c <= std_logic_vector(unsigned(q) + unsigned(to_unsigned(1, DWIDTH) SLL p));
                    a_c <= std_logic_vector(unsigned(a) - unsigned(resize(unsigned(b),DWIDTH) SLL p));
                    next_state <= s1;
                else
                    next_state <= s2;
                end if;

            when s2 =>
                sign := dividend(DWIDTH-1) xor divisor(DWIDTH-1);
                q_c <= if_cond(sign = '1', std_logic_vector(-signed(q)), q);
                r_c <= if_cond(dividend(DWIDTH-1) = '1', std_logic_vector(resize(-signed(a),DWIDTH)), std_logic_vector(resize(signed(a),DWIDTH)));
                done_c <= '1';
                next_state <= s0;
                
            when OTHERS =>
                a_c <= (others => 'X');
                b_c <= (others => 'X');
                q_c <= (others => 'X');
                r_c <= (others => 'X');
                o_c <= 'X';
                done_c <= 'X';
                next_state <= s0;
        end case;
    end process div_process;

    -- output ports from registered signals
    done <= done_o;
    overflow <= o;
    remainder <= r;
    quotient <= q;
    
end architecture behavior;
