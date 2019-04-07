//module to generate test data
module tdg(
  input wire clk,
  input wire reset,
  output reg [16:0] ad,
  output reg [1:0] cs,
  output reg [2:0] cycle
);
parameter admax = 131071;// number of cells: 0-131071;
always@(posedge clk)
  begin
    if(!reset)
	  begin
	    cs=2'b01;
		cycle=3'b000;
		ad=17'h00000;
	  end
	else if(!((cs==2'b10)&&(ad==admax)&&(cycle==3'b101)))
	  begin
		if(ad==admax)
		  begin
		    if(cycle<5)
			  begin
			    ad=0;
				cycle=cycle+1;
			  end
			if(cycle==5)
			  begin
			    ad=0;
				cycle=0;
				cs=10;
			  end
		  end
		else
	      ad=ad+1; //注意这里的顺序，不能让admax+1出现，出来就成毛刺了
	  end
  end
endmodule

//module to implement March-c
module march(
  input wire [16:0] ad,
  input wire [2:0] cycle,
  input wire [1:0] cs,
  output reg oe,
  output reg [1:0] we,
  output reg [16:0] a,
  output reg [7:0] data,//输出给RDE
  inout [15:0] io 
);
parameter admax = 131071;// number of cells: 0-131071;
reg [15:0] io_t;
assign io[15:8]=(cs[1]&&we[1])?io_t[15:8]:8'bzzzzzzzz; 
assign io[7:0]=(cs[0]&&we[0])?io_t[7:0]:8'bzzzzzzzz; 
always@(cycle or ad or cs)
  begin
    case(cycle)
	  3'b000: begin
	            oe=0; we=2'b11; a=ad;
				case(cs)
				  2'b01: begin io_t[7:0]=8'h00; end
				  2'b10: begin io_t[15:8]=8'h00; end
				  default: begin end
				endcase
	          end
	  3'b001: begin
	            oe=1; we=2'b00; a=ad;
				case(cs)
				  2'b01: begin  data[7:0]=io[7:0]; end
				  2'b10: begin  data[7:0]=io[15:8]; end
				  default: begin end
				endcase
				oe=0; we=2'b11; a=ad;
				case(cs)
				  2'b01: begin  io_t[7:0]=8'hff; end
				  2'b10: begin  io_t[15:8]=8'hff; end
				  default: begin end
				endcase
	          end
	  3'b010: begin
	            oe=1; we=2'b00; a=ad;
				case(cs)
				  2'b01: begin  data[7:0]=io[7:0]; end
				  2'b10: begin data[7:0]=io[15:8]; end
				  default: begin end
				endcase
				oe=0; we=2'b11;
				case(cs)
				  2'b01: begin io_t[7:0]=8'h00; end
				  2'b10: begin io_t[15:8]=8'h00; end
				  default: begin end
				endcase
	          end
	  3'b011: begin
	            oe=1; we=2'b00; a = admax-ad;
				case(cs)
				  2'b01: begin data[7:0]=io[7:0]; end
				  2'b10: begin data[7:0]=io[15:8]; end
				  default: begin end
				endcase
				oe=0; we=2'b11; 
				case(cs)
				  2'b01: begin  io_t[7:0]=8'hff; end
				  2'b10: begin  io_t[15:8]=8'hff; end
				  default: begin end
				endcase
	          end
	  3'b100: begin
	            oe=1; we=2'b00; a = admax-ad;
				case(cs)
				  2'b01: begin  data[7:0]=io[7:0]; end
				  2'b10: begin  data[7:0]=io[15:8]; end
				  default: begin end
				endcase
				oe=0; we=2'b11;
				case(cs)
				  2'b01: begin  io_t[7:0]=8'h00; end
				  2'b10: begin  io_t[15:8]=8'h00; end
				  default: begin end
				endcase
	          end
	  3'b101: begin
	            oe=1; we=2'b00; a=ad;
				case(cs)
				  2'b01: begin data[7:0]=io[7:0]; end
				  2'b10: begin  data[7:0]=io[15:8]; end
				  default: begin end
				endcase
	          end
	  default: begin end
	endcase
  end  
endmodule

//module to generate result
module rde(
  input wire reset,
  input wire [16:0] a,//connect to module march
  input wire [2:0] cycle,//connect to module tdg
  input wire [1:0] cs,//connect to module tdg
  input wire [7:0] data,//connect to module tdg
  output reg [7:0] addr,//memory to record errors   这个地址怎么初始化啊？？？？？？
  output reg [25:0] record //cs[2],ad[17],cycle[3],ec[4];
);
reg [7:0] error;   
always@(a or cycle or cs or reset)
  begin
    if(!reset)
	  begin
	    addr[7:0]=8'h00;
	  end
	else
	  begin
		case(cycle)
		  3'b001,
		  3'b011,
		  3'b101: begin
					error[7:0]=data[7:0]^8'h00;
					if(error!=8'h00)
					  begin
						addr=addr+1;
						record[25:4]={cs[1:0],a[16:0],cycle[2:0]};
						case(error)
						  //single bit error
						  8'h01: record[3:0]=4'b0000;
						  8'h02: record[3:0]=4'b0001;
						  8'h04: record[3:0]=4'b0010;
						  8'h08: record[3:0]=4'b0011;
						  8'h10: record[3:0]=4'b0100;
						  8'h20: record[3:0]=4'b0101;
						  8'h40: record[3:0]=4'b0110;
						  8'h80: record[3:0]=4'b0111;
						  //multi bit error
						  default: begin 
									 if(error[0]==1)
									   begin record[3:0]=4'b1000; end
									 else if(error[1:0]==2'b10)
									   begin record[3:0]=4'b1001; end
									 else if(error[2:0]==3'b100)
									   begin record[3:0]=4'b1010; end
									 else if(error[3:0]==4'b1000)
									   begin record[3:0]=4'b1011; end
									 else if(error[4:0]==5'b10000)
									   begin record[3:0]=4'b1100; end
									 else if(error[5:0]==2'b100000)
									   begin record[3:0]=4'b1101; end
									 else if(error[6:0]==2'b1000000)
									   begin record[3:0]=4'b1110; end
								   end
						endcase
					  end
				  end	  
		  3'b010,
		  3'b100: begin
					error[7:0]=data[7:0]^8'hff;
					if(error!=8'h00)
					  begin
						addr=addr+1;
						record[25:4]={cs[1:0],a[16:0],cycle[2:0]};
						case(error)
						  //single bit error
						  8'h01: record[3:0]=4'b0000;
						  8'h02: record[3:0]=4'b0001;
						  8'h04: record[3:0]=4'b0010;
						  8'h08: record[3:0]=4'b0011;
						  8'h10: record[3:0]=4'b0100;
						  8'h20: record[3:0]=4'b0101;
						  8'h40: record[3:0]=4'b0110;
						  8'h80: record[3:0]=4'b0111;
						  //multi bit error
						  default: begin 
									 if(error[0]==1)
									   begin record[3:0]=4'b1000; end
									 else if(error[1:0]==2'b10)
									   begin record[3:0]=4'b1001; end
									 else if(error[2:0]==3'b100)
									   begin record[3:0]=4'b1010; end
									 else if(error[3:0]==4'b1000)
									   begin record[3:0]=4'b1011; end
									 else if(error[4:0]==5'b10000)
									   begin record[3:0]=4'b1100; end
									 else if(error[5:0]==2'b100000)
									   begin record[3:0]=4'b1101; end
									 else if(error[6:0]==2'b1000000)
									   begin record[3:0]=4'b1110; end
								   end
						endcase
					  end
				  end
		  default: begin end
		endcase
    end
  end
endmodule 










