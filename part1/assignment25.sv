// Create Transaction, Generator and Driver code for Synchronus 4-bit Multiplier.
module Multiplier
(
  input clk,
  input [3:0] a,b,
  output reg [7:0] mul
);
  
  always@(posedge clk)
    begin
     mul <= a * b;
    end
  
endmodule

class Transaction;
    randc bit [3:0] a, b;
    bit [7:0] mul;

    function Transaction copy();
        copy = new();
        copy.a = this.a;
        copy.b = this.b;
        copy.mul = this.mul;
    endfunction

endclass

interface MultiplierInterface;
    logic [3:0] a,b;
    logic [7:0] mul;
    logic clk;
endinterface

class Generator;
    Transaction transaction;
    mailbox #(Transaction) mailBox;
    
    function new(mailbox #(Transaction) mailBox);
        this.mailBox = mailBox;
        transaction = new();
    endfunction

    task main();
        for (int i = 0; i < 20; i ++) begin
            transaction.randomize();
            $display("Generator: a = %0d, b = %0d", transaction.a, transaction.b);
            mailBox.put(transaction.copy());
            #10;
        end 
    endtask

endclass

class Driver;
    Transaction transaction;
    mailbox #(Transaction) mailBox;
    virtual MultiplierInterface multiplierInterface;

    function new(mailbox #(Transaction) mailBox);
        this.mailBox = mailBox;
    endfunction

    task main();
        forever begin
            mailBox.get(transaction);
            @(posedge multiplierInterface.clk);
            multiplierInterface.a <= transaction.a;
            multiplierInterface.b <= transaction.b;
            $display("Driver: a = %0d, b = %0d", transaction.a, transaction.b);
        end
    endtask

endclass

module tb;

    MultiplierInterface multiplierInterface();
    Driver driver;
    Generator generator;
    mailbox #(Transaction) mailBox;
    Multiplier dut (multiplierInterface.clk, multiplierInterface.a, multiplierInterface.b, multiplierInterface.mul);

    initial begin
        multiplierInterface.clk = 0;
    end

    always #5 multiplierInterface.clk = ~ multiplierInterface.clk;

    initial begin
        mailBox = new();
        driver = new(mailBox);
        generator = new(mailBox);
        driver.multiplierInterface = multiplierInterface;
        fork
            generator.main();
            driver.main();
        join_any
        $finish();
    end

endmodule

