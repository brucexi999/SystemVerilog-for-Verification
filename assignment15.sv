class myClass;
    bit [7:0] a, b, c;

    function new(input bit [7:0] a, b, c);
    this.a = a;
    this.b = b;
    this.c = c;
    endfunction

    task addPrint(output int sum);
        sum = a + b + c;
        $display("a = %0d, b = %0d, c = %0d, a + b + c = %0d", a, b, c, sum);
    endtask
endclass

module tb;

myClass myObject;
int sum;

initial begin
    myObject = new(1, 2, 4);
    myObject.addPrint(sum);
end
endmodule