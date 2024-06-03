module tb;
    function automatic void mul8 (ref int arr [32]);
        for(int i=0; i < 32; i++) begin
            arr[i] = 8*i;
        end
    endfunction

  int arr [32];

initial begin
    mul8(arr);
    for (int i = 0; i < 32; i++) begin
        $display("arr[%0d]: %0d", i, arr[i]);
    end
end
endmodule
