//module supermario
//	(
//		CLOCK_50,						//	On Board 50 MHz
//		// Your inputs and outputs here
//        KEY,
//        SW,
//		  LEDR,
//		// The ports below are for the VGA output.  Do not change.
//		VGA_CLK,   						//	VGA Clock
//		VGA_HS,							//	VGA H_SYNC
//		VGA_VS,							//	VGA V_SYNC
//		VGA_BLANK_N,						//	VGA BLANK
//		VGA_SYNC_N,						//	VGA SYNC
//		VGA_R,   						//	VGA Red[9:0]
//		VGA_G,	 						//	VGA Green[9:0]
//		VGA_B   						//	VGA Blue[9:0]
//	);
//	input CLOCK_50;
//	input [9:0] SW;
//	input [3:0] KEY;
//	output [9:0] LEDR;
//	output			VGA_CLK;   				//	VGA Clock
//	output			VGA_HS;					//	VGA H_SYNC
//	output			VGA_VS;					//	VGA V_SYNC
//	output			VGA_BLANK_N;				//	VGA BLANK
//	output			VGA_SYNC_N;				//	VGA SYNC
//	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
//	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
//	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
//	
//	wire left = ~KEY[3];
//	wire right = ~KEY[1];
//	wire jump = ~KEY[2];
//	wire go = ~KEY[0];
//	wire resetn = SW[9];
//	
//	wire [2:0] colour;
//	wire [7:0] x;
//	wire [6:0] y;
//	wire writeEn;
//	
//	vga_adapter VGA(
//			.resetn(resetn),
//			.clock(CLOCK_50),
//			.colour(colour_in),
//			.x(x_in),
//			.y(y_in),
//			.plot(writeEn),
//			/* Signals for the DAC to drive the monitor. */
//			.VGA_R(VGA_R),
//			.VGA_G(VGA_G),
//			.VGA_B(VGA_B),
//			.VGA_HS(VGA_HS),
//			.VGA_VS(VGA_VS),
//			.VGA_BLANK(VGA_BLANK_N),
//			.VGA_SYNC(VGA_SYNC_N),
//			.VGA_CLK(VGA_CLK));
//		defparam VGA.RESOLUTION = "160x120";
//		defparam VGA.MONOCHROME = "FALSE";
//		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
//		defparam VGA.BACKGROUND_IMAGE = "black.mif";
//		
//	wire moveleft, moveright;
//	wire [2:0] colour_in;
////	wire [7:0] x_in;
//	wire [6:0] y_in;
//	//control and datapath to be initiated here;
//	control c0(
//		.resetn(resetn),
//		.go(go),
//		.clk(CLOCK_50),
//		.left(left),
//		.right(right),
//		.jump(jump),
//		.left_en(moveleft),
//		.right_en(moveright),
//		.plot(writeEn)
//		);
//	
//	datapath d0(
//		.clk(CLOCK_50),
//		.resetn(resetn),
//		.left_en(moveleft),
//		.right_en(moveright),
//		.speedcounter(LEDR[4:0]),
//		.move_counter_x(LEDR[9:5]),
//		.yout(y_in[6:0]),
//		.colour(colour_in[2:0])
//		);
//		
//		
//endmodule

module control(
	input resetn,
	input go,
	input clk,
	input left,
	input right,
	input jump,
	output reg left_en, right_en, plot);
	
	reg [3:0] current_state, next_state;
	
	localparam SPAWN_CHAR         = 4'b0000,
				  MOVE_LEFT				= 4'b0001,
				  MOVE_RIGHT			= 4'b0010,
				  STAY					= 4'b0011,
				  AIRBRONE			   = 4'b0100,
				  INITIALIZE         = 4'b0101;
				  
				  
				  
	always@(*)
	begin: state_table
			case (current_state)
				INITIALIZE: next_state = go ? STAY : INITIALIZE;
				STAY:			next_state = STAY;
//				MOVE_LEFT: next_state = left ? MOVE_LEFT : STAY;
//				MOVE_RIGHT: next_state = right ? MOVE_RIGHT : STAY;
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
		left_en = 1'b0;
		right_en = 1'b0;
		plot = 1'b0;
		
		case (current_state)
			INITIALIZE: begin
				left_en = 1'b0;
				right_en = 1'b0;
				plot = 1'b0;
			end
			STAY: begin
				left_en = left;
				right_en = right;
				plot = 1'b1;
			end
//			MOVE_LEFT: begin
//				left_en = 1'b1;
//				right_en = 1'b0;
//				plot = 1'b1;
//			end
//			MOVE_RIGHT: begin
//				left_en = 1'b0;
//				right_en = 1'b1;
//				plot = 1'b1;
//			end
			default: begin
				left_en = 1'b0;
				right_en = 1'b0;
				plot = 1'b0;
			end
		endcase
	end
endmodule
				
module datapath(
	input clk,
	input resetn,
	input left_en,
	input right_en,
	output reg [4:0] speedcounter,
	output reg [4:0] move_counter_x,
	output reg [6:0] yout,
	output reg [2:0] colour
	);
	reg [7:0] xout;
	reg [4:0] sqcounter;
	reg [7:0] x, y;
//	reg [7:0] speedcounter;
	reg [29:0] framecounter;
//	reg [7:0] move_counter_x;
	localparam SPAWN_HEIGHT = 7'd80;   //change the height of Mario spawn point here
	
	
	always @(posedge clk) begin
		if (!resetn) begin
			x <= 7'd0;
			y <= SPAWN_HEIGHT;
		end
	end
		
	
	always @(posedge clk) begin
		if (!resetn) begin
			sqcounter <= 5'd0;
		end
		else begin
			if (sqcounter == 5'd16) begin
				sqcounter <= 5'd0;
			end
			if (framecounter == 29'd100) begin
				sqcounter <= 5'd0;
			end
			else
				sqcounter <= sqcounter + 1;
		end
	end
	
	always @(posedge clk) begin
		if (!resetn) begin
			framecounter <= 29'd0;
			colour <= 3'd0;
			speedcounter <= 8'd0;
			move_counter_x <= 8'd0;
		end
		else begin
			if (framecounter == 29'd100) begin
				framecounter <= 29'd0;
				speedcounter <= speedcounter + 1;
				colour <= 3'd0; //black to erase
//				if (speedcounter == 8'd10) begin
//					speedcounter <= 0;
//					if (move_counter_x == 8'd0) begin
//						if (right_en)
//							move_counter_x <= move_counter_x + 1;
//						else
//							move_counter_x <= move_counter_x;
//					end
//					if (move_counter_x == 8'b10011011) begin//set max x for square be 155
//						if (left_en)
//							move_counter_x <= move_counter_x - 1;
//						else
//							move_counter_x <= move_counter_x;
//					end
//					else begin
//						if (left_en)
//							move_counter_x <= move_counter_x - 1;
//						if (right_en)
//							move_counter_x <= move_counter_x + 1;
//						else
//							move_counter_x <= move_counter_x;
//					end
//				end
			end
			else begin
				framecounter <= framecounter + 1;
				if (sqcounter == 5'd16) begin
					colour <= 3'd1;
				end
			end
		end
	end
	
	
//	always @(negedge resetn) begin
//		if (!resetn) begin
//			move_counter_x <= 8'd0;
//		end
//		else begin
//			if (speedcounter == 8'd10) begin//change this line to change the speed of obj.
//				if (move_counter_x == 7'd0) begin
//					if (right_en)
//						move_counter_x <= move_counter_x + 1;
//					else
//						move_counter_x <= move_counter_x;
//				end
//				if (move_counter_x == 8'b10011011) begin//set max x for square be 155
//					if (left_en)
//						move_counter_x <= move_counter_x - 1;
//					else
//						move_counter_x <= move_counter_x;
//				end
//				else begin
//					if (left_en)
//						move_counter_x <= move_counter_x - 1;
//					if (right_en)
//						move_counter_x <= move_counter_x + 1;
//					else
//						move_counter_x <= move_counter_x;
//				end
//			end
//			else
//				move_counter_x <= move_counter_x;
//		end
//	end
	
	always @(posedge clk) begin
		xout <= x + sqcounter[1:0] + move_counter_x;
		yout <= y + sqcounter[3:2];
	end
endmodule

