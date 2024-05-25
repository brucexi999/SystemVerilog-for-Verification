class generator;
  
  bit [3:0] a = 5,b =7;
  bit wr = 1;
  bit en = 1;
  bit [4:0] s = 12;
  
  function void display();
    $display("a:%0d b:%0d wr:%0b en:%0b s:%0d", a,b,wr,en,s);
  endfunction

  function generator copy;
    copy = new;
    copy.a = a;
    copy.b = b;
    copy.wr = wr;
    copy.en = en;
    copy.s = s;
  endfunction
 
endclass

class myClass;

generator G;

function new;
    G = new;
endfunction

function myClass copy;
    copy = new;
    copy.G = G.copy;
endfunction
endclass

module tb;
    myClass myHandle0, myHandle1;
    initial begin
        myHandle0 = new;
        myHandle0.G.wr = 0;
        myHandle0.G.display();
        myHandle1 = myHandle0.copy;
        myHandle1.G.wr = 1;
        myHandle1.G.display();
        myHandle0.G.display();
    end

endmodule