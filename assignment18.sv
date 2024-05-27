`timescale 1ns/1ns

class Generator;
    randc bit [7:0] x, y, z;
    constraint data {x inside {[0:50]}; y inside {[0:50]}; z inside {[0:50]};}
endclass

module tb;
    Generator generator;

    initial begin
        for (int i = 0; i < 20; i++) begin
            generator = new();
            if (!generator.randomize()) begin
                $display("Randomization failed at time %0t", $time);
                $finish();
            end
            $display("x = %0d, y = %0d, z = %0d", generator.x, generator.y, generator.z);
            #20;
        end
    end

endmodule