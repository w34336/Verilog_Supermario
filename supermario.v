module supermario
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);
	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire left = ~KEY[3];
	wire right = ~KEY[1];
	wire go = ~KEY[0];
	
	wire [2:0] colour;
	wire [7:0] x_in;
	wire [6:0] y_in;
	wire writeEn;
	
	vga_adapter VGA(
			.resetn(SW[9]),
			.clock(CLOCK_50),
			.colour(colour_in),
			.x(x_in),
			.y(y_in),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
	wire [2:0] colour_in;
	wire [7:0] x_q;
	wire [6:0] y_q;
	wire [19:0] delay_q;
	//control and datapath to be initiated here;
	control c0(
		.resetn(SW[9]),
		.go(go),
		.clk(CLOCK_50),
		.left(left),
		.right(right),
		.x_q(x_q),
		.y_q(y_q),
		.delay_q(delay_q),
		.plot(writeEn)
		);
	
	datapath d0(
		.x(x_q),
		.y(y_q),
		.delay_q(delay_q),
		.clk(CLOCK_50),
		.resetn(SW[9]),
		.colourout(colour_in[2:0]),
		.xout(x_in[7:0]),
		.yout(y_in[6:0])
		);
		
		
endmodule

module control(
	input resetn,
	input go,
	input clk,
	input left,
	input right,
	output [7:0] x_q,
	output [6:0] y_q,
	output [19:0] delay_q,
	output reg plot);
	
	reg x_en, y_en, x_ud, y_ud, d_en;
	wire [4:0] s_q;
	
	reg [3:0] current_state, next_state;
	
	localparam INITIALIZE			= 4'b0000,
				  STATIC		         = 4'b0001,
				  MOVE_LEFT				= 4'b0010,
				  MOVE_RIGHT			= 4'b0011;
				  
				  
	always @(*)
	begin: state_table
			case (current_state)
				INITIALIZE:	next_state = go ? STATIC : INITIALIZE;
				STATIC:								if (right)
															next_state = MOVE_RIGHT;
														else if (left)
															next_state = MOVE_LEFT;
														else
															next_state = STATIC;
				MOVE_LEFT: 	next_state = left ? MOVE_LEFT : STATIC;
				MOVE_RIGHT: next_state = right ? MOVE_RIGHT : STATIC;
			default: next_state = INITIALIZE;
		endcase
	end
				

	 always @(posedge clk)
	 begin: state_FFS
		  if(!resetn)
				current_state <= INITIALIZE;
		  else
				current_state <= next_state;
	 end
	
	always @(*)
	begin: enable_signals
		x_en = 1'b0;
		y_en = 1'b0;
		x_ud = 1'b0;
		y_ud = 1'b0;
		plot = 1'b0;
		d_en = 1'b0;
		
		case (current_state)
			INITIALIZE: begin
				x_en = 1'b0;
				y_en = 1'b0;
				x_ud = 1'b0;
				y_ud = 1'b0;
				plot = 1'b0;
				d_en = 1'b0;
			end
			STATIC: begin
				x_en = 1'b0;
				y_en = 1'b0;
				x_ud = 1'b0;
				y_ud = 1'b0;
				plot = 1'b1;
				d_en = 1'b1;
			end
			MOVE_LEFT: begin
				x_en = 1'b1;
				y_en = 1'b0;
				x_ud = 1'b0;
				y_ud = 1'b0;
				plot = 1'b1;
				d_en = 1'b1;
			end
			MOVE_RIGHT: begin
				x_en = 1'b1;
				y_en = 1'b0;
				x_ud = 1'b1;
				y_ud = 1'b0;
				plot = 1'b1;
				d_en = 1'b1;
			end
			default: begin
				x_en = 1'b0;
				y_en = 1'b0;
				x_ud = 1'b0;
				y_ud = 1'b0;
				plot = 1'b0;
				d_en = 1'b0;
			end
		endcase
	end
	
	wire x_den, y_den;
	reg x_fen, y_fen;	
	
	always @(posedge clk) begin
		if (x_den & x_en & delay_q == 20'd0)
			x_fen <= 1'b1;
		else
			x_fen <= 1'b0;
	end

	always @(posedge clk) begin
		if (y_den & y_en & delay_q == 20'd0)
			y_fen <= 1'b1;
		else
			y_fen <= 1'b0;
	end
			
	
	assign x_den = (s_q == 5'd0) ? 1 : 0;
	assign y_den = (s_q == 5'd0) ? 1 : 0;
	
	xcounter x0(clk, resetn, x_fen, x_ud, x_q);
	ycounter y0(clk, resetn, y_fen, y_ud, y_q);
	delaycounter d0(clk, resetn, d_en, delay_q);
	
	wire s_en;
	assign s_en = (delay_q == 20'd0) ? 1 : 0;
	speedcounter s0(s_en, clk, resetn, s_q);
	
endmodule

module datapath(
	input [7:0] x,
	input [6:0] y,
	input [19:0] delay_q,
	input clk,
	input resetn,
	output reg [2:0] colourout,
	output [7:0] xout,
	output [6:0] yout);
	reg [3:0] count;
	
	always @(posedge clk) begin
		if (!resetn) begin
			count <= 4'd0;
		end
		else
			count <= count + 1;
	end
			
	always @(posedge clk) begin
		if (!resetn) begin
			colourout <= 3'd0;
		end
		else begin
			if (delay_q < 20'd830000) begin
				colourout <= 3'd0;
			end
			else begin
				colourout <= 3'd1;
			end
		end
	end

	assign xout = x + count[1:0];
	assign yout = y + count[3:2];
	
endmodule

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
	output reg [6:0] q
	);
	
	always @(posedge clk, negedge resetn)
	begin
		if (resetn == 1'b0)
			begin
				q <= 7'd60;
			end
		else if (enable == 1'b1)
			begin
				if (updown == 1'b1 & q < 7'd115)
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
				if (q == 20'b11001011011100110101) // 20'b11001011011100110101 for 60fps
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
				if (q == 5'b00100) //1pt per 5fps
					q <= 0;
				else
					q <= q + 1;
			end
		else
			q <= q;
	end

endmodule
