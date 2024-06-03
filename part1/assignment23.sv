class Transaction;
 
    bit [7:0] addr = 7'h12;
    bit [3:0] data = 4'h4;
    bit we = 1'b1;
    bit rst = 1'b0;
 
endclass

class Generator;

    Transaction tran_out;
    mailbox #(Transaction) mbx;

    function new (mailbox #(Transaction) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        tran_out = new();
        mbx.put(tran_out);
        $display("Generator: addr = %0d, data = %0d, we = %0d, rst = %0d", tran_out.data, tran_out.addr, tran_out.we, tran_out.rst);
    endtask

endclass

class Driver;

    Transaction tran_in;
    mailbox #(Transaction) mbx;

    function new (mailbox #(Transaction) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        mbx.get(tran_in);
        $display("Driver: addr = %0d, data = %0d, we = %0d, rst = %0d", tran_in.data, tran_in.addr, tran_in.we, tran_in.rst);
    endtask

endclass

module tb;

    Generator generator;
    Driver driver;
    mailbox #(Transaction) mbx;

    initial begin
        mbx = new();
        generator = new(mbx);
        driver = new(mbx);

        fork
            generator.run();
            driver.run();
        join
    end

endmodule