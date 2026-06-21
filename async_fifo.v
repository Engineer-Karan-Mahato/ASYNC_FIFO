module async_fifo #(
        parameter DATA_WIDTH = 8,
        parameter ADDR_WIDTH = 3
    )(
        input  wr_clk,  rd_clk,
        input  wr_rst,  rd_rst,
        input  wr_en,   rd_en,
        input       [DATA_WIDTH-1 : 0]   wr_data,
        output reg  [DATA_WIDTH-1 : 0]   rd_data,
        output reg wr_full,
        output reg rd_empty
    );

    // memory depth = 2^address width
    localparam MEMORY_DEPTH = ( 1 << ADDR_WIDTH ) ;

    // dual port memory for temporary data storage
    reg [DATA_WIDTH-1 : 0] memory [0 : MEMORY_DEPTH-1];
    
    // full and empty next wire
    wire wr_full_next  ;
    wire rd_empty_next ;

    // write and read pointers in binary
    reg [ADDR_WIDTH : 0] wr_bin,   rd_bin ;

    // write and read pointers in gray
    reg [ADDR_WIDTH : 0] wr_gray,  rd_gray ;

    // write 2 ff sync signals
    reg [ADDR_WIDTH : 0] wr_gray_sync1,  wr_gray_sync2;

    // read 2 ff sync signals
    reg [ADDR_WIDTH : 0] rd_gray_sync1,  rd_gray_sync2;

    // write and read next pointer in binary
    wire [ADDR_WIDTH : 0] wr_bin_next,   rd_bin_next ;

    // write and read pointers in gray
    wire [ADDR_WIDTH : 0] wr_gray_next,  rd_gray_next ;

    // logic for binary next pointers
    assign wr_bin_next = wr_bin + (wr_en && !wr_full ) ;
    assign rd_bin_next = rd_bin + (rd_en && !rd_empty) ;

    // logic for gray next pointers
    assign wr_gray_next = wr_bin_next ^ (wr_bin_next >> 1) ;
    assign rd_gray_next = rd_bin_next ^ (rd_bin_next >> 1) ;

    // write full logic
    generate
        if ( ADDR_WIDTH == 1) begin : FULL_AD1
            assign wr_full_next = ( wr_gray_next == ~rd_gray_sync2 ) ;
        end
        else begin : FULL_AD_GT1
            assign wr_full_next = ( wr_gray_next == { ~rd_gray_sync2[ADDR_WIDTH : ADDR_WIDTH-1] , rd_gray_sync2[ADDR_WIDTH-2 : 0] } ) ;
        end
    endgenerate
    
    // read empty logic
    assign rd_empty_next = (rd_gray_next == wr_gray_sync2) ;


    /////////////////////////////////
    // write clock domain
    /////////////////////////////////

    // writing data to memory
    always @(posedge wr_clk or negedge wr_rst) begin
        if (!wr_rst) begin
            wr_bin  <= 0 ;
            wr_gray <= 0 ;
            wr_full <= 0 ;
        end

        else begin 
            if (wr_en && !wr_full) begin
                memory[wr_bin[ADDR_WIDTH-1 : 0]] <= wr_data ;
            end

            wr_bin   <= wr_bin_next  ;
            wr_gray  <= wr_gray_next ;
            wr_full  <= wr_full_next ;
        end
    end

    // gray read pointer synchronization in write clock domain
    always @(posedge wr_clk or negedge wr_rst) begin
        if (!wr_rst) begin
            rd_gray_sync1 <= 0 ;
            rd_gray_sync2 <= 0 ;
        end
        else begin
            rd_gray_sync1 <= rd_gray ;
            rd_gray_sync2 <= rd_gray_sync1 ; 
        end
    end


    /////////////////////////////////
    // read clock domain
    /////////////////////////////////

    // reading data from memory
    always @(posedge rd_clk or negedge rd_rst) begin
        if (!rd_rst) begin
            rd_bin   <= 0 ;
            rd_gray  <= 0 ;
            rd_data  <= 0 ;
            rd_empty <= 1 ;
        end
        else begin
            if (rd_en && !rd_empty) begin
                rd_data <= memory[rd_bin[ADDR_WIDTH-1 : 0]] ;
            end

            rd_bin   <= rd_bin_next   ;
            rd_gray  <= rd_gray_next  ;
            rd_empty <= rd_empty_next ;
        end
    end

    // gray write pointer synchronization in read clock domain
    always @(posedge rd_clk or negedge rd_rst) begin
        if (!rd_rst) begin
            wr_gray_sync1 <= 0 ;
            wr_gray_sync2 <= 0 ;
        end
        else begin
            wr_gray_sync1 <= wr_gray ;
            wr_gray_sync2 <= wr_gray_sync1 ;
        end
    end
endmodule