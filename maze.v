`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: UPB
// Engineer: Cosmin Sturzu
// 
// Create Date:    01:27:27 12/02/2021 
// Design Name: 
// Module Name:    maze 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module maze #(parameter maze_width = 6)(
	input 		          			clk,
	input 	  [maze_width - 1:0] starting_col, starting_row, 	// indicii punctului de start
	input  			  					maze_in, 			// ofera informa?ii despre punctul de coordonate [row, col]
	output reg [maze_width - 1:0] row, col,	 		// selecteaza un rând si o coloana din labirint
	output reg 			  				maze_oe,			// output enable (activeaza citirea din labirint la rândul ?i coloana date) - semnal sincron	
	output reg			 		 		maze_we, 			// write enable (activeaza scrierea în labirint la rândul ?i coloana date) - semnal sincron
	output reg			  				done);		 	// ie?irea din labirint a fost gasita; semnalul ramane activ 


`define start_position				0
`define choose_first_direction	1
`define check_start_free_path    2
`define go_back_to_start			3
`define check_free_path 			4
`define choose_direction 			5
`define from_north					6
`define from_south					7
`define from_west						8 
`define from_est						9
`define go_back						10
`define exit 							11


reg [3:0] state, next_state = 0;

reg [1:0] direction;
reg [1:0] direction_north;
reg [1:0] direction_south;
reg [1:0] direction_west;
reg [1:0] direction_est;

reg [1:0] last_direction; //retine ultima directie de deplasare valida


// Secvential
always @(posedge clk) begin
	if(done == 0)
		state <= next_state;
end

// Combinational
always @(*) begin
	maze_oe = 0;
	maze_we = 0;
	done = 0;
	
	case(state)
////////////////////////////////////////////
		`start_position: begin
			row = starting_row;
			col = starting_col;
			maze_we = 1;
			direction = 0;
			next_state = `choose_first_direction;
		end
////////////////////////////////////////////


////////////////////////////////////////////
		`choose_first_direction: begin       
			case(direction)
				0: row = row - 1; //N
				1: row = row + 1; //S
				2: col = col - 1; //W
				3: col = col + 1; //E
			endcase
			maze_oe = 1;
			next_state = `check_start_free_path;
		end
////////////////////////////////////////////
		
		
////////////////////////////////////////////
		`check_start_free_path: begin
			if(maze_in == 1) begin 
				next_state = `go_back_to_start;
			end else if(maze_in == 0) begin
				maze_we = 1;
				next_state = `choose_direction;
			end
		end
////////////////////////////////////////////


////////////////////////////////////////////		
		`go_back_to_start: begin
			case(direction)
				0: row = row + 1; //N
				1: row = row - 1; //S
				2: col = col + 1; //W
				3: col = col - 1; //E
			endcase
			direction = direction + 1;
			next_state = `choose_first_direction;
		end	
////////////////////////////////////////////


////////////////////////////////////////////		
		`check_free_path: begin
			if(maze_in == 1) begin
				next_state = `go_back;
			end else if(maze_in == 0) begin
				if(row == 0 || row == 63 || col == 0 || col == 63) begin
					maze_we = 1;
					next_state = `exit;
				end else begin
					maze_we = 1;
					direction = last_direction; 		//ultima directie valida salvata din starile: from_north/south/west/est
					next_state = `choose_direction;	//folosita pentru alegerea cazului de verificare in starea choose_direction
				end
			end
		end
////////////////////////////////////////////


////////////////////////////////////////////		//Alege cazul de verificari
		`choose_direction: begin						//in functie de directia valida
			case(direction)								//anterior.  
				0: begin										
						direction_north = direction; //se va incrementa in go_back pt incercari 
						next_state = `from_north;
					end
				1: begin
						direction_south = direction; //se va incrementa in go_back pt incercari
						next_state = `from_south;
					end
				2: begin
						direction_west = direction; //se va incrementa in go_back pt incercari
						next_state = `from_west;
					end
				3: begin
						direction_est = direction; //se va incrementa in go_back pt incercari
						next_state = `from_est;
					end
			endcase
		end
////////////////////////////////////////////


////////////////////////////////////////////
		`from_north: begin   					//Daca m-am deplasat spre NORD anterior
			case(direction_north)				//verificarile se vor face 
				0: begin								//in ordinea: E->N->W->S 
						col = col + 1;//E
						last_direction = 3;
					end
				1: begin
						row = row - 1;//N
						last_direction = 0;
					end
				2: begin
						col = col - 1;//W
						last_direction = 2;
					end
				3: begin
						row = row + 1;//S
						last_direction = 1;
					end
			endcase
			maze_oe = 1;
			next_state = `check_free_path;
		end
////////////////////////////////////////////


////////////////////////////////////////////		
		`from_south: begin						//Daca m-am deplasat spre SUD anterior
			case(direction_south)				//verificarile se vor face 
				0: begin 							//in ordinea: W->S->E->N
						row = row - 1;//N
						last_direction = 0;
					end
				1: begin
						col = col - 1;//W
						last_direction = 2;
					end
				2: begin
						row = row + 1;//S
						last_direction = 1;
					end
				3: begin 
						col = col + 1;//E
						last_direction = 3;
					end
			endcase
			maze_oe = 1;
			next_state = `check_free_path;
		end
////////////////////////////////////////////


////////////////////////////////////////////		
		`from_west: begin							//Daca m-am deplasat spre VEST anterior
			case(direction_west)					//verificarile se vor face
				0: begin								//in ordinea: N->W->S->E
						row = row + 1;//S
						last_direction = 1;
					end
				1: begin
						col = col + 1;//E
						last_direction = 3;
					end
				2:begin
						row = row - 1;//N
						last_direction = 0;
					end
				3: begin
						col = col - 1;//W
						last_direction = 2;
					end
			endcase
			maze_oe = 1;
			next_state = `check_free_path;
		end
////////////////////////////////////////////


////////////////////////////////////////////		
		`from_est: begin						   //Daca m-am deplasat spre EST anterior
			case(direction_est)					//verificarile se vor face 
				0: begin								//in ordinea: S->E->N->V
						col = col + 1;//E
						last_direction = 3;
					end
				1: begin
						row = row - 1;//N
						last_direction = 0;
					end
				2: begin
						col = col - 1;//W
						last_direction = 2;
					end
				3: begin 
						row = row + 1;//S
						last_direction = 1;
					end
			endcase
			maze_oe = 1;
			next_state = `check_free_path;
		end
////////////////////////////////////////////
		

////////////////////////////////////////////
		`go_back: begin                     //Tine cont de ultima directie valida
			case(direction)						//si de verificarile anterioare din : 
				0: begin								//from_north, from_south, from_west, from_est
						case(direction_north)
							0: col = col - 1;//E
							1: row = row + 1;//N
							2: col = col + 1;//W
							3: row = row - 1;//S
						endcase
					direction_north = direction_north + 1;
					next_state = `from_north;
				end
				1: begin
						case(direction_south)
							0: row = row + 1;//N
							1: col = col + 1;//W
							2: row = row - 1;//S
							3: col = col - 1;//E
						endcase
					direction_south = direction_south + 1;
					next_state = `from_south;
				end
				2: begin
						case(direction_west)
							0: row = row - 1;//S
							1: col = col - 1;//E
							2: row = row + 1;//N
							3: col = col + 1;//W
						endcase
					direction_west = direction_west + 1;
					next_state = `from_west;
				end
				3: begin
						case(direction_est)
							0: col = col - 1;//E
							1: row = row + 1;//N
							2: col = col + 1;//W
							3: row = row - 1;//S
						endcase
						direction_est = direction_est + 1;
						next_state = `from_est;
				end
			endcase
		end	
////////////////////////////////////////////

////////////////////////////////////////////
		`exit: done = 1;
////////////////////////////////////////////
	endcase
		
end
endmodule
