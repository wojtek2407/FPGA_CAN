`timescale 1ns / 1ps

`define CAN_WISHBONE_IF

`define CAN_MODE_RESET                  1'h1    /* Reset mode */
`define CAN_TIMING0_BRP                 6'h0    /* Baud rate prescaler */
`define CAN_TIMING0_SJW                 2'h1    /* SJW */
`define CAN_TIMING1_TSEG1               4'hf    /* TSEG1 segment */
`define CAN_TIMING1_TSEG2               3'h2    /* TSEG2 segment */

module dual_can_tb();

reg  clk;

reg  wb_clk_i;
reg  wb_rst_i;

// can0 wishbone
reg  [7:0] wb0_dat_i;
wire [7:0] wb0_dat_o;
reg        wb0_cyc_i;
reg        wb0_we_i;
reg  [7:0] wb0_adr_i;
wire       wb0_ack_o;
reg        wb0_stb_i;

// can1 wishbone
reg  [7:0] wb1_dat_i;
wire [7:0] wb1_dat_o;
reg        wb1_cyc_i;
reg        wb1_we_i;
reg  [7:0] wb1_adr_i;
wire       wb1_ack_o;
reg        wb1_stb_i;

wire can_bus;
wire can0_tx, can1_tx;
wire can0_irq_n, can1_irq_n;

can_top u_can0( 
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wb_dat_i(wb0_dat_i),
    .wb_dat_o(wb0_dat_o),
    .wb_cyc_i(wb0_cyc_i),
    .wb_stb_i(wb0_stb_i),
    .wb_we_i(wb0_we_i),
    .wb_adr_i(wb0_adr_i),
    .wb_ack_o(wb0_ack_o),
    .clk_i(clk),
    .rx_i(can_bus),
    .tx_o(can0_tx),
    .bus_off_on(),
    .irq_on(can0_irq_n),
    .clkout_o()
);

can_top u_can1( 
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wb_dat_i(wb1_dat_i),
    .wb_dat_o(wb1_dat_o),
    .wb_cyc_i(wb1_cyc_i),
    .wb_stb_i(wb1_stb_i),
    .wb_we_i(wb1_we_i),
    .wb_adr_i(wb1_adr_i),
    .wb_ack_o(wb1_ack_o),
    .clk_i(clk),
    .rx_i(can_bus),
    .tx_o(can1_tx),
    .bus_off_on(),
    .irq_on(can1_irq_n),
    .clkout_o()
);


// can clk 40 MHz
initial
begin
    clk=0;
    forever #12.5 clk = ~clk;
end

// wishbone clk 10 MHz
initial
begin
    wb_clk_i=0;
    forever #50 wb_clk_i = ~wb_clk_i;
end

assign can_bus = can0_tx & can1_tx;

reg [7:0] rx_data = 8'h00;
integer i = 0;
integer seed = 0;

reg [7:0] can0_tx_data [7:0];
reg [7:0] can1_tx_data [7:0];

initial 
begin

    seed = 100;
    $srandom(seed);
    for (i = 0; i < 8; i = i + 1) begin
        can0_tx_data[i] = $urandom_range(0,255);
        can1_tx_data[i] = $urandom_range(0,255);
    end

    wb0_we_i  = 0;
    wb0_cyc_i = 0;
    wb0_stb_i = 0;
    wb0_dat_i = 0;
    wb0_adr_i = 0;
    wb1_we_i  = 0;
    wb1_cyc_i = 0;
    wb1_stb_i = 0;
    wb1_dat_i = 0;
    wb1_adr_i = 0;
    
    wb_rst_i = 1;
    #10000
    @(posedge clk) wb_rst_i = 0;
    #10000
    
    write_can0_register(8'h00, 8'h01); // reset mode on
    write_can0_register(8'h06, {`CAN_TIMING0_SJW, `CAN_TIMING0_BRP});  
    write_can0_register(8'h07, {1'b0, `CAN_TIMING1_TSEG2, `CAN_TIMING1_TSEG1});
    write_can0_register(8'h04, 8'h00); // acceptance code
    write_can0_register(8'h05, 8'hff); // acceptance mask
    write_can0_register(8'h00, 8'h02); // reset mode off
    write_can0_register(8'h0A, 8'h88); // Writing ID[10:3]
    write_can0_register(8'h0B, 8'h48); // Writing ID[2:0], rtr = 0, length = 8 
    for (i = 0; i < 8; i = i + 1) write_can0_register(8'h0C+i, can0_tx_data[i]);
    
    write_can1_register(8'h00, 8'h01); // reset mode on
    write_can1_register(8'h06, {`CAN_TIMING0_SJW, `CAN_TIMING0_BRP});  
    write_can1_register(8'h07, {1'b0, `CAN_TIMING1_TSEG2, `CAN_TIMING1_TSEG1});
    write_can1_register(8'h04, 8'h00); // acceptance code
    write_can1_register(8'h05, 8'hff); // acceptance mask
    write_can1_register(8'h00, 8'h02); // reset mode off
    write_can1_register(8'h0A, 8'h88); // Writing ID[10:3]
    write_can1_register(8'h0B, 8'hA8); // Writing ID[2:0], rtr = 0, length = 8 
    for (i = 0; i < 8; i = i + 1) write_can1_register(8'h0C+i, can1_tx_data[i]);
    
    #10000

    fork
        write_can0_register(8'h01, 8'h01); // tx_request
        write_can1_register(8'h01, 8'h01); // tx_request  
    join
    
    @(!can0_irq_n & !can1_irq_n);
    
    for (i = 0; i < 8; i = i + 1) begin
        read_can0_register(8'h16+i, rx_data);
        if (rx_data == can1_tx_data[i]) $display("ok");
        else $display("nok");
    end
    write_can0_register(8'h01, 8'h4);
    
    for (i = 0; i < 8; i = i + 1) begin
        read_can1_register(8'h16+i, rx_data);
        if (rx_data == can0_tx_data[i]) $display("ok");
        else $display("nok");
    end
    write_can1_register(8'h01, 8'h4);

    $stop;
    
end

task write_can0_register;
    input [7:0] address;
    input [7:0] value;
    
    begin
        @(posedge wb_clk_i) begin
            wb0_we_i  = 1;
            wb0_cyc_i = 1;
            wb0_stb_i = 1;
            wb0_dat_i = value;
            wb0_adr_i = address;
        end
        @(negedge wb0_ack_o) begin
            wb0_we_i  = 0;
            wb0_cyc_i = 0;
            wb0_stb_i = 0;
        end
    end
endtask

task write_can1_register;
    input [7:0] address;
    input [7:0] value;
    
    begin
        @(posedge wb_clk_i) begin
            wb1_we_i  = 1;
            wb1_cyc_i = 1;
            wb1_stb_i = 1;
            wb1_dat_i = value;
            wb1_adr_i = address;
        end
        @(negedge wb1_ack_o) begin
            wb1_we_i  = 0;
            wb1_cyc_i = 0;
            wb1_stb_i = 0;
        end
    end
endtask

task read_can0_register;
    input [7:0] address;
    output [7:0] value;
    begin
        @(posedge wb_clk_i) begin
            wb0_we_i  = 0;
            wb0_cyc_i = 1;
            wb0_stb_i = 1;
            wb0_adr_i = address;
        end
        @(posedge wb0_ack_o) begin
            value = wb0_dat_o;
        end
        @(negedge wb0_ack_o) begin
            wb0_we_i  = 0;
            wb0_cyc_i = 0;
            wb0_stb_i = 0;
        end
    end
endtask

task read_can1_register;
    input [7:0] address;
    output [7:0] value;
    begin
        @(posedge wb_clk_i) begin
            wb1_we_i  = 0;
            wb1_cyc_i = 1;
            wb1_stb_i = 1;
            wb1_adr_i = address;
        end
        @(posedge wb1_ack_o) begin
            value = wb1_dat_o;
        end
        @(negedge wb1_ack_o) begin
            wb1_we_i  = 0;
            wb1_cyc_i = 0;
            wb1_stb_i = 0;
        end
    end
endtask

endmodule
