`timescale 1ns/1ns

class Generator;
    rand bit [4:0] a;
    rand bit [5:0] b;
    static int count = 0;

    constraint data {
        a inside {[0:8]};
        b inside {[0:5]};
    }

    task display_rand_data();
        $display("a = %0d, b = %0d", a, b);
    endtask

    task display_rand_fail_counter();
        $display("Randomization failed %0d times", count);
    endtask

    function void rand_fail_counter();
        count ++;
    endfunction

endclass

module tb;
    Generator generator;

    initial begin
        for (int i = 0; i < 20; i++) begin
            generator = new();
            if (!generator.randomize()) begin
                generator.rand_fail_counter();
            end
            generator.display_rand_data();
            #20;
        end
        generator.display_rand_fail_counter();
    end

endmodule