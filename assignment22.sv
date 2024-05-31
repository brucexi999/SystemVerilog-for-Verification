module tb;

event evt;
int count = 0;

task Task1();
  forever begin
    #20;
    $display("Task 1 triggered.");
    -> evt;
  end
endtask

task Task2();
  forever begin
    #40;
    $display("Task 2 triggered.");
    -> evt;
  end
endtask

task counter();
  forever begin
    //wait(evt.triggered); // Wait for event
    @(evt);
    count++;
  end
endtask

initial begin
  fork
    Task1();
    Task2();
    counter();
  join
end

initial begin
    #200;
    $display("Counter = %0d", count);
    $finish();
end
endmodule