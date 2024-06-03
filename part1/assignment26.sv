/*
Create Monitor and Scoreboard Code for Synchronous 4-bit Multiplier. Stimulus is generated in Testbench top so do not add Transaction, 
Generator, or Driver Code. Also, add the Scoreboard model to compare the response with an expected result.
*/

module top
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

interface top_if;
  logic clk;
  logic [3:0] a, b;
  logic [7:0] mul;
  
endinterface

class Transaction;
    bit [3:0] a,b;
    bit [7:0] mul;
endclass

class Monitor;
    Transaction transaction;
    mailbox #(Transaction) mailBox;
    virtual top_if IF;

    function new(mailbox #(Transaction) mailBox);
        this.mailBox = mailBox;
    endfunction

    task main();
        transaction = new();
        forever begin
            repeat (2) @(posedge IF.clk);
            transaction.a = IF.a;
            transaction.b = IF.b;
            transaction.mul = IF.mul;
            $display("Monitor: a = %0d, b = %0d, product = %0d", transaction.a, transaction.b, transaction.mul);
            mailBox.put(transaction);
        end
    endtask

endclass

class Scoreboard;
    Transaction transaction;
    mailbox #(Transaction) mailBox;

    function new(mailbox #(Transaction) mailBox);
        this.mailBox = mailBox;
    endfunction

    task main();
        forever begin
            #20;
            mailBox.get(transaction);
            $display("Scoreboard: a = %0d, b = %0d, product = %0d", transaction.a, transaction.b, transaction.mul);
            mul_result_check: assert (transaction.mul == transaction.a * transaction.b)
                else $error("Assertion failed!");
        end
    endtask

endclass

module tb;
  
    top_if vif();
    mailbox #(Transaction) mailBox;
    Monitor monitor;
    Scoreboard scoreboard;
    
    top dut (vif.clk, vif.a, vif.b, vif.mul);
    
    initial begin
        vif.clk <= 0;
    end
    
    always #5 vif.clk <= ~vif.clk;
    
    initial begin
        for(int i = 0; i<20; i++) begin
        repeat (2) @(posedge vif.clk);
        vif.a <= $urandom_range(1,15);
        vif.b <= $urandom_range(1,15);
        end
        
    end

    initial begin
        mailBox = new();
        monitor = new(mailBox);
        scoreboard = new(mailBox);
        monitor.IF = vif;
        fork
            monitor.main();
            scoreboard.main();
        join_any
    end
    
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;    
        #300;
        $finish();
    end
  
endmodule