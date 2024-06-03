class myClass;
    bit [7:0] a, b, c;

    function new(input bit [7:0] a, b, c);
    this.a = a;
    this.b = b;
    this.c = c;
    endfunction
endclass

module tb;

myClass myObject;

initial begin
    myObject = new(2, 4, 56);
    $display("a: %0d, b: %0d, c: %0d", myObject.a, myObject.b, myObject.c);
end
endmodule