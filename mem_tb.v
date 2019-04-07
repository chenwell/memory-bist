`include "mem.v"
module mem_tb;
reg [16:0] a;
reg oe;
reg [1:0] cs;
reg [1:0] we;
wire [15:0] io;
reg [15:0] io_t;

assign io[15:8]=(cs[1]&&we[1])?io_t[15:8]:8'bzzzzzzzz; 
assign io[7:0]=(cs[0]&&we[0])?io_t[7:0]:8'bzzzzzzzz; 
mem mem1(a,oe,cs,we,io);
   
initial
 begin
#10     oe=0; cs=2'b11; we=2'b11; a[16:0]=17'h00001; io_t=16'h0113;	 
#50  oe=0; cs=2'b01; we=2'b01; a[16:0]=17'h00000; io_t=16'h1031;
#50  oe=0; cs=2'b10; we=2'b10; a[16:0]=17'h00000; io_t=16'h2104;
#50  oe=1; cs=2'b11; we=0; a[16:0]=17'h00000;
#50  oe=1; cs=2'b01; we=0; a[16:0]=17'h00001;
#50  oe=1; cs=2'b10; we=0; a[16:0]=17'h00001;

end

initial $monitor($time,,,"a=%d oe=%b cs=%b we=%b io=%h", a,oe,cs,we,io);

endmodule 