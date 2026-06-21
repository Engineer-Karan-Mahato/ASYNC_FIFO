`timescale 1ns/1ps

module async_fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 3;
    parameter DEPTH = (1 << ADDR_WIDTH);

    reg wr_clk, rd_clk;
    reg wr_rst, rd_rst;
    reg wr_en, rd_en;
    reg [DATA_WIDTH-1:0] wr_data;

    wire [DATA_WIDTH-1:0] rd_data;
    wire wr_full;
    wire rd_empty;

    integer i;
    integer error_count;

    reg [DATA_WIDTH-1:0] expected_data [0:DEPTH-1];

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

    // different clocks
    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    task fifo_write;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge wr_clk);
            while (wr_full) begin
                @(negedge wr_clk);
            end

            wr_data = data;
            wr_en   = 1;

            @(negedge wr_clk);
            wr_en   = 0;
            wr_data = 0;
        end
    endtask

    task fifo_read;
        input [DATA_WIDTH-1:0] expected;
        begin
            @(negedge rd_clk);
            while (rd_empty) begin
                @(negedge rd_clk);
            end

            rd_en = 1;

            @(posedge rd_clk);
            #1;

            if (rd_data !== expected) begin
                $display("ERROR: Expected = %h, Got = %h", expected, rd_data);
                error_count = error_count + 1;
            end
            else begin
                $display("PASS : Expected = %h, Got = %h", expected, rd_data);
            end

            @(negedge rd_clk);
            rd_en = 0;
        end
    endtask

    initial begin
        wr_clk = 0;
        rd_clk = 0;
        wr_rst = 0;
        rd_rst = 0;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;
        error_count = 0;

        $dumpfile("async_fifo.vcd");
        $dumpvars(0, async_fifo_tb);

        // reset
        #30;
        wr_rst = 1;
        rd_rst = 1;

        #30;

        // write 7 values into FIFO
        for (i = 0; i < DEPTH-1; i = i + 1) begin
            expected_data[i] = i + 8'h10;
            fifo_write(expected_data[i]);
        end

        #50;

        // read 7 values from FIFO
        for (i = 0; i < DEPTH-1; i = i + 1) begin
            fifo_read(expected_data[i]);
        end

        #50;

        if (error_count == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED with %0d errors", error_count);

        $finish;
    end

endmodule
