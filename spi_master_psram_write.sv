// The SPI write bus cycle to PSRAM looks like this...
// 1 byte command + 3 bytes address + 2 bytes data = 6 bytes sent
// the FSM states are IDLE, CMD, ADDR and DATA, and this matches that order
// 48 SCLK cycles are needed, and the chip select goes active 4 CLK cycles early
// and chip select goes in-active 4 CLK cycles after SCLK stops, for a total duration of 56 CLK cycles

module spi_master_psram_write (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start, // pulse to start
  input  logic  [15:0] adc_data,
  output logic         busy,

  output logic         sclk,
  output logic         mosi,
//  input  logic         miso,
  output logic         cs_n
);
  
  parameter CMD_CLK_COUNT  = 11;    // 1 byte  * 8 + 4 chip select
  parameter ADDR_CLK_COUNT = 23;    // 3 bytes * 8
  parameter DATA_CLK_COUNT = 19;    // 2 bytes * 8 + 4 chip select
  parameter CMD_DATA       = 8'h02; // write to PSRAM command

  typedef enum logic [1:0] {IDLE, CMD, ADDR, DATA} state_t;
  state_t next_state, state;
  
  logic        en_sclk;
  logic  [4:0] counter;
  logic [23:0] address;
  logic [15:0] data;

  assign busy = (state != IDLE);

//  Gowin_DHCEN u_spi_clk_gate
//    ( .clkout (sclk),    // output
//      .clkin  (clk),    // input
//      .ce     (en_sclk) // input
//    );

  assign sclk = clk && en_sclk; // dirty clock gate

  always_comb
    if ((state == IDLE) && start)                 next_state = CMD;
    else if ((state == CMD)  && (counter == 'd0)) next_state = ADDR;
    else if ((state == ADDR) && (counter == 'd0)) next_state = DATA;
    else if ((state == DATA) && (counter == 'd0)) next_state = IDLE;
    else                                          next_state = state;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) state <= IDLE;
    else        state <= next_state;

  // countdown style which makes it easier to use for indexing MOSI data
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)                                             counter <= 'd0;
    else if ((next_state != state) && (next_state == CMD))  counter <= CMD_CLK_COUNT;
    else if ((next_state != state) && (next_state == ADDR)) counter <= ADDR_CLK_COUNT;
    else if ((next_state != state) && (next_state == DATA)) counter <= DATA_CLK_COUNT;
    else if  (next_state == IDLE)                           counter <= 'd0;
    else if (counter != 'd0)                                counter <= counter - 'd1;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)                  cs_n <= 1'b1;
    else if (state == CMD)       cs_n <= 1'b0;
    else if (next_state == IDLE) cs_n <= 1'b1;

  always_ff @(negedge clk or negedge rst_n) // negative edge to avoid glitches when gating clk to make sclk
    if (!rst_n)                                   en_sclk <= 1'b0;
    else if ((state == CMD)  && (counter == 'd7)) en_sclk <= 1'b1;
    else if ((state == DATA) && (counter == 'd3)) en_sclk <= 1'b0;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)                                       address <= 'd0;
    else if ((state == DATA) && (next_state == IDLE)) address <= address + 'd2; // PSRAM has one address per byte

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)                                      data <= 'd0;
    else if ((state == IDLE) && (next_state == CMD)) data <= adc_data; // optional holding of input adc_data

  always_ff @(negedge clk or negedge rst_n) // PSRAM capures data on the positive edge of SCLK
    if (!rst_n)                                  mosi <= 1'b0;
    else if ((state == CMD) && (counter < 'd8))  mosi <= CMD_DATA[counter];
    else if (state == ADDR)                      mosi <= address[counter];
    else if ((state == DATA) && (counter > 'd3)) mosi <= data[counter - 'd4];
    else                                         mosi <= 1'b0;

endmodule
