class Generator;
  
  rand bit [3:0] addr;
  rand bit wr;
  
  constraint data {
    if (wr == 1) {
        addr inside {[0:7]};
    } else {
        addr inside {[8:15]};
    }
  }
  
  task display_data();
    $display("wr = %0d, addr = %0d", wr, addr);
  endtask
  
endclass
 
module tb;

Generator generator;

initial begin
    generator.new();
    for (int i=0; i<20; i++) begin
        generator.randomize();
        generator.display_data();
    end
end

endmodule