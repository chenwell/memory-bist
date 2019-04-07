module mem(
  input wire [16:0] a,
  input wire oe,
  input wire [1:0] cs,
  input wire [1:0] we,
  inout [15:0] io
);
reg [15:0] io_reg;
assign io[15:8]=(cs[1]&&oe)?io_reg[15:8]:8'bzzzzzzzz;
assign io[7:0]=(cs[0]&&oe)?io_reg[7:0]:8'bzzzzzzzz;

reg [7:0] bank0[3:0];//131071
reg [7:0] bank1[7:0];//131071

always@(a or oe or we or cs or io)
  begin
    case(cs) //choose work mode
	   2'b01: begin//256*8 low 128
	            if(oe&&(!we[0]))
			        io_reg[7:0]=bank0[a];
			      if(we[0]&&(!oe))
			        bank0[a]=io[7:0];
	          end
	   2'b10: begin//256*8 high 128
	            if(oe&&(!we[1]))
			        io_reg[15:8]=bank1[a];
			      if(we[1]&&(!oe))
			        bank1[a]=io[15:8];
	          end
	   2'b11: begin//128*16
	            if(oe&&(!we[1])&&(!we[0]))
			        io_reg[15:0]={bank1[a],bank0[a]};
			      if((we[1:0]==2'b11)&&(!oe))
			        begin
			          bank0[a]=io[7:0];
				       bank1[a]=io[15:8];
				     end
	          end
	   default: begin end
	 endcase
  end
  
endmodule 