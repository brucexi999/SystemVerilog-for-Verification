class Generator;
  
  rand bit rst;  // 30% low
  rand bit wr;  // 50% low
  
  constraint data {
    rst dist {0 :/ 3, 1 :/ 7};
    wr dist {0 :/ 5, 1 :/ 5};
  }
  
  task display_data();
    $display("rst = %0d, wr = %0d", rst, wr);
  endtask
  
endclass
 
module tb;
Generator generator;

initial begin
    generator = new();
    for(int i = 0; i<20; i++) begin
        generator.randomize();
        generator.display_data();
    end
end

endmodule