// Create a testbench environment for validating the SPI interface's ability to transmit data serially immediately when the CS signal goes low. 
// Utilize the negative edge of the SCLK to sample the MOSI signal in order to generate reference data.

module spi_master(
input clk, newd,rst,
input [11:0] din, 
output reg sclk,cs,mosi
    );
  
  typedef enum bit [1:0] {idle = 2'b00, enable = 2'b01, send = 2'b10, comp = 2'b11 } state_type;
  state_type state = idle;
  
  int countc = 0;
  int count = 0;
 
  /////////////////////////generation of sclk
 always@(posedge clk)
  begin
    if(rst == 1'b1) begin
      countc <= 0;
      sclk <= 1'b0;
    end
    else begin 
      if(countc < 3 )
          countc <= countc + 1;
      else
          begin
          countc <= 0;
          sclk <= ~sclk;
          end
    end
  end
  
  //////////////////state machine
    reg [11:0] temp;
    
    
  always@(posedge sclk)
  begin
    if(rst == 1'b1) 
    begin
      cs <= 1'b1; 
      mosi <= 1'b0;
    end
    else begin
     case(state)
         idle:
             begin
               if(newd == 1'b1) 
                 begin
                 state <= send;
                 temp <= din; 
                 cs <= 1'b0;
                 mosi <= din[0];
                 count <= 1;
                 end
               else begin
                 state <= idle;
                 temp <= 8'h00;
               end
             end
       
       
       send : begin
         if(count <= 11) begin
           mosi <= temp[count]; /////sending lsb first
           count <= count + 1;
         end
         else
             begin
               count <= 0;
               state <= idle;
               cs <= 1'b1;
               mosi <= 1'b0;
             end
       end
       
                
      default : state <= idle; 
       
   endcase
  end 
 end
  
endmodule

interface SPI_IF;
    logic clk, sclk, newd, rst, cs, mosi;
    logic [11:0] din;

endinterface

class Transaction;
    bit newd;
    randc bit [11:0] din;
    bit [11:0] dout;

    function Transaction copy();
        copy = new();
        copy.newd = this.newd;
        copy.din = this.din;
        copy.dout = this.dout;
    endfunction
endclass

class Generator;
    Transaction transaction;
    mailbox #(Transaction) mail_box_gen_dri, mail_box_gen_sco;
    int count = 10;
    event send_next_stimulus;

    function new(mailbox #(Transaction) mail_box_gen_dri, mail_box_gen_sco);
        this.mail_box_gen_dri = mail_box_gen_dri;
        this.mail_box_gen_sco = mail_box_gen_sco;
        transaction = new();
    endfunction

    task run();
        repeat(count) begin
            transaction.randomize();
            mail_box_gen_dri.put(transaction.copy());
            mail_box_gen_sco.put(transaction.copy());
            @(send_next_stimulus); 
        end
    endtask

endclass

class Driver;
    Transaction transaction;
    mailbox #(Transaction) mail_box;
    virtual SPI_IF spi_if;

    function new(mailbox #(Transaction) mail_box);
        this.mail_box = mail_box;
    endfunction

    task reset();
        spi_if.rst <= 1;
        spi_if.newd <= 0;
        spi_if.din <= 0;
        repeat(10) @(posedge spi_if.clk);
        spi_if.rst <= 0;
        repeat(10) @(posedge spi_if.clk);
        $display("[Driver] : Reset done");
        $display("-----------------------------------------");
    endtask

    task run();
        forever begin
            mail_box.get(transaction);
            @(posedge spi_if.sclk);
            spi_if.newd <= 1;
            spi_if.din <= transaction.din;
            @(posedge spi_if.sclk);
            spi_if.newd <= 0;
            wait(spi_if.sclk == 1);
            $display("[Driver] : Data sent to DUT : %0d",transaction.din);
        end
    endtask
endclass

class Monitor;
    Transaction transaction;
    mailbox #(Transaction) mail_box;
    virtual SPI_IF spi_if;

    function new(mailbox #(Transaction) mail_box);
        this.mail_box = mail_box;
        transaction = new();
    endfunction

    task run();
        forever begin
            @(negedge spi_if.sclk);
            wait(spi_if.cs == 0);
            //@(negedge spi_if.sclk);
            for (int i = 0; i < 12; i ++) begin
                @(negedge spi_if.sclk);
                transaction.dout[i] = spi_if.mosi;
            end
            wait(spi_if.cs == 1);
            $display("[Monitor] : Data sent to scoreboard : %0d", transaction.dout);
            mail_box.put(transaction);
        end
    endtask
endclass

class Scoreboard;
    Transaction transaction_gen_sco, transaction_mon_sco;
    mailbox #(Transaction) mail_box_gen_sco;
    mailbox #(Transaction) mail_box_mon_sco;
    event send_next_stimulus;

    function new(mailbox #(Transaction) mail_box_gen_sco, mailbox #(Transaction) mail_box_mon_sco);
        this.mail_box_gen_sco = mail_box_gen_sco;
        this.mail_box_mon_sco = mail_box_mon_sco;
    endfunction

    task run();
        forever begin
            mail_box_mon_sco.get(transaction_mon_sco);
            mail_box_gen_sco.get(transaction_gen_sco);
            $display("[Scoreboard] : DRV : %0d MON : %0d", transaction_mon_sco.dout, transaction_gen_sco.din);
            assert (transaction_mon_sco.dout == transaction_gen_sco.din) else $error("[Scoreboard] : DATA MISMATCHED!");
            $display("-----------------------------------------");
            -> send_next_stimulus;
        end
    endtask

endclass

class Environment;
    Generator generator;
    Driver driver;
    Monitor monitor;
    Scoreboard scoreboard;
    mailbox #(Transaction) mbx_gen_dri, mbx_gen_sco, mbx_mon_sco;
    virtual SPI_IF spi_if;
    event send_next_stimulus;

    function new(virtual SPI_IF spi_if);
        mbx_gen_dri = new();
        mbx_gen_sco = new();
        mbx_mon_sco = new();
        generator = new(mbx_gen_dri, mbx_gen_sco);
        driver = new(mbx_gen_dri);
        monitor = new(mbx_mon_sco);
        scoreboard = new(mbx_gen_sco, mbx_mon_sco);
        driver.spi_if = spi_if;
        monitor.spi_if = spi_if;
        generator.send_next_stimulus = send_next_stimulus;
        scoreboard.send_next_stimulus = send_next_stimulus;
    endfunction

    task run();
        driver.reset();
        fork
            generator.run();
            driver.run();
            monitor.run();
            scoreboard.run();
        join_any
        $finish();
    endtask
endclass

module tb;
    SPI_IF spi_if();

    initial begin
        spi_if.clk <= 0;
    end

    always #5 spi_if.clk <= ~spi_if.clk;

    spi_master dut (
        spi_if.clk,
        spi_if.newd,
        spi_if.rst,
        spi_if.din,
        spi_if.sclk,
        spi_if.cs,
        spi_if.mosi
    );

    Environment env;

    initial begin
        env = new(spi_if);
        env.run();
    end
endmodule