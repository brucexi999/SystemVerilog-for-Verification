/*
Modify the Testbench environment used for the verification of UART to test the operation of 
the UART transmitter with PARITY and STOP BIT. Add logic in scoreboard to verify that the data 
on TX pin matches the random 8-bit data applied on the DIN bus by the user. Parity is always enabled and odd type.
*/

module uarttx
#(
parameter clk_freq = 1000000,
parameter baud_rate = 9600
)
(
input clk,rst,
input newd,
input [7:0] tx_data,
output reg tx,
output reg donetx
);
 
  localparam clkcount = (clk_freq/baud_rate); ///x
  
integer count = 0;
integer counts = 0;
 
reg uclk = 0;
  
enum bit[1:0] {idle = 2'b00, start = 2'b01, transfer = 2'b10, send_parity = 2'b11} state;
 
 ///////////uart_clock_gen
  always@(posedge clk)
    begin
      if(count < clkcount/2)
        count <= count + 1;
      else begin
        count <= 0;
        uclk <= ~uclk;
      end 
    end
  
  
  reg [7:0] din;
  reg parity = 0; /// store odd parity
  ////////////////////Reset decoder
  
  
  always@(posedge uclk)
    begin
      if(rst) 
      begin
        state <= idle;
      end
     else
     begin
     case(state)
     
     //////detect new data and start transmission
       idle:
         begin
           counts <= 0;
           tx <= 1'b1;
           donetx <= 1'b0;
           
           if(newd) 
           begin
             state <= transfer;
             din <= tx_data;
             tx <= 1'b0; 
             parity <= ~^tx_data; 
           end
           else
             state <= idle;       
         end
       
 
      ///// wait till transmission of data is completed
      transfer: begin 
          
        if(counts <= 7) 
        begin
           counts <= counts + 1;
           tx     <= din[counts];
           state  <= transfer;
        end
        else 
        begin
           counts <= 0;
           tx     <= parity;
           state  <= send_parity;
        end
      end
      
      ////send parity and move to idle
      send_parity: 
      begin
      tx     <= 1'b1;
      state  <= idle;
      donetx <= 1'b1;
      end
      
      default : state <= idle;
      
    endcase
  end
end
 
endmodule

interface UART_IF;
    logic clk, rst, newd, tx, donetx, uclk;
    logic [7:0] tx_data;
endinterface

class Transaction;
    randc bit [7:0] tx_data;
    bit newd, tx, donetx;

    function Transaction copy();
        copy = new();
        copy.tx_data = this.tx_data;
        copy.newd = this.newd;
        copy.tx = this.tx;
        copy.donetx = this.donetx;
    endfunction
endclass

class Generator;
    Transaction trans;
    mailbox #(Transaction) mbx_to_dri;
    mailbox #(bit [9:0]) mbx_to_sco;
    event send_next_stimulus;
    bit parity = 0;

    function new(mailbox #(Transaction) mbx_to_dri, mailbox #(bit [9:0]) mbx_to_sco);
        this.mbx_to_dri = mbx_to_dri;
        this.mbx_to_sco = mbx_to_sco;
        trans = new();
    endfunction

    task run();
        for (int i = 0; i<10; i++) begin
            trans.randomize();
            parity = ~^trans.tx_data;
            mbx_to_dri.put(trans.copy());
            mbx_to_sco.put({1'b1, parity, trans.tx_data});
            @(send_next_stimulus);
        end
    endtask

endclass

class Driver;
    Transaction trans;
    mailbox #(Transaction) mbx;
    virtual UART_IF itfc;

    function new(mailbox #(Transaction) mbx);
        this.mbx = mbx;
    endfunction

    task reset();
        itfc.rst <= 1;
        repeat (5) @(posedge itfc.clk);
        itfc.rst <= 0;
        repeat (5) @(posedge itfc.clk);
        $display("[Driver] Reset done.");
    endtask

    task run();
        forever begin
            mbx.get(trans);
            @(posedge itfc.uclk);
            itfc.newd <= 1;
            itfc.tx_data <= trans.tx_data;
            @(posedge itfc.uclk);
            itfc.newd <= 0;
            $display("[Driver] Data %b sent to DUT", {1'b1, ~^trans.tx_data, trans.tx_data});
            wait(itfc.donetx == 1);
        end
    endtask
endclass

class Monitor;
    mailbox #(bit [9:0]) mbx;
    virtual UART_IF itfc;
    bit [9:0] received_data;

    function new(mailbox #(bit [9:0]) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        forever begin
            int i = 0;
            @(posedge itfc.uclk);
            wait(itfc.newd == 1);
            repeat(2) @(posedge itfc.uclk);
            while (itfc.donetx != 1) begin
                @(posedge itfc.uclk);
                received_data[i] = itfc.tx;
                i++;
            end
            @(posedge itfc.uclk);
            received_data[i] = itfc.tx;
            $display("[Monitor] Data received from DUT %b", received_data);
            mbx.put(received_data);
        end
    endtask

endclass

class Scoreboard;
    mailbox #(bit [9:0]) mbx_from_gen;
    mailbox #(bit [9:0]) mbx_from_mon;
    event send_next_stimulus;
    bit [9:0] data_from_gen, data_from_mon;

    function new(mailbox #(bit [9:0]) mbx_from_gen, mailbox #(bit [9:0]) mbx_from_mon);
        this.mbx_from_gen = mbx_from_gen;
        this.mbx_from_mon = mbx_from_mon;
    endfunction

    task run();
        forever begin
            mbx_from_gen.get(data_from_gen);
            mbx_from_mon.get(data_from_mon);
            $display("[Scoreboard] Data from Generator %b, data from Monitor %b", data_from_gen, data_from_mon);
            assert (data_from_gen == data_from_mon) else $error("Data mismatched!");
            $display("------------------------------------------------");
            ->send_next_stimulus;
        end
    endtask

endclass

class Environment;
    Generator gen;
    Driver dri;
    Monitor mon;
    Scoreboard sco;
    event send_next_stimulus;

    mailbox #(Transaction) mbx_gen_dri;
    mailbox #(bit [9:0]) mbx_gen_sco;
    mailbox #(bit [9:0]) mbx_mon_sco;

    function new(virtual UART_IF itfc);
        mbx_gen_dri = new();
        mbx_gen_sco = new();
        mbx_mon_sco = new();
        gen = new(mbx_gen_dri, mbx_gen_sco);
        dri = new(mbx_gen_dri);
        mon = new(mbx_mon_sco);
        sco = new(mbx_gen_sco, mbx_mon_sco);
        dri.itfc = itfc;
        mon.itfc = itfc;
        gen.send_next_stimulus = send_next_stimulus;
        sco.send_next_stimulus = send_next_stimulus;
    endfunction

    task run();
        dri.reset();
        fork
            gen.run();
            dri.run();
            mon.run();
            sco.run();
        join_any
        $finish();
    endtask

endclass



module uart_tb;

    Environment env;
    UART_IF itfc();
    
    uarttx #(1000000, 9600) dut (itfc.clk, itfc.rst, itfc.newd, itfc.tx_data, itfc.tx, itfc.donetx);
    assign itfc.uclk = dut.uclk;

    initial begin
        itfc.clk <= 0;
    end

    always #5 itfc.clk <= ~itfc.clk;

    initial begin
        env = new(itfc);
        env.run();
    end

endmodule