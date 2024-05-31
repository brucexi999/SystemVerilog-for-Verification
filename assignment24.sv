class Transaction;
 
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit wr;
    
endclass

class Generator;
    Transaction transaction;
    mailbox #(Transaction) mailBox;

    function new(mailbox #(Transaction) mailBox);
        this.mailBox = mailBox;
    endfunction

    task main();
        for (int i=0; i<10; i++) begin
            transaction = new();
            assert(transaction.randomize()) else $display("Randomization failed.");
            mailBox.put(transaction);
            $display("Generator: a = %0d, b = %0d, wr = %0d", transaction.a, transaction.b, transaction.wr);
            #1;
        end
    endtask

endclass

class Driver;
    Transaction transaction;
    mailbox #(Transaction) mailBox;

    function new(mailbox #(Transaction) mailBox);
        this.mailBox = mailBox;
    endfunction

    task main();
        forever begin
            mailBox.get(transaction);
            $display("Driver: a = %0d, b = %0d, wr = %0d", transaction.a, transaction.b, transaction.wr);
            #1;
        end
    endtask

endclass;

module tb;
    Generator generator;
    Driver driver;
    mailbox #(Transaction) mailBox;

    initial begin
        mailBox = new();
        generator = new(mailBox);
        driver = new(mailBox);

        fork
            generator.main();
            driver.main();
        join_any
        $finish();
    end

endmodule

