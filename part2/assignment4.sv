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






module tb(  );
 
reg clk = 0, rst = 0, newd = 0;
reg [11:0] din = 0;
wire sclk, cs, mosi;
  reg [11:0] mosi_out;
 
always #10 clk = ~clk;
 
spi_master dut (clk, newd,rst, din, sclk, cs, mosi);
 
initial 
begin
rst = 1;
repeat(5) @(posedge clk);
rst = 0;
 
newd = 1;
din = $urandom;
  $display("%0d", din); 
  for(int i = 0; i <= 11; i++)
    begin
    @(negedge dut.sclk);
    mosi_out = {mosi, mosi_out[11:1]};
    $display("%0d", mosi_out);  
    end
  
  
end
 
 
 
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    #2500;
    $stop;
  end
 
endmodule