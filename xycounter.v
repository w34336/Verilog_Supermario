
module xcounter(
	input clk,
	input resetn,
	input enable,
	input updown,
	output reg [7:0] q
	);
	
	always @ (posedge clk, negedge resetn)
	begin
		if (resetn == 1'b0)
			begin
				q <= 0;
			end
		else if (enable == 1'b1)
			begin
				if (updown == 1'b1 & q < 8'd155)
					q <= q + 1;
				else if (updown == 1'b0 & q > 8'd0)
					q <= q - 1;
			end
	end

endmodule


module ycounter(
	input clk,
	input resetn,
	input enable,
	input updown,
	output reg [7:0] q
	);
	
	always @(posedge clk, negedge resetn)
	begin
		if (resetn == 1'b0)
			begin
				q <= 0;
			end
		else if (enable == 1'b1)
			begin
				if (updown == 1'b1 & q < 8'd115)
					q <= q + 1;
				else if (updown == 1'b0 & q > 8'd0)
					q <= q - 1;
			end
	end

endmodule

module delaycounter(
	input clk,
	input resetn,
	input enable,
	output reg [19:0] q
	);
	
	always @(posedge clk, negedge resetn)
	begin
		if (resetn == 1'b0)
			begin
				q <= 0;
			end
		else if (enable == 1'b1)
			begin
				if (q == 20'd9) // 20'b11001011011100110101 for 60fps
					q <= 0;
				else
					q <= q + 1;
			end
		else
			q <= q;
	end
	
endmodule

module speedcounter(
	input enable,
	input clk,
	input resetn,
	output reg [4:0] q);
	always @(posedge clk, negedge resetn)
	begin
		if (resetn == 1'b0)
			begin
				q <= 0;
			end
		else if (enable == 1'b1)
			begin
				if (q == 5'd4) //1pt per 5fps
					q <= 0;
				else
					q <= q + 1;
			end
		else
			q <= q;
	end

endmodule
	