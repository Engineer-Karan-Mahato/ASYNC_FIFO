`timescale 1ns/1ps

module async_fifo_tb ;
    parameter DATA_WIDTH = 8 ;
    parameter ADDR_WIDTH = 3 ;
    
    reg  wr_clk,  rd_clk ;
    reg  wr_rst,  rd_rst ;
    reg  wr_en,   rd_en  ;
    reg  [DATA_WIDTH-1 : 0] wr_data ;
    
    wire [DATA_WIDTH-1 : 0] rd_data ;
    wire wr_full ;
    wire rd_empty ;

    
    integer i;

    // initialize async_fifo module 
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk(wr_clk),  
        .rd_clk(rd_clk),
        .wr_rst(wr_rst),  
        .rd_rst(rd_rst),
        .wr_en(wr_en),   
        .rd_en(rd_en),
        .wr_data(wr_data), 
        .rd_data(rd_data),
        .wr_full(wr_full), 
        .rd_empty(rd_empty)
    );

    // set write and read clock period
    always #5 wr_clk = ~wr_clk ;
    always #7 rd_clk = ~rd_clk ;


    initial begin
        wr_clk = 0;
        rd_clk = 0;

        wr_en = 0;
        rd_en = 0;

        wr_data = 0;

        // assert reset
        wr_rst = 0;
        rd_rst = 0;

        #20;

        // de-assert reset
        wr_rst = 1;
        rd_rst = 1;

        // extra wait befor write
        repeat(3) @(posedge wr_clk);

        // write loop
        for ( i = 0 ; i<8 ; i = i+1) begin
            @(posedge wr_clk);
            wr_en = 1;
            $display("Time=%0t\t Data Write=%h", $time, wr_data);
            wr_data = 8'h05 + i;  
        end

        @(posedge wr_clk);
        wr_en = 0;

        // extra wait before
        repeat(3) @(posedge rd_clk);

        // read loop
        for ( i = 0 ; i<8 ; i = i+1) begin
            @(posedge rd_clk);
            rd_en = 1;
            $display("Time=%0t\t Data read=%h", $time, rd_data);
        end

        @(posedge rd_clk);
        rd_en = 0;

        #100;
        $finish();
    end

    // dump vcd file
    initial begin
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars(0, async_fifo_tb);
    end
endmodule