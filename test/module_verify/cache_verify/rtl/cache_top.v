module cache_top #
(
   parameter SIMULATION=1'b0
)
(
    input  wire        resetn, 
    input  wire        clk,

    //------gpio-------
    output wire [15:0] led,
    input  wire [7 :0] switch,       
    output reg  [7 :0] num_csn,
    output reg  [6 :0] num_a_g
);
clk_pll clk_pll(
    .clk_out1(clk_g),
    .clk_in1(clk)
);


localparam PREPARE=2'b00;
localparam WRITE  =2'b01;
localparam READ   =2'b10;

reg [ 19:0] tag  [3:0];
reg [127:0] data [3:0];
reg [ 22:0] pseudo_random_23;
reg [  1:0] counter_i;
reg [  1:0] counter_j;
reg [  1:0] round_state;
reg [  7:0] test_index;
reg [  1:0] res_counter_i;
reg [  1:0] res_counter_j;

wire [15:0] switch_led;
wire [15:0] led_r_n;
assign switch_led = {{2{switch[7]}},{2{switch[6]}},{2{switch[5]}},{2{switch[4]}},
                    {2{switch[3]}},{2{switch[2]}},{2{switch[1]}},{2{switch[0]}}};
assign led_r_n = ~switch_led;
always @ (posedge clk_g)
begin
   if (!resetn)
       pseudo_random_23 <= (SIMULATION == 1'b1) ? {7'b1010101,16'h00FF} : {7'b1010101,led_r_n};
   else
       pseudo_random_23 <= {pseudo_random_23[21:0],pseudo_random_23[22] ^ pseudo_random_23[17]};
end

wire addr_ok;

//wait_1s
wire        wait_1s;
reg [26:0] wait_cnt;
assign wait_1s = wait_cnt==27'd0;
always @(posedge clk_g)
begin
    if (!resetn ||  wait_1s)
    begin
        wait_cnt <= (SIMULATION == 1'b1) ? 27'd5 : 27'd8_000_00;
    end
    else
    begin
        wait_cnt <= wait_cnt - 1'b1;
    end
end

reg          memref_valid;
wire         memref_op;
wire [  7:0] in_index;
wire [ 19:0] in_tag;
wire [  3:0] in_offset;
wire [ 31:0] memref_data;
wire [  3:0] memref_wstrb;

wire         cache_addr_ok;
wire         out_valid;
wire [ 31:0] cacheres;
    
wire         rd_req;
wire [  2:0] rd_type;
wire [ 31:0] rd_addr;
wire         rd_rdy;
wire         ret_valid;
wire         ret_last;
wire [ 31:0] ret_data;

wire         wr_req;
wire [  2:0] wr_type;
wire [ 31:0] wr_addr;
wire [  3:0] wr_wstrb;
wire [127:0] wr_data;
wire         wr_rdy;

wire         prepare_finish;
wire         write_finish;
wire         read_finish;
wire         write_round_finish;
wire         read_round_finish;

reg          new_state;

assign addr_ok = cache_addr_ok && memref_valid;
assign prepare_finish = round_state==PREPARE && counter_i==2'b11 && wait_1s;
assign write_round_finish = round_state==WRITE && res_counter_i==2'b11 && res_counter_j==2'b11 && write_finish;
assign  read_round_finish = round_state== READ && res_counter_i==2'b11 && read_finish;

always @(posedge clk_g) begin
    if(!resetn) begin
        test_index   <= 8'b0;
    end
    else if(read_round_finish && ~(&test_index)) begin
        test_index <= test_index + 8'b1;
    end
end

always @(posedge clk_g) begin
    if(!resetn) begin
        counter_i    <= 2'b0;
        counter_j    <= 2'b0;
    end
    else if(round_state==PREPARE && wait_1s) begin
        counter_i <= counter_i + 2'b01;
    end
    else if(round_state==WRITE && addr_ok) begin
        counter_j <= counter_j + 2'b01;
        if(counter_j==2'b11) begin
            counter_i <= counter_i + 2'b01;
        end
    end
    else if(round_state==READ && addr_ok) begin
        counter_i <= counter_i + 2'b01;
    end
end

always @(posedge clk_g) begin
    if(!resetn) begin
        res_counter_i    <= 2'b0;
        res_counter_j    <= 2'b0;
    end
    else if(round_state==WRITE && write_finish) begin
        res_counter_j <= res_counter_j + 2'b01;
        if(res_counter_j==2'b11) begin
            res_counter_i <= res_counter_i + 2'b01;
        end
    end
    else if(round_state==READ && read_finish) begin
        res_counter_i <= res_counter_i + 2'b01;
    end
end

always @(posedge clk_g) begin
    if(prepare_finish || write_round_finish || read_round_finish) begin
        new_state <= 1'b1;
    end
    else if(new_state) begin
        new_state <= 1'b0;
    end
end

always @(posedge clk_g) begin
    if(!resetn) begin
        round_state <= PREPARE;
    end
    else if(prepare_finish) begin
        round_state <= WRITE;
    end
    else if(write_round_finish) begin
        round_state <= READ;
    end
    else if(read_round_finish && ~(&test_index)) begin
        round_state <= PREPARE;
    end
end

/*      prepare         */
always @(posedge clk_g) begin
    if(!resetn) begin
        tag[0] <= 20'b0;
        tag[1] <= 20'b0;
        tag[2] <= 20'b0;
        tag[3] <= 20'b0;
        data[0] <= 128'b0;
        data[1] <= 128'b0;
        data[2] <= 128'b0;
        data[3] <= 128'b0;
    end
    else if(round_state==PREPARE && wait_1s) begin
        tag[counter_i] <= pseudo_random_23[19:0];
        data[counter_i] <= {{5{pseudo_random_23}},pseudo_random_23[12:0]};
    end
end    

/*       write          */
wire write_start;
assign write_start = round_state==WRITE && (new_state || (addr_ok && !(counter_i==2'b11 && counter_j==2'b11)));
assign write_finish = round_state==WRITE && out_valid;
assign memref_op = round_state==WRITE;

assign in_index  = test_index;
assign in_tag    = tag[counter_i];
assign in_offset = {counter_j,2'b00};
assign memref_data = {32{counter_j==2'b00}} & data[counter_i][ 31: 0]
                   | {32{counter_j==2'b01}} & data[counter_i][ 63:32]
                   | {32{counter_j==2'b10}} & data[counter_i][ 95:64]
                   | {32{counter_j==2'b11}} & data[counter_i][127:96];
assign memref_wstrb = counter_j==2'b11 ? 4'b0111 : 4'b1111;

/*       read          */
wire read_start;
wire cacheres_right;
wire cacheres_wrong;
assign read_start = round_state==READ && (new_state || (addr_ok && !(counter_i==2'b11)));
assign read_finish = round_state==READ && cacheres_right;
assign cacheres_right = out_valid && cacheres == data[res_counter_i][31:0];
assign cacheres_wrong = out_valid && cacheres != data[res_counter_i][31:0] && round_state==READ;

always @(posedge clk_g) begin
    if(!resetn) begin
        memref_valid <= 1'b0;
    end
    else if(write_start) begin
        memref_valid <= 1'b1;
    end
    else if(read_start) begin
        memref_valid <= 1'b1;
    end
    else if(addr_ok) begin
        memref_valid <= 1'b0;
    end
end

cache cache(
    .clk    (clk_g),
    .resetn (resetn),
    .valid  (memref_valid),
    .op     (memref_op ),
    .index  (in_index  ),
    .tag    (in_tag    ),
    .offset (in_offset ),
    .wstrb  (memref_wstrb),
    .wdata  (memref_data),

    .addr_ok(cache_addr_ok),
    .data_ok(out_valid),
    .rdata  (cacheres ),

    .rd_req   (rd_req   ),
    .rd_type  (rd_type  ),
    .rd_addr  (rd_addr  ),
    .rd_rdy   (rd_rdy   ),
    .ret_valid(ret_valid),
    .ret_last (ret_last ),
    .ret_data (ret_data ),

    .wr_req  (wr_req  ),
    .wr_type (wr_type ),
    .wr_addr (wr_addr ),
    .wr_wstrb(wr_wstrb),
    .wr_data (wr_data ),
    .wr_rdy  (wr_rdy  )
);

/*         rd respond       */
reg do_rd;
reg [1:0] rd_cnt;
reg [19:0] rd_tag_r;
reg [7:0] rd_index_r;
wire [127:0] rd_hit_data;
wire [31:0] rd_true_value;
assign rd_hit_data = {128{rd_tag_r == tag[0]}} & data[0]
                   | {128{rd_tag_r == tag[1]}} & data[1]
                   | {128{rd_tag_r == tag[2]}} & data[2]
                   | {128{rd_tag_r == tag[3]}} & data[3];

assign rd_true_value = {32{rd_cnt==2'b00 && rd_index_r==test_index}} & rd_hit_data[31 : 0]
                     | {32{rd_cnt==2'b01 && rd_index_r==test_index}} & rd_hit_data[63 :32]
                     | {32{rd_cnt==2'b10 && rd_index_r==test_index}} & rd_hit_data[95 :64]
                     | {32{rd_cnt==2'b11 && rd_index_r==test_index}} & {8'hff,rd_hit_data[119:96]};

assign rd_rdy = ~do_rd;
assign ret_valid = do_rd;
assign ret_last = rd_cnt == 2'b11;
assign ret_data = round_state==WRITE ? 32'hffffffff : rd_true_value;

always @(posedge clk_g) begin
    if(!resetn) begin
        do_rd <= 1'b0;
    end
    if(rd_req && ~do_rd) begin
        do_rd <= 1'b1;
        rd_tag_r <= rd_addr[31:12];
        rd_index_r <= rd_addr[11:4];
    end
    else if(do_rd && rd_cnt==2'b11) begin
        do_rd <= 1'b0;
    end
end

always @(posedge clk_g) begin
    if(!resetn) begin
        rd_cnt <= 2'b00;
    end
    else if(do_rd) begin
        rd_cnt <= rd_cnt + 2'b01;
    end
end
/*         wr respond       */
reg do_wr;
reg [127:0] wr_data_r;
reg [ 19:0] wr_tag_r;
reg [  7:0] wr_index_r;
wire data_right;
wire replace_wrong;
wire [127:0] wr_hit_data;
assign wr_hit_data = {128{wr_tag_r == tag[0] && wr_index_r==test_index}} & data[0]
                   | {128{wr_tag_r == tag[1] && wr_index_r==test_index}} & data[1]
                   | {128{wr_tag_r == tag[2] && wr_index_r==test_index}} & data[2]
                   | {128{wr_tag_r == tag[3] && wr_index_r==test_index}} & data[3];
assign data_right = {8'hff,wr_hit_data[119:0]} == wr_data_r;
assign replace_wrong = do_wr && {8'hff,wr_hit_data[119:0]} != wr_data_r;

assign wr_rdy = ~do_wr;
always @(posedge clk_g) begin
    if(!resetn) begin
        do_wr <= 1'b0;
    end
    if(wr_req && ~do_wr) begin
        do_wr <= 1'b1;
        wr_data_r <= wr_data;
        wr_tag_r <= wr_addr[31:12];
        wr_index_r <= wr_addr[11:4];
    end
    else if(do_wr && data_right) begin
        do_wr <= 1'b0;
    end
end

/* --------------   print   ---------------*/

reg [19:0] count;
always @(posedge clk_g)
begin
    if(!resetn)
    begin
        count <= 20'd0;
    end
    else
    begin
        count <= count + 1'b1;
    end
end
//scan data
reg [3:0] scan_data;
always @ ( posedge clk_g)  
begin
    if ( !resetn )
    begin
        scan_data <= 32'd0;  
        num_csn   <= 8'b1111_1111;
    end
    else
    begin
        case(count[19:17])
            3'b000 : scan_data <= test_index[7:4];
            3'b001 : scan_data <= test_index[3:0];
            3'b010 : scan_data <= 4'b0;
            3'b011 : scan_data <= 4'b0;
            3'b100 : scan_data <= 4'b0;
            3'b101 : scan_data <= 4'b0;
            3'b110 : scan_data <= 4'b0;
            3'b111 : scan_data <= 4'b0;
        endcase

        case(count[19:17])
            3'b000 : num_csn <= 8'b0111_1111;
            3'b001 : num_csn <= 8'b1011_1111;
            3'b010 : num_csn <= 8'b1101_1111;
            3'b011 : num_csn <= 8'b1110_1111;
            3'b100 : num_csn <= 8'b1111_0111;
            3'b101 : num_csn <= 8'b1111_1011;
            3'b110 : num_csn <= 8'b1111_1101;
            3'b111 : num_csn <= 8'b1111_1110;
        endcase
    end
end

always @(posedge clk_g)
begin
    if ( !resetn )
    begin
        num_a_g <= 7'b0000000;
    end
    else
    begin
        case ( scan_data )
            4'd0 : num_a_g <= 7'b1111110;   //0
            4'd1 : num_a_g <= 7'b0110000;   //1
            4'd2 : num_a_g <= 7'b1101101;   //2
            4'd3 : num_a_g <= 7'b1111001;   //3
            4'd4 : num_a_g <= 7'b0110011;   //4
            4'd5 : num_a_g <= 7'b1011011;   //5
            4'd6 : num_a_g <= 7'b1011111;   //6
            4'd7 : num_a_g <= 7'b1110000;   //7
            4'd8 : num_a_g <= 7'b1111111;   //8
            4'd9 : num_a_g <= 7'b1111011;   //9
            4'd10: num_a_g <= 7'b1110111;   //a
            4'd11: num_a_g <= 7'b0011111;   //b
            4'd12: num_a_g <= 7'b1001110;   //c
            4'd13: num_a_g <= 7'b0111101;   //d
            4'd14: num_a_g <= 7'b1001111;   //e
            4'd15: num_a_g <= 7'b1000111;   //f
        endcase
    end
end

assign led = {16'hffff};

endmodule
