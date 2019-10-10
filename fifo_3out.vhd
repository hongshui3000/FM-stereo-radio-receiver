

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo_3out is
generic
(
	constant FIFO_DATA_WIDTH : integer := 32;
	constant FIFO_BUFFER_SIZE : integer := 256
);
port
(
	signal reset    : in std_logic;

	signal rd_clk   : in std_logic;
	signal rd_en1    : in std_logic;
	signal rd_en2    : in std_logic;
	signal rd_en3    : in std_logic;
	signal rd_dout1  : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal rd_dout2  : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal rd_dout3  : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal rd_empty1 : out std_logic;
	signal rd_empty2 : out std_logic;
	signal rd_empty3 : out std_logic;

	signal wr_clk   : in std_logic;
	signal wr_en    : in std_logic;
	signal wr_din   : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal wr_full  : out std_logic
);
end entity fifo_3out;


architecture structure of fifo_3out is 

	component fifo is
	generic
	(
		constant FIFO_DATA_WIDTH : integer := 32;
		constant FIFO_BUFFER_SIZE : integer := 32
	);
	port
	(
		signal rd_clk : in std_logic;
		signal wr_clk : in std_logic;
		signal reset : in std_logic;
		signal rd_en : in std_logic;
		signal wr_en : in std_logic;
		signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
		signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
		signal full : out std_logic;
		signal empty : out std_logic
	);
	end component fifo;

	signal full : std_logic_vector(2 downto 0);
	signal empty : std_logic_vector(2 downto 0);

begin

	data1 : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => FIFO_BUFFER_SIZE,
		FIFO_DATA_WIDTH => FIFO_DATA_WIDTH
	)
	port map
	(
		rd_clk 	=> rd_clk,
		wr_clk 	=> wr_clk,
		reset 	=> reset,
		rd_en 	=> rd_en1,
		wr_en 	=> wr_en,
		din 	=> wr_din,
		dout 	=> rd_dout1,
		full 	=> full(0),
		empty 	=> rd_empty1
	);

	data2 : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => FIFO_BUFFER_SIZE,
		FIFO_DATA_WIDTH => FIFO_DATA_WIDTH
	)
	port map
	(
		rd_clk 	=> rd_clk,
		wr_clk 	=> wr_clk,
		reset 	=> reset,
		rd_en 	=> rd_en2,
		wr_en 	=> wr_en,
		din 	=> wr_din,
		dout 	=> rd_dout2,
		full 	=> full(1),
		empty 	=> rd_empty2
	);
	
	data3 : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => FIFO_BUFFER_SIZE,
		FIFO_DATA_WIDTH => FIFO_DATA_WIDTH
	)
	port map
	(
		rd_clk 	=> rd_clk,
		wr_clk 	=> wr_clk,
		reset 	=> reset,
		rd_en 	=> rd_en3,
		wr_en 	=> wr_en,
		din 	=> wr_din,
		dout 	=> rd_dout3,
		full 	=> full(2),
		empty 	=> rd_empty3
	);

	--rd_empty <= empty(0) or empty(1);

	wr_full <= full(0) or full(1) or full(2);

end architecture structure;
