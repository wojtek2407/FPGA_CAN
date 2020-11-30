`timescale 1ns / 1ps

`define CAN_WISHBONE_IF

`define CAN_MODE_RESET                  1'h1    /* Reset mode */

`define CAN_TIMING0_BRP                 6'h3    /* Baud rate prescaler (2*(value+1)) */
`define CAN_TIMING0_SJW                 2'h1    /* SJW (value+1) */

`define CAN_TIMING1_TSEG1               4'hf    /* TSEG1 segment (value+1) */
`define CAN_TIMING1_TSEG2               3'h2    /* TSEG2 segment (value+1) */
`define CAN_TIMING1_SAM                 1'h0    /* Triple sampling */

module dual_can_tb();

parameter BRP = 2*(`CAN_TIMING0_BRP + 1);

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

wire rx_and_tx;
wire can0_tx, can1_tx;

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
    .rx_i(rx_and_tx),
    .tx_o(can0_tx),
    .bus_off_on(),
    .irq_on(),
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
    .rx_i(rx_and_tx),
    .tx_o(can1_tx),
    .bus_off_on(),
    .irq_on(),
    .clkout_o()
);


// can clk 32 MHz
initial
begin
    clk=0;
    forever #31.25 clk = ~clk;
end

// wishbone clk 10 MHz
initial
begin
    wb_clk_i=0;
    forever #50 wb_clk_i = ~wb_clk_i;
end

assign rx_and_tx = can0_tx & can1_tx;

reg [7:0] rx_data = 8'h00;
integer i = 0;

initial 
begin

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
    #1000
    wb_rst_i = 0;
    #1000
    
    // reset mode on
    write_can0_register(8'd0, 8'h01);  
    // can timming
    write_can0_register(8'd6, {`CAN_TIMING0_SJW, `CAN_TIMING0_BRP});  
    write_can0_register(8'd7, {`CAN_TIMING1_SAM, `CAN_TIMING1_TSEG2, `CAN_TIMING1_TSEG1});
    write_can0_register(8'd31, {1'b0, 3'h0, 1'b0, 3'h0});   // Setting the normal mode (not extended)
    write_can0_register(8'd4, 8'h84); // acceptance code
    write_can0_register(8'd5, 8'h00); // acceptance mask
    // reset mode off
    write_can0_register(8'd0, 8'h00);  
    
    write_can0_register(8'd10, 8'h88); // Writing ID[10:3] = 0x55
    write_can0_register(8'd11, 8'h28); // Writing ID[2:0] = 0x3, rtr = 1, length = 7
    write_can0_register(8'd12, 8'h00); // data byte 1
    write_can0_register(8'd13, 8'h11); // data byte 2
    write_can0_register(8'd14, 8'h22); // data byte 3
    write_can0_register(8'd15, 8'h33); // data byte 4
    write_can0_register(8'd16, 8'h44); // data byte 5
    write_can0_register(8'd17, 8'h55); // data byte 6
    write_can0_register(8'd18, 8'h66); // data byte 7
    write_can0_register(8'd19, 8'h77); // data byte 8
    
    
    // reset mode on
    write_can1_register(8'd0, 8'h01);  
    // can timming
    write_can1_register(8'd6, {`CAN_TIMING0_SJW, `CAN_TIMING0_BRP});  
    write_can1_register(8'd7, {`CAN_TIMING1_SAM, `CAN_TIMING1_TSEG2, `CAN_TIMING1_TSEG1});
    write_can1_register(8'd31, {1'b0, 3'h0, 1'b0, 3'h0});   // Setting the normal mode (not extended)
    write_can1_register(8'd4, 8'h88); // acceptance code
    write_can1_register(8'd5, 8'h00); // acceptance mask
    // reset mode off
    write_can1_register(8'd0, 8'h00);  
    
    write_can1_register(8'd10, 8'h84); // Writing ID[10:3] = 0x55
    write_can1_register(8'd11, 8'h28); // Writing ID[2:0] = 0x3, rtr = 1, length = 7
    write_can1_register(8'd12, 8'hff); // data byte 1
    write_can1_register(8'd13, 8'hee); // data byte 2
    write_can1_register(8'd14, 8'hdd); // data byte 3
    write_can1_register(8'd15, 8'hcc); // data byte 4
    write_can1_register(8'd16, 8'hbb); // data byte 5
    write_can1_register(8'd17, 8'haa); // data byte 6
    write_can1_register(8'd18, 8'h99); // data byte 7
    write_can1_register(8'd19, 8'h88); // data byte 8
    
    #100000;
 
    fork
        write_can0_register(8'd1, 8'h01); // tx_request
        write_can1_register(8'd1, 8'h01); // tx_request  
    join
    
    #3500000
    

    for (i = 0; i < 8; i = i + 1) begin
        read_can0_register(22+i, rx_data);
    end
    write_can0_register(8'd1, 8'h4);
    
    for (i = 0; i < 8; i = i + 1) begin
        read_can1_register(22+i, rx_data);
    end
    write_can1_register(8'd1, 8'h4);
    
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
