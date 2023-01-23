module mux_controler(instruction_address, clock, signal_controller, cache_data_output, wb_address, controller_running, cache_data_input, done);

input clock;
input [2:0] signal_controller;
input [4:0] instruction_address;
input [2:0] cache_data_output;
input [4:0] wb_address;
input controller_running;

output reg [2:0] cache_data_input;
output reg done;

reg [4:0] controller;
reg [2:0] temp_ram;
reg [2:0] ram_data_input;
reg write_ram;
reg [4:0] address;
reg internal_running;

wire [2:0] ram_data_output;


initial begin
	controller = 0;
	done = 0;
	internal_running = 0;
end


always @(posedge clock)
begin
	if(controller == 5'b00000) begin
		done <= 0;
		
		if(internal_running) begin
			$write("Controller Running");
			if(signal_controller == 3'b000) begin // Read miss s/ Dirty
				controller <= 5'b00100;
			end
			else if(signal_controller == 3'b011 || signal_controller == 3'b111 ) begin // Write miss/hit c/ Dirty
				controller <= 5'b01000;
			end
			else if(signal_controller == 3'b001) begin // Read miss c/ Dirty 
				controller <= 5'b01001;
			end
			else begin
				controller <= 5'b00000;
			end
		end
		
		if(controller_running)	begin
			$write("Connecting to controller");
			internal_running <= 1;
		end
	end
	
	if(controller == 5'b00100) begin // Read on RAM
		$write("Setting values");
		address <= instruction_address;
		write_ram <= 0;
		controller <= 5'b00101;
	end
	
	else if(controller == 5'b00101) begin // Reading on RAM
		$write("Reading on RAM");
		controller <= 5'b00110;
	end
	
	else if(controller == 5'b00110) begin
		$write("Saving Values");
		temp_ram <= ram_data_output;
		controller <= 5'b00111;
	end
	
	else if(controller == 5'b00111) begin // Send to Cache
		$write("Sending to Cache");
		cache_data_input <= temp_ram;
		controller <= 5'b00000;
		done <= 1;
		internal_running <= 0;
	end
	
	else if(controller == 5'b01000) begin // Write Data on RAM (Write Miss)
		$write("Writing on RAM (Write Miss)");
		address <= wb_address;
		ram_data_input <= cache_data_output;
		write_ram <= 1;
		controller <= 5'b00000;
		done <= 1;
		internal_running <= 0;
	end
	
	else if(controller == 5'b01001) begin // Write Data on RAM (Read miss)
		$write("Writing on RAM (Read Miss)");
		address <=  wb_address;
		ram_data_input <= cache_data_output;
		write_ram <= 1;
		controller <=  5'b00100;
	end
end


ram _RAM_(address, clock, ram_data_input, write_ram, ram_data_output);

endmodule
