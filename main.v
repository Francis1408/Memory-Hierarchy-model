module Pratica1_parte3(clock, instruction, wback, hit_miss, data_out, Valid_way1, Valid_way2, LRU_way1, LRU_way2, dirty_way1, dirty_way2, tag_out_way1, tag_out_way2);


input clock;
input [8:0] instruction;

output wback;
output hit_miss;
output [2:0] data_out; 

// --- Cache blocks ---
output Valid_way1;
output Valid_way2;
output LRU_way1; 
output LRU_way2; 
output dirty_way1; 
output dirty_way2; 
output [2:0] tag_out_way1; 
output [2:0] tag_out_way2;


cache _CACHE_(clock, instruction, wback, hit_miss, data_out, Valid_way1, Valid_way2, LRU_way1, LRU_way2, dirty_way1, dirty_way2, tag_out_way1, tag_out_way2);



endmodule