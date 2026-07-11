
module qspi_master_psram_write (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start, // pulse to start
  input  logic [15:0] adc_data,
  output logic        busy,

  output logic        sck,
  output logic        sio0,
  output logic        sio1,
  output logic        sio2,
  output logic        sio3,
  output logic        cs_n
);
  
  parameter CMD_CLK_COUNT   = 9;    // 1 byte  * 8 + 2 chip select
  parameter ADDR_CLK_COUNT  = 5;    // 3 bytes * 2
  parameter DATA_CLK_COUNT  = 5;    // 2 bytes * 2 + 2 chip select
  parameter CMD_QUAD_WRITE  = 8'h38; // Quad Write PSRAM command

  typedef enum logic [1:0] {IDLE, CMD, ADDR, DATA} state_t;
  state_t next_state, state;
  logic en_sclk;
  logic  [4:0] counter;
  logic [23:0] address;
  logic [15:0] data;

  assign busy = (state != IDLE);

  assign sck = clk && en_sclk; // dirty clock gate

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
    else if (counter != 'd0)                                counter <= counter - 'd1;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)                  cs_n <= 1'b1;
    else if (state == CMD)       cs_n <= 1'b0;
    else if (next_state == IDLE) cs_n <= 1'b1;

  always_ff @(negedge clk or negedge rst_n)
    if (!rst_n)                                   en_sclk <= 1'b0;
    else if ((state == CMD)  && (counter == 'd7)) en_sclk <= 1'b1;
    else if ((state == DATA) && (counter == 'd1)) en_sclk <= 1'b0;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)                                       address <= 'd0;
    else if ((state == DATA) && (next_state == IDLE)) address <= address + 'd2;
    
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)                                       data <= 'hFFFF;  // optional buffering of adc_data
    else if ((state == DATA) && (next_state == IDLE)) data <= adc_data;

  always_ff @(negedge clk or negedge rst_n)
    if (!rst_n)                                   {sio3,sio2,sio1,sio0} <= 4'd0;
    else if ((state == CMD)  && (counter <  'd8))                  sio0 <= CMD_QUAD_WRITE[counter];
    else if ((state == ADDR) && (counter == 'd5)) {sio3,sio2,sio1,sio0} <= address[23:20];
    else if ((state == ADDR) && (counter == 'd4)) {sio3,sio2,sio1,sio0} <= address[19:16];
    else if ((state == ADDR) && (counter == 'd3)) {sio3,sio2,sio1,sio0} <= address[15:12];
    else if ((state == ADDR) && (counter == 'd2)) {sio3,sio2,sio1,sio0} <= address[11:8];
    else if ((state == ADDR) && (counter == 'd1)) {sio3,sio2,sio1,sio0} <= address[7:4];
    else if ((state == ADDR) && (counter == 'd0)) {sio3,sio2,sio1,sio0} <= address[3:0];
    else if ((state == DATA) && (counter == 'd5)) {sio3,sio2,sio1,sio0} <= data[15:12];
    else if ((state == DATA) && (counter == 'd4)) {sio3,sio2,sio1,sio0} <= data[11:8];
    else if ((state == DATA) && (counter == 'd3)) {sio3,sio2,sio1,sio0} <= data[7:4];
    else if ((state == DATA) && (counter == 'd2)) {sio3,sio2,sio1,sio0} <= data[3:0];
    else                                          {sio3,sio2,sio1,sio0} <= 'd0;

endmodule
