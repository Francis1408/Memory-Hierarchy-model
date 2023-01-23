module cache(clock, 
				 instruction,
				 wback, 
				 hit_miss, 
				 data_out,
				 Valid_way1, 
				 Valid_way2,	 
				 LRU_way1, 
				 LRU_way2, 
				 dirty_way1, 
				 dirty_way2, 
				 tag_out_way1, 
				 tag_out_way2);

				 
// ----- Signals inputs --------				 
input clock;
input [8:0] instruction;

// ----- Signals outputs -------
output reg wback;
output reg hit_miss;
output reg [2:0] data_out;
output reg Valid_way1;
output reg Valid_way2;
output reg LRU_way1;
output reg LRU_way2;
output reg dirty_way1;
output reg dirty_way2;
output reg [2:0] tag_out_way1;
output reg [2:0] tag_out_way2;


// Chanel 1
// word   -> [    [8:8]       [7:7]      [6:6]      [5:3]     [2:0]     ] <- Positions on array
// word   -> [  [ valid ]   [ LRU ]    [ dirty ]    [ TAG ]   [ DATA ]  ] <- Representation
// Size   -> [   [1 bit]    [1 bit]     [1 bit]     [3 bits]  [3 bits]  ] <- Size

reg [8:0]cache[7:0];


reg running;
reg send_data;

// ---- CONTROLLER INPUTS ----
reg [2:0] wb_data;
reg [4:0] wb_address;
reg [4:0] instruction_address;
reg controller_running;
wire [2:0] signal_controller;



// ---- INTERNAL WIRES and REGS ----
wire [1:0]index;
wire [2:0]tag;
wire [2:0] data;
wire [2:0] cache_data_in;
wire done_ram;
reg [7:0] temp_index;
reg write_inst;




assign tag = instruction[7:5];
assign index = instruction[4:3];
assign data = instruction[2:0];

initial begin
	$display("Cache running");	
	running = 1;
	controller_running = 1;
	send_data = 0;
	
	// Cache initialization
	
	// First Row
	cache[0][8:8] = 0;
	cache[0][7:7] = 0;
	cache[0][6:6] = 0;
	cache[0][5:3] = 3'b100;
	cache[0][2:0] = 3'b011;
	//-----------------
	cache[4][8:8] = 1;
	cache[4][7:7] = 1;
	cache[4][6:6] = 0;
	cache[4][5:3] = 3'b101;
	cache[4][2:0] = 3'b100;
	
	// Second Row
	cache[1][8:8] = 1;
	cache[1][7:7] = 0;
	cache[1][6:6] = 0;
	cache[1][5:3] = 3'b000;
	cache[1][2:0] = 3'b011;
	//-----------------
	cache[5][8:8] = 1;
	cache[5][7:7] = 1;
	cache[5][6:6] = 0;
	cache[5][5:3] = 3'b001;
	cache[5][2:0] = 3'b111;
	
	// Third Row
	cache[2][8:8] = 0;
	//-----------------
	cache[6][8:8] = 0;
	
	// Fourth Row
	cache[3][8:8] = 1;
	cache[3][7:7] = 1;
	cache[3][6:6] = 0;
	cache[3][2:0] = 3'b011;
	//-----------------
	cache[7][8:8] = 0; 
end

always @(negedge clock) 
begin
	
	if(running == 1 || done_ram == 1 || send_data == 1) begin
	
		if(done_ram == 1) begin
		$write("Writing data");
			cache[temp_index][2:0] <= cache_data_in;
			send_data <= 1;
		end
		
		if(send_data == 1) begin
		// Exporting signals
			$write("Exporting data");
			Valid_way1 <= cache[index][8:8];
			Valid_way2 <= cache[index+4][8:8];
			LRU_way1 <= cache[index][7:7];
			LRU_way2 <= cache[index+4][7:7];
			dirty_way1 <= cache[index][6:6];
			dirty_way2 <= cache[index+4][6:6];
			tag_out_way1 <= cache[index][5:3];
			tag_out_way2 <= cache[index+4][5:3];
			running <= 1;
			send_data <= 0;
			controller_running <= 1;
			
			if(!write_inst) begin
				data_out <= cache[temp_index][2:0];
			end
			else begin
				data_out <= 0;
			end
		end
		
		if(running == 1) begin
			case(instruction[8:8])	
		
		
		//------------- READ INSTRUCTION ---------------------
			
			1'b0: begin
			
				if(!cache[index][8:8] && !cache[index+4][8:8]) // Way1 and 2 are not valid (Read Miss)
				begin
					$write("Read miss not valid Way1 and Way2");
					hit_miss <= 0;     // Miss
					cache[index][8:8] <= 1; // Valid
					cache[index][7:7] <= 1; // LRU
					cache[index+4][7:7] <= 0; // LRU way2 down
					cache[index][6:6] <= 0; // Dirty
					cache[index][5:3] <= tag; // Write Tag
					wback <= 0;
					
					$write("FETCH ON RAM");
					// Fetch data from ram
					temp_index <= index;
					instruction_address <= instruction[7:3];
					
					running <= 0;
					write_inst <= 0;
					controller_running <= 0;
				end
					
				else if(cache[index][5:3] == tag && cache[index][8:8]) // Read Hit on Way1
				begin
					$write("READ HIT WAY 1");
					hit_miss <= 1;
					cache[index][7:7] <= 1; // LRU
					cache[index+4][7:7] <= 0; //LRU way2 down
					wback <= 0;
					temp_index <= index; // Read Data
				
					// Does not read on RAM
					send_data <= 1;
					running <= 0;
					write_inst <= 0;
					controller_running <= 0;
								
				end
				
				else if(cache[index+4][5:3] == tag && cache[index+4][8:8]) // Read Hit on Way2
				begin
					$write("READ HIT WAY 2");
					hit_miss <= 1;
					cache[index+4][7:7] <= 1; // LRU
					cache[index][7:7] <= 0; //LRU way1 down
					wback <= 0;
					temp_index <= index+4; // Read Data
					
					// Does not read on RAM
					send_data <= 1;
					running <= 0;
					write_inst <= 0;
					controller_running <= 0;

				end
				
				else if(!cache[index][8:8]) // Way1 are not valid (Read Miss)
				begin
					$write("Read miss not valid Way1");
					hit_miss <= 0;     // Miss
					cache[index][8:8] <= 1; // Valid
					cache[index][7:7] <= 1; // LRU
					cache[index+4][7:7] <= 0; // LRU way2 down
					cache[index][6:6] <= 0; // Dirty
					cache[index][5:3] <= tag; // Write Tag
					wback <= 0;
					
					$write("FETCH ON RAM");
					// Fetch data from RAM
					temp_index <= index;
					instruction_address <= instruction[7:3];
					running <= 0;
					write_inst <= 0;
					controller_running <= 0;
					
				end
				
				else if(!cache[index+4][8:8]) // Way2 are not valid (Read Miss)
				begin
					$write("Read miss not valid Way2");
					hit_miss <= 0;     // Miss
					cache[index+4][8:8] <= 1; // Valid
					cache[index+4][7:7] <= 1; // LRU
					cache[index][7:7] <= 0; // LRU way1 down
					cache[index+4][6:6] <= 0; // Dirty
					cache[index+4][5:3] <= tag; // Write Tag
					wback <= 0;
					
					$write("FETCH ON RAM");
					// Fetch data from RAM
					temp_index <= index+4;
					instruction_address <= instruction[7:3];
					running <= 0;
					write_inst <= 0;
					controller_running <= 0;
					
				end
				
				
				else if(cache[index][7:7] == 0 ) // Read miss. Write on way1
				begin
					$write("READ MISS WAY 1");
					hit_miss <= 0; 
					cache[index][7:7] <= 1; //LRU
					cache[index+4][7:7] <= 0; //LRU way2 down
					write_inst <= 0;
					
					
					if(cache[index][6:6]) //Write back and fetch data from RAM
					begin
						$write("WRITE BACK WITH FETCH ON RAM");
						wback <= 1;
						cache[index][6:6] <= 0;
						wb_data <= cache[index][2:0];
						wb_address <= {cache[index][5:3], index};
						running <= 0;
						instruction_address <= instruction[7:3];
						cache[index][5:3] <= tag;
						temp_index <= index;
						controller_running <= 0;
		
					end
					else begin
						$write("FETCH ON RAM");
					// Fetch data from RAM
						wback <= 0;
						running <= 0;
						instruction_address <= instruction[7:3];
						cache[index][5:3] <= tag;
						temp_index <= index;
						controller_running <= 0;
					end
					
				end
				
				else if(cache[index+4][7:7] == 0 ) // Read miss. Write on way2
				begin 
					$write("READ MISS WAY 2");
					hit_miss <= 0; 
					cache[index+4][7:7] <= 1; //LRU
					cache[index][7:7] <= 0; //LRU way1 down
					write_inst <= 0;
					
					if(cache[index+4][6:6]) //Write back and fetch data from RAM
					begin
						$write("WRITE BACK WITH FETCH ON RAM");
						wback <= 1;
						cache[index+4][6:6] <= 0;
						instruction_address <= instruction[7:3];
						wb_data <= cache[index+4][2:0];
						wb_address <= {cache[index+4][5:3], index};
						running <= 0;
						cache[index+4][5:3] <= tag;
						temp_index <= index+4;
						controller_running <= 0;
					end
					else begin
						$write("FETCH ON RAM");
					// Fetch data from RAM
						wback <= 0;
						running <= 0;
						instruction_address <= instruction[7:3];
						cache[index+4][5:3] <= tag;
						temp_index <= index+4;
						controller_running <= 0;
					end
				end
			end
			
		//---------------------------------------------------
		
		//------------------- WRITE INSTRUCTION -------------
			1'b1: begin
				if(!cache[index][8:8] && !cache[index+4][8:8]) // Way1 and Way2 are not valid (Write Miss)
					begin
						$write("Write Miss not Valid Way 1");
						hit_miss <= 0;     // Miss
						cache[index][8:8] <= 1; // Valid
						cache[index][7:7] <= 1; // LRU
						cache[index+4][7:7] <= 0; // LRU way2 down
						cache[index][6:6] <= 1; // Dirty Up
						cache[index][5:3] <= tag; // Write Tag
						cache[index][2:0] <= data; //Write Data
						wback <= 0;
						send_data <= 1;
						running <= 0;
						
						// No output
						write_inst <= 1;
						
						controller_running <= 0;
									
				end
				
				else if(cache[index][5:3] == tag && cache[index][8:8]) // Write Hit on Way1
					begin
						$write("Write Hit Way 1");
						hit_miss <= 1;
						cache[index][7:7] <= 1; // LRU
						cache[index+4][7:7] <= 0; //LRU way2 down
						running <= 0;
						
						// No output
						write_inst <= 1;
						
						if(cache[index][6:6]) // Write back
						begin
							$write("Write back Way 1");
						// Write old data on Ram and new on cache
							wback <= 1;
							wb_data <= cache[index][2:0];
							wb_address <= {cache[index][5:3], index};
							cache[index][2:0] <= data;
						//	done <= done_ram;
						end
						else begin
						// Write data on cache
							wback <= 0;
							cache[index][2:0] <= data;
							send_data <= 1;
							cache[index][6:6] <= 1; // Dirty Up
						end
						
						controller_running <= 0;
						
					end
					
					else if(cache[index+4][5:3] == tag && cache[index+4][8:8]) // Write Hit on Way2
					begin
						$write("Write Hit Way 2");
						hit_miss <= 1;
						cache[index+4][7:7] <= 1; // LRU
						cache[index][7:7] <= 0; //LRU way1 down
						running <= 0;
						
						// No output
						write_inst <= 1;
						
						if(cache[index+4][6:6]) // Write back
						begin
							$write("Write back Way 2");
						// Write old data on Ram and new on cache
							wback <= 1;
							wb_data <= cache[index+4][2:0]; 
							wb_address <= {cache[index+4][5:3], index};
							cache[index+4][2:0] <= data;
						end
						else begin
						//Write data on cache
							wback <= 0;
							cache[index+4][2:0] <= data;
							send_data <= 1;
							cache[index+4][6:6] <= 1; // Dirty Up
						end
						
						controller_running <= 0;
						
					end
					
					else if(!cache[index][8:8]) // Way1 are not valid (Write Miss)
					begin
						$write("Write Miss not Valid Way 1");
						hit_miss <= 0;     // Miss
						cache[index][8:8] <= 1; // Valid
						cache[index][7:7] <= 1; // LRU
						cache[index+4][7:7] <= 0; // LRU way2 down
						cache[index][6:6] <= 1; // Dirty Up
						cache[index][5:3] <= tag; // Write Tag
						cache[index][2:0] <= data; //Write Data
						wback <= 0;
						running <= 0;
						send_data <= 1;
						
						// No output
						write_inst <= 1;
						
						controller_running <= 0;
					end
					
					else if(!cache[index+4][8:8]) // Way2 are not valid (Write Miss)
					begin
						$write("Write Miss not Valid Way 2");
						hit_miss <= 0;     // Miss
						cache[index+4][8:8] <= 1; // Valid
						cache[index+4][7:7] <= 1; // LRU
						cache[index][7:7] <= 0; // LRU way1 down
						cache[index+4][6:6] <= 1; // Dirty up
						cache[index+4][5:3] <= tag; // Write Tag
						cache[index+4][2:0] <= data; // Write Data
						wback <= 0;
						running <= 0;
						send_data <= 1;
						
						// No output
						write_inst <= 1;
						
						controller_running <= 0;			
					end
					
					
					else if(cache[index][7:7] == 0 ) // Write miss way1. 
					begin
						$write("Write Miss tag Way1");
						hit_miss <= 0; 
						cache[index][7:7] <= 1; //LRU
						cache[index+4][7:7] <= 0; //LRU way2 down
						running <= 0;
						
						// No output
						write_inst <= 1;
						
						if(cache[index][6:6]) //Write back
						begin
							$write("Write Back");
						// Write old data on Ram and new on cache
							wback <= 1;
							wb_data <= cache[index][2:0]; 
							wb_address <= {cache[index][5:3], index};
							cache[index][2:0] <= data;
							cache[index][5:3] <= tag;
						end
						else begin
						//Write data on cache
							wback <= 0;
							cache[index][2:0] <= data;
							cache[index][5:3] <= tag;
							send_data <= 1;
							cache[index][6:6] <= 1; // Dirty Up
						end
						
						controller_running <= 0;
					end
					
					else if(cache[index+4][7:7] == 0 ) // Write miss way2.
					begin
						$write("Write Miss tag Way2");
						hit_miss <= 0; 
						cache[index+4][7:7] <= 1; //LRU
						cache[index][7:7] <= 0; //LRU way1 down
						running <= 0;
						
						// No output
						write_inst <= 1;
						
						if(cache[index+4][6:6]) //Write back
						begin
							$write("Write Back");
						// Write old data on Ram and new on cache
							wback <= 1;
							wb_data <= cache[index+4][2:0]; 
							wb_address <= {cache[index+4][5:3], index};
							cache[index+4][2:0] <= data;
							cache[index+4][5:3] <= tag;
						end
						else begin
						// Write data on cache
							wback <= 0;
							cache[index+4][2:0] <= data;
							cache[index+4][5:3] <= tag;
							send_data <= 1;
							cache[index+4][6:6] <= 1; // Dirty Up
						end
						
						controller_running <= 0;
					end
				end		
			endcase
		end
	end
end  


assign signal_controller = {hit_miss, instruction[8:8], wback};

mux_controler _MUX_(instruction_address, clock, signal_controller, wb_data, wb_address, controller_running, cache_data_in, done_ram);


endmodule