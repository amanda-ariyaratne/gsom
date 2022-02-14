`timescale  1 ns / 1 ps
module gsom_tb();
    reg clk = 0;
    wire [31:0] out;
    wire completed;
    reg reset = 0;
    reg en = 0;
    
    gsom uut(
        .clk(clk),
        .reset(reset),
        .done_training(completed)
    );
    
    reg [32:0] i=0;
    initial begin
        for (i=0;i<1000_000_000; i=i+1) begin
            $display("i %d", i);
            clk = ~clk;
            if (completed)
                $finish;
            #10;
        end
    end
    

endmodule

