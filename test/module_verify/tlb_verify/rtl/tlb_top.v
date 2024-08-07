//the test include 2 parts : write / read & search.
module tlb_top #
(
    parameter TLBNUM=16
   ,parameter SIMULATION=1'b0
)
(
    input  wire        resetn, 
    input  wire        clk,

    //------gpio-------
    output wire [15:0] led,
    output reg  [7 :0] num_csn,
    output reg  [6 :0] num_a_g
);

clk_pll clk_pll(
    .clk_out1(clk_g),
    .clk_in1(clk)
);

reg       test_error;
reg       tlb_w_test_ok;
reg       tlb_r_test_ok;
reg       tlb_s_test_ok;
reg [3:0] tlb_w_cnt;
reg [3:0] tlb_r_cnt;
reg [3:0] tlb_s_cnt;

// search port 0
wire [18:0] s0_vppn;
wire        s0_va_bit12;
wire [9 :0] s0_asid;
wire        s0_found;
wire [$clog2(TLBNUM)-1:0]s0_index;
wire [19:0] s0_ppn;
wire [5 :0] s0_ps;
wire [1 :0] s0_plv;
wire [1 :0] s0_mat;
wire        s0_d;
wire        s0_v;
// search port 1
wire [18:0] s1_vppn;
wire        s1_va_bit12;
wire [9 :0] s1_asid;
wire        s1_found;
wire [$clog2(TLBNUM)-1:0] s1_index;
wire [19:0] s1_ppn;
wire [5 :0] s1_ps;
wire [1 :0] s1_plv;
wire [1 :0] s1_mat;
wire        s1_d;
wire        s1_v;
// write port
wire        we;
wire [$clog2(TLBNUM)-1:0] w_index;
wire        w_e;
wire [18:0] w_vppn;
wire [5 :0] w_ps  ;
wire [9 :0] w_asid;
wire        w_g;
wire [19:0] w_ppn0;
wire [1 :0] w_plv0;
wire [1 :0] w_mat0;
wire        w_d0;
wire        w_v0;
wire [19:0] w_ppn1;
wire [1 :0] w_plv1;
wire [1 :0] w_mat1;
wire        w_d1;
wire        w_v1;
// read port
wire [$clog2(TLBNUM)-1:0] r_index;
wire        r_e;
wire [18:0] r_vppn;
wire [5 :0] r_ps;
wire [9 :0] r_asid;
wire        r_g;
wire [19:0] r_ppn0;
wire [1 :0] r_plv0;
wire [1 :0] r_mat0;
wire        r_d0;
wire        r_v0;
wire [19:0] r_ppn1;
wire [1 :0] r_plv1;
wire [1 :0] r_mat1;
wire        r_d1;
wire        r_v1;

wire        r_error;
wire        s0_error;
wire        s1_error;
wire        wait_1s;

//wait_1s
reg [26:0] wait_cnt;
assign wait_1s = wait_cnt==27'd0;
always @(posedge clk_g)
begin
    if (!resetn ||  wait_1s)
    begin
        wait_cnt <= (SIMULATION == 1'b1) ? 27'd5 : 27'd30_000_000;
    end
    else
    begin
        wait_cnt <= wait_cnt - 1'b1;
    end
end
tlb #(.TLBNUM(16)) tlb (
    .clk         (clk_g      ),
    .s0_vppn     (s0_vppn    ),
    .s0_va_bit12 (s0_va_bit12),
    .s0_asid     (s0_asid    ),
    .s0_found    (s0_found   ),
    .s0_index    (s0_index   ),
    .s0_ppn      (s0_ppn     ),
    .s0_ps       (s0_ps      ),
    .s0_plv      (s0_plv     ),
    .s0_mat      (s0_mat     ),
    .s0_d        (s0_d       ),
    .s0_v        (s0_v       ),

    .s1_vppn     (s1_vppn    ),
    .s1_va_bit12 (s1_va_bit12),
    .s1_asid     (s1_asid    ),
    .s1_found    (s1_found   ),
    .s1_index    (s1_index   ),
    .s1_ppn      (s1_ppn     ),
    .s1_ps       (s1_ps      ),
    .s1_plv      (s1_plv     ),
    .s1_mat      (s1_mat     ),
    .s1_d        (s1_d       ),
    .s1_v        (s1_v       ),

    .invtlb_valid(1'b0       ),
    .invtlb_op   (5'd0       ),

    .we          (we         ),
    .w_index     (w_index    ),
    .w_e         (w_e        ),
    .w_vppn      (w_vppn     ),
    .w_ps        (w_ps       ),
    .w_asid      (w_asid     ),
    .w_g         (w_g        ),
    .w_ppn0      (w_ppn0     ),
    .w_plv0      (w_plv0     ),
    .w_mat0      (w_mat0     ),
    .w_d0        (w_d0       ),
    .w_v0        (w_v0       ),
    .w_ppn1      (w_ppn1     ),
    .w_plv1      (w_plv1     ),
    .w_mat1      (w_mat1     ),
    .w_d1        (w_d1       ),
    .w_v1        (w_v1       ),

    .r_index     (r_index    ),
    .r_e         (r_e        ),
    .r_vppn      (r_vppn     ),
    .r_ps        (r_ps       ),
    .r_asid      (r_asid     ),
    .r_g         (r_g        ),
    .r_ppn0      (r_ppn0     ),
    .r_plv0      (r_plv0     ),
    .r_mat0      (r_mat0     ),
    .r_d0        (r_d0       ),
    .r_v0        (r_v0       ),
    .r_ppn1      (r_ppn1     ),
    .r_plv1      (r_plv1     ),
    .r_mat1      (r_mat1     ),
    .r_d1        (r_d1       ),
    .r_v1        (r_v1       )
);

// input data
// write \ read

//  index  | e | vppn   | ps   | asid |  g  |  ppn0  |  plv0 mat0 d0 v0 |  ppn1  |  plv1 mat1 d1 v1 |
//   0     | 1 | 0x1000 | 0x15 | 0x0  |  0  |  0x1000|     0,1,1,1      |  0x1100|     0,1,1,1      | 
//   1     | 1 | 0x111  | 0xc  | 0x1  |  1  |  0x222 |     0,1,1,1      |  0x033 |     0,1,1,1      | 
//   2     | 1 | 0x222  | 0xc  | 0x2  |  0  |  0x333 |     0,1,1,1      |  0x044 |     0,1,1,1      | 
//   3     | 1 | 0x333  | 0xc  | 0x3  |  1  |  0x444 |     0,1,1,1      |  0x055 |     0,1,1,1      | 
//   4     | 1 | 0x444  | 0xc  | 0x4  |  0  |  0x555 |     0,1,1,1      |  0x066 |     0,1,1,1      | 
//   5     | 1 | 0x444  | 0xc  | 0x5  |  0  |  0x666 |     0,1,1,1      |  0x077 |     0,1,1,1      | 
//   6     | 1 | 0x666  | 0xc  | 0x6  |  0  |  0x777 |     0,1,1,1      |  0x088 |     0,1,1,1      | 
//   7     | 1 | 0x666  | 0xc  | 0x7  |  0  |  0x888 |     0,1,1,1      |  0x099 |     0,1,1,1      | 
//   8     | 1 | 0x888  | 0xc  | 0x8  |  0  |  0x999 |     0,1,1,1      |  0x0aa |     0,1,1,1      | 
//   9     | 1 | 0x999  | 0xc  | 0x9  |  0  |  0xaaa |     0,1,1,1      |  0x0bb |     0,1,1,1      | 
//   10    | 1 | 0xaaa  | 0xc  | 0xa  |  0  |  0xbbb |     0,1,1,1      |  0x0cc |     0,1,1,1      | 
//   11    | 1 | 0xbbb  | 0xc  | 0xb  |  0  |  0xccc |     0,1,1,1      |  0x0dd |     0,1,1,1      | 
//   12    | 1 | 0xccc  | 0xc  | 0xc  |  0  |  0xddd |     0,1,1,1      |  0x0ee |     0,1,1,1      | 
//   13    | 1 | 0xddd  | 0xc  | 0xd  |  0  |  0xeee |     0,1,1,1      |  0x0ff |     0,1,1,1      | 
//   14    | 1 | 0xeee  | 0xc  | 0xe  |  0  |  0xfff |     0,1,1,1      |  0x000 |     0,1,1,1      | 
//   15    | 1 | 0xf000 | 0x15 | 0xf  |  0  |  0x2000|     0,1,1,1      |  0x2100|     0,1,1,1      | 

wire [18:0] tlb_vppn [15:0];
wire        tlb_e    [15:0];
wire [5 :0] tlb_ps   [15:0];
wire [9 :0] tlb_asid [15:0];
wire        tlb_g    [15:0];
wire [19:0] tlb_ppn0 [15:0];
wire [1 :0] tlb_plv0 [15:0];
wire [1 :0] tlb_mat0 [15:0];
wire        tlb_d0   [15:0];
wire        tlb_v0   [15:0];
wire [19:0] tlb_ppn1 [15:0];
wire [1 :0] tlb_plv1 [15:0];
wire [1 :0] tlb_mat1 [15:0];
wire        tlb_d1   [15:0];
wire        tlb_v1   [15:0];

assign tlb_vppn[ 0] = 19'h1000;
assign tlb_vppn[ 1] = 19'h111;
assign tlb_vppn[ 2] = 19'h222;
assign tlb_vppn[ 3] = 19'h333;
assign tlb_vppn[ 4] = 19'h444;
assign tlb_vppn[ 5] = 19'h444;
assign tlb_vppn[ 6] = 19'h666;
assign tlb_vppn[ 7] = 19'h666;
assign tlb_vppn[ 8] = 19'h888;
assign tlb_vppn[ 9] = 19'h999;
assign tlb_vppn[10] = 19'haaa;
assign tlb_vppn[11] = 19'hbbb;
assign tlb_vppn[12] = 19'hccc;
assign tlb_vppn[13] = 19'hddd;
assign tlb_vppn[14] = 19'heee;
assign tlb_vppn[15] = 19'hf000;

assign tlb_e[ 0] = 1'b1;
assign tlb_e[ 1] = 1'b1;
assign tlb_e[ 2] = 1'b1;
assign tlb_e[ 3] = 1'b1;
assign tlb_e[ 4] = 1'b1;
assign tlb_e[ 5] = 1'b1;
assign tlb_e[ 6] = 1'b1;
assign tlb_e[ 7] = 1'b1;
assign tlb_e[ 8] = 1'b1;
assign tlb_e[ 9] = 1'b1;
assign tlb_e[10] = 1'b1;
assign tlb_e[11] = 1'b1;
assign tlb_e[12] = 1'b1;
assign tlb_e[13] = 1'b1;
assign tlb_e[14] = 1'b1;
assign tlb_e[15] = 1'b1;

assign tlb_ps[ 0] = 6'h15;
assign tlb_ps[ 1] = 6'hc;
assign tlb_ps[ 2] = 6'hc;
assign tlb_ps[ 3] = 6'hc;
assign tlb_ps[ 4] = 6'hc;
assign tlb_ps[ 5] = 6'hc;
assign tlb_ps[ 6] = 6'hc;
assign tlb_ps[ 7] = 6'hc;
assign tlb_ps[ 8] = 6'hc;
assign tlb_ps[ 9] = 6'hc;
assign tlb_ps[10] = 6'hc;
assign tlb_ps[11] = 6'hc;
assign tlb_ps[12] = 6'hc;
assign tlb_ps[13] = 6'hc;
assign tlb_ps[14] = 6'hc;
assign tlb_ps[15] = 6'h15;

assign tlb_asid[ 0] = 10'h0;
assign tlb_asid[ 1] = 10'h1;
assign tlb_asid[ 2] = 10'h2;
assign tlb_asid[ 3] = 10'h3;
assign tlb_asid[ 4] = 10'h4;
assign tlb_asid[ 5] = 10'h5;
assign tlb_asid[ 6] = 10'h6;
assign tlb_asid[ 7] = 10'h7;
assign tlb_asid[ 8] = 10'h8;
assign tlb_asid[ 9] = 10'h9;
assign tlb_asid[10] = 10'ha;
assign tlb_asid[11] = 10'hb;
assign tlb_asid[12] = 10'hc;
assign tlb_asid[13] = 10'hd;
assign tlb_asid[14] = 10'he;
assign tlb_asid[15] = 10'hf;

assign tlb_g[ 0] = 1'h0;
assign tlb_g[ 1] = 1'h1;
assign tlb_g[ 2] = 1'h0;
assign tlb_g[ 3] = 1'h1;
assign tlb_g[ 4] = 1'h0;
assign tlb_g[ 5] = 1'h0;
assign tlb_g[ 6] = 1'h0;
assign tlb_g[ 7] = 1'h0;
assign tlb_g[ 8] = 1'h0;
assign tlb_g[ 9] = 1'h0;
assign tlb_g[10] = 1'h0;
assign tlb_g[11] = 1'h0;
assign tlb_g[12] = 1'h0;
assign tlb_g[13] = 1'h0;
assign tlb_g[14] = 1'h0;
assign tlb_g[15] = 1'h0;

assign tlb_ppn0[ 0] = 20'h1000;
assign tlb_ppn0[ 1] = 20'h222;
assign tlb_ppn0[ 2] = 20'h333;
assign tlb_ppn0[ 3] = 20'h444;
assign tlb_ppn0[ 4] = 20'h555;
assign tlb_ppn0[ 5] = 20'h666;
assign tlb_ppn0[ 6] = 20'h777;
assign tlb_ppn0[ 7] = 20'h888;
assign tlb_ppn0[ 8] = 20'h999;
assign tlb_ppn0[ 9] = 20'haaa;
assign tlb_ppn0[10] = 20'hbbb;
assign tlb_ppn0[11] = 20'hccc;
assign tlb_ppn0[12] = 20'hddd;
assign tlb_ppn0[13] = 20'heee;
assign tlb_ppn0[14] = 20'hfff;
assign tlb_ppn0[15] = 20'h2000;

assign tlb_plv0[ 0] = 2'd0;
assign tlb_plv0[ 1] = 2'd0;
assign tlb_plv0[ 2] = 2'd0;
assign tlb_plv0[ 3] = 2'd0;
assign tlb_plv0[ 4] = 2'd0;
assign tlb_plv0[ 5] = 2'd0;
assign tlb_plv0[ 6] = 2'd0;
assign tlb_plv0[ 7] = 2'd0;
assign tlb_plv0[ 8] = 2'd0;
assign tlb_plv0[ 9] = 2'd0;
assign tlb_plv0[10] = 2'd0;
assign tlb_plv0[11] = 2'd0;
assign tlb_plv0[12] = 2'd0;
assign tlb_plv0[13] = 2'd0;
assign tlb_plv0[14] = 2'd0;
assign tlb_plv0[15] = 2'd0;

assign tlb_mat0[ 0] = 2'd1;
assign tlb_mat0[ 1] = 2'd1;
assign tlb_mat0[ 2] = 2'd1;
assign tlb_mat0[ 3] = 2'd1;
assign tlb_mat0[ 4] = 2'd1;
assign tlb_mat0[ 5] = 2'd1;
assign tlb_mat0[ 6] = 2'd1;
assign tlb_mat0[ 7] = 2'd1;
assign tlb_mat0[ 8] = 2'd1;
assign tlb_mat0[ 9] = 2'd1;
assign tlb_mat0[10] = 2'd1;
assign tlb_mat0[11] = 2'd1;
assign tlb_mat0[12] = 2'd1;
assign tlb_mat0[13] = 2'd1;
assign tlb_mat0[14] = 2'd1;
assign tlb_mat0[15] = 2'd1;

assign tlb_d0[ 0] = 1'h1;
assign tlb_d0[ 1] = 1'h1;
assign tlb_d0[ 2] = 1'h1;
assign tlb_d0[ 3] = 1'h1;
assign tlb_d0[ 4] = 1'h1;
assign tlb_d0[ 5] = 1'h1;
assign tlb_d0[ 6] = 1'h1;
assign tlb_d0[ 7] = 1'h1;
assign tlb_d0[ 8] = 1'h1;
assign tlb_d0[ 9] = 1'h1;
assign tlb_d0[10] = 1'h1;
assign tlb_d0[11] = 1'h1;
assign tlb_d0[12] = 1'h1;
assign tlb_d0[13] = 1'h1;
assign tlb_d0[14] = 1'h1;
assign tlb_d0[15] = 1'h1;

assign tlb_v0[ 0] = 1'h1;
assign tlb_v0[ 1] = 1'h1;
assign tlb_v0[ 2] = 1'h1;
assign tlb_v0[ 3] = 1'h1;
assign tlb_v0[ 4] = 1'h1;
assign tlb_v0[ 5] = 1'h1;
assign tlb_v0[ 6] = 1'h1;
assign tlb_v0[ 7] = 1'h1;
assign tlb_v0[ 8] = 1'h1;
assign tlb_v0[ 9] = 1'h1;
assign tlb_v0[10] = 1'h1;
assign tlb_v0[11] = 1'h1;
assign tlb_v0[12] = 1'h1;
assign tlb_v0[13] = 1'h1;
assign tlb_v0[14] = 1'h1;
assign tlb_v0[15] = 1'h1;

assign tlb_ppn1[ 0] = 20'h1100;
assign tlb_ppn1[ 1] = 20'h033;
assign tlb_ppn1[ 2] = 20'h044;
assign tlb_ppn1[ 3] = 20'h055;
assign tlb_ppn1[ 4] = 20'h066;
assign tlb_ppn1[ 5] = 20'h077;
assign tlb_ppn1[ 6] = 20'h088;
assign tlb_ppn1[ 7] = 20'h099;
assign tlb_ppn1[ 8] = 20'h0aa;
assign tlb_ppn1[ 9] = 20'h0bb;
assign tlb_ppn1[10] = 20'h0cc;
assign tlb_ppn1[11] = 20'h0dd;
assign tlb_ppn1[12] = 20'h0ee;
assign tlb_ppn1[13] = 20'h0ff;
assign tlb_ppn1[14] = 20'h000;
assign tlb_ppn1[15] = 20'h2100;

assign tlb_plv1[ 0] = 2'd0;
assign tlb_plv1[ 1] = 2'd0;
assign tlb_plv1[ 2] = 2'd0;
assign tlb_plv1[ 3] = 2'd0;
assign tlb_plv1[ 4] = 2'd0;
assign tlb_plv1[ 5] = 2'd0;
assign tlb_plv1[ 6] = 2'd0;
assign tlb_plv1[ 7] = 2'd0;
assign tlb_plv1[ 8] = 2'd0;
assign tlb_plv1[ 9] = 2'd0;
assign tlb_plv1[10] = 2'd0;
assign tlb_plv1[11] = 2'd0;
assign tlb_plv1[12] = 2'd0;
assign tlb_plv1[13] = 2'd0;
assign tlb_plv1[14] = 2'd0;
assign tlb_plv1[15] = 2'd0;

assign tlb_mat1[ 0] = 2'd1;
assign tlb_mat1[ 1] = 2'd1;
assign tlb_mat1[ 2] = 2'd1;
assign tlb_mat1[ 3] = 2'd1;
assign tlb_mat1[ 4] = 2'd1;
assign tlb_mat1[ 5] = 2'd1;
assign tlb_mat1[ 6] = 2'd1;
assign tlb_mat1[ 7] = 2'd1;
assign tlb_mat1[ 8] = 2'd1;
assign tlb_mat1[ 9] = 2'd1;
assign tlb_mat1[10] = 2'd1;
assign tlb_mat1[11] = 2'd1;
assign tlb_mat1[12] = 2'd1;
assign tlb_mat1[13] = 2'd1;
assign tlb_mat1[14] = 2'd1;
assign tlb_mat1[15] = 2'd1;

assign tlb_d1[ 0] = 1'h1;
assign tlb_d1[ 1] = 1'h1;
assign tlb_d1[ 2] = 1'h1;
assign tlb_d1[ 3] = 1'h1;
assign tlb_d1[ 4] = 1'h1;
assign tlb_d1[ 5] = 1'h1;
assign tlb_d1[ 6] = 1'h1;
assign tlb_d1[ 7] = 1'h1;
assign tlb_d1[ 8] = 1'h1;
assign tlb_d1[ 9] = 1'h1;
assign tlb_d1[10] = 1'h1;
assign tlb_d1[11] = 1'h1;
assign tlb_d1[12] = 1'h1;
assign tlb_d1[13] = 1'h1;
assign tlb_d1[14] = 1'h1;
assign tlb_d1[15] = 1'h1;

assign tlb_v1[ 0] = 1'h1;
assign tlb_v1[ 1] = 1'h1;
assign tlb_v1[ 2] = 1'h1;
assign tlb_v1[ 3] = 1'h1;
assign tlb_v1[ 4] = 1'h1;
assign tlb_v1[ 5] = 1'h1;
assign tlb_v1[ 6] = 1'h1;
assign tlb_v1[ 7] = 1'h1;
assign tlb_v1[ 8] = 1'h1;
assign tlb_v1[ 9] = 1'h1;
assign tlb_v1[10] = 1'h1;
assign tlb_v1[11] = 1'h1;
assign tlb_v1[12] = 1'h1;
assign tlb_v1[13] = 1'h1;
assign tlb_v1[14] = 1'h1;
assign tlb_v1[15] = 1'h1;

//search
// s_vppn  |  s_va_bit12  | s_asid  |  s_found  |  s_index  |  s_ppn  | s_ps | s_plv s_mat s_d s_v |
//  0x1000 |         0x1  |    0x0  |        1  |        0  |  0x1000 | 0x15 |     0,1,1,1         |
//  0x1100 |         0x0  |    0x0  |        1  |        0  |  0x1100 | 0x15 |     0,1,1,1         |
//  0x1000 |         0x1  |    0x1  |        0  |        x  |  0xxxx  |   x  |     x,x,x,x         |
//  0x111  |         0x1  |    0x0  |        1  |        1  |  0x033  | 0xc  |     0,1,1,1         |
//  0x111  |         0x0  |    0x1  |        1  |        1  |  0x222  | 0xc  |     0,1,1,1         |
//  0x222  |         0x0  |    0x0  |        0  |        x  |  0xxxx  |   x  |     x,x,x,x         |
//  0x222  |         0x0  |    0x2  |        1  |        2  |  0x333  | 0xc  |     0,1,1,1         |
//  0x333  |         0x0  |    0x3  |        1  |        3  |  0x444  | 0xc  |     0,1,1,1         |
//  0x333  |         0x1  |    0x4  |        1  |        3  |  0x055  | 0xc  |     0,1,1,1         |
//  0x444  |         0x0  |    0x4  |        1  |        4  |  0x555  | 0xc  |     0,1,1,1         |
//  0x444  |         0x0  |    0x5  |        1  |        5  |  0x666  | 0xc  |     0,1,1,1         |
//  0x555  |         0x1  |    0x5  |        0  |        x  |  0xxxx  |   x  |     x,x,x,x         |
//  0x666  |         0x0  |    0x6  |        1  |        6  |  0x777  | 0xc  |     0,1,1,1         |
//  0x666  |         0x1  |    0x7  |        1  |        7  |  0x099  | 0xc  |     0,1,1,1         |
//  0x666  |         0x1  |    0x8  |        0  |        x  |  0xxxx  |   x  |     x,x,x,x         |
//  0x777  |         0x0  |    0x7  |        0  |        x  |  0xxxx  |   x  |     x,x,x,x         |
//  0x888  |         0x0  |    0x8  |        1  |        8  |  0x999  | 0xc  |     0,1,1,1         |
//  0x999  |         0x1  |    0x9  |        1  |        9  |  0x0bb  | 0xc  |     0,1,1,1         |
//  0xaaa  |         0x0  |    0xa  |        1  |       10  |  0xbbb  | 0xc  |     0,1,1,1         |
//  0xbbb  |         0x1  |    0xb  |        1  |       11  |  0x0dd  | 0xc  |     0,1,1,1         |
//  0xccc  |         0x0  |    0xc  |        1  |       12  |  0xddd  | 0xc  |     0,1,1,1         |
//  0xddd  |         0x1  |    0xd  |        1  |       13  |  0x0ff  | 0xc  |     0,1,1,1         |
//  0xeee  |         0x0  |    0xe  |        1  |       14  |  0xfff  | 0xc  |     0,1,1,1         |
//  0xf000 |         0x0  |    0xf  |        1  |       15  |  0x2000 | 0x15 |     0,1,1,1         |
//  0xabc  |         0x0  |    0xf  |        0  |        x  |  0xxxx  |   x  |     x,x,x,x         |
//  0x123  |         0x1  |    0x3  |        0  |        x  |  0xxxx  |   x  |     x,x,x,x         |

wire [18:0] s_test_vppn    [25:0];
wire        s_test_va_bit12[25:0];
wire [ 9:0] s_test_asid    [25:0];
wire        s_test_found   [25:0];
wire [ 3:0] s_test_index   [25:0];
wire [19:0] s_test_ppn     [25:0];
wire [ 5:0] s_test_ps      [25:0];
wire [ 1:0] s_test_plv     [25:0];
wire [ 1:0] s_test_mat     [25:0];
wire        s_test_d       [25:0];
wire        s_test_v       [25:0];

assign s_test_vppn[ 0] = 19'h1000;
assign s_test_vppn[ 1] = 19'h1100;
assign s_test_vppn[ 2] = 19'h1000;
assign s_test_vppn[ 3] = 19'h111;
assign s_test_vppn[ 4] = 19'h111;
assign s_test_vppn[ 5] = 19'h222;
assign s_test_vppn[ 6] = 19'h222;
assign s_test_vppn[ 7] = 19'h333;
assign s_test_vppn[ 8] = 19'h333;
assign s_test_vppn[ 9] = 19'h444;
assign s_test_vppn[10] = 19'h444;
assign s_test_vppn[11] = 19'h555;
assign s_test_vppn[12] = 19'h666;
assign s_test_vppn[13] = 19'h666;
assign s_test_vppn[14] = 19'h666;
assign s_test_vppn[15] = 19'h777;
assign s_test_vppn[16] = 19'h888;
assign s_test_vppn[17] = 19'h999;
assign s_test_vppn[18] = 19'haaa;
assign s_test_vppn[19] = 19'hbbb;
assign s_test_vppn[20] = 19'hccc;
assign s_test_vppn[21] = 19'hddd;
assign s_test_vppn[22] = 19'heee;
assign s_test_vppn[23] = 19'hf000;
assign s_test_vppn[24] = 19'habc;
assign s_test_vppn[25] = 19'h123;

assign s_test_va_bit12[ 0] = 1'h1;
assign s_test_va_bit12[ 1] = 1'h0;
assign s_test_va_bit12[ 2] = 1'h1;
assign s_test_va_bit12[ 3] = 1'h1;
assign s_test_va_bit12[ 4] = 1'h0;
assign s_test_va_bit12[ 5] = 1'h0;
assign s_test_va_bit12[ 6] = 1'h0;
assign s_test_va_bit12[ 7] = 1'h0;
assign s_test_va_bit12[ 8] = 1'h1;
assign s_test_va_bit12[ 9] = 1'h0;
assign s_test_va_bit12[10] = 1'h0;
assign s_test_va_bit12[11] = 1'h1;
assign s_test_va_bit12[12] = 1'h0;
assign s_test_va_bit12[13] = 1'h1;
assign s_test_va_bit12[14] = 1'h1;
assign s_test_va_bit12[15] = 1'h0;
assign s_test_va_bit12[16] = 1'h0;
assign s_test_va_bit12[17] = 1'h1;
assign s_test_va_bit12[18] = 1'h0;
assign s_test_va_bit12[19] = 1'h1;
assign s_test_va_bit12[20] = 1'h0;
assign s_test_va_bit12[21] = 1'h1;
assign s_test_va_bit12[22] = 1'h0;
assign s_test_va_bit12[23] = 1'h0;
assign s_test_va_bit12[24] = 1'h0;
assign s_test_va_bit12[25] = 1'h1;

assign s_test_asid[ 0] = 10'h0;
assign s_test_asid[ 1] = 10'h0;
assign s_test_asid[ 2] = 10'h1;
assign s_test_asid[ 3] = 10'h0;
assign s_test_asid[ 4] = 10'h1;
assign s_test_asid[ 5] = 10'h0;
assign s_test_asid[ 6] = 10'h2;
assign s_test_asid[ 7] = 10'h3;
assign s_test_asid[ 8] = 10'h4;
assign s_test_asid[ 9] = 10'h4;
assign s_test_asid[10] = 10'h5;
assign s_test_asid[11] = 10'h5;
assign s_test_asid[12] = 10'h6;
assign s_test_asid[13] = 10'h7;
assign s_test_asid[14] = 10'h8;
assign s_test_asid[15] = 10'h7;
assign s_test_asid[16] = 10'h8;
assign s_test_asid[17] = 10'h9;
assign s_test_asid[18] = 10'ha;
assign s_test_asid[19] = 10'hb;
assign s_test_asid[20] = 10'hc;
assign s_test_asid[21] = 10'hd;
assign s_test_asid[22] = 10'he;
assign s_test_asid[23] = 10'hf;
assign s_test_asid[24] = 10'hf;
assign s_test_asid[25] = 10'h3;

assign s_test_found[ 0] = 1'h1;
assign s_test_found[ 1] = 1'h1;
assign s_test_found[ 2] = 1'h0;
assign s_test_found[ 3] = 1'h1;
assign s_test_found[ 4] = 1'h1;
assign s_test_found[ 5] = 1'h0;
assign s_test_found[ 6] = 1'h1;
assign s_test_found[ 7] = 1'h1;
assign s_test_found[ 8] = 1'h1;
assign s_test_found[ 9] = 1'h1;
assign s_test_found[10] = 1'h1;
assign s_test_found[11] = 1'h0;
assign s_test_found[12] = 1'h1;
assign s_test_found[13] = 1'h1;
assign s_test_found[14] = 1'h0;
assign s_test_found[15] = 1'h0;
assign s_test_found[16] = 1'h1;
assign s_test_found[17] = 1'h1;
assign s_test_found[18] = 1'h1;
assign s_test_found[19] = 1'h1;
assign s_test_found[20] = 1'h1;
assign s_test_found[21] = 1'h1;
assign s_test_found[22] = 1'h1;
assign s_test_found[23] = 1'h1;
assign s_test_found[24] = 1'h0;
assign s_test_found[25] = 1'h0;

assign s_test_index[ 0] = 4'h0;
assign s_test_index[ 1] = 4'h0;
assign s_test_index[ 2] = 4'hx;
assign s_test_index[ 3] = 4'h1;
assign s_test_index[ 4] = 4'h1;
assign s_test_index[ 5] = 4'hx;
assign s_test_index[ 6] = 4'h2;
assign s_test_index[ 7] = 4'h3;
assign s_test_index[ 8] = 4'h3;
assign s_test_index[ 9] = 4'h4;
assign s_test_index[10] = 4'h5;
assign s_test_index[11] = 4'hx;
assign s_test_index[12] = 4'h6;
assign s_test_index[13] = 4'h7;
assign s_test_index[14] = 4'hx;
assign s_test_index[15] = 4'hx;
assign s_test_index[16] = 4'h8;
assign s_test_index[17] = 4'h9;
assign s_test_index[18] = 4'ha;
assign s_test_index[19] = 4'hb;
assign s_test_index[20] = 4'hc;
assign s_test_index[21] = 4'hd;
assign s_test_index[22] = 4'he;
assign s_test_index[23] = 4'hf;
assign s_test_index[24] = 4'hx;
assign s_test_index[25] = 4'hx;

assign s_test_ppn[ 0] = 20'h1000;
assign s_test_ppn[ 1] = 20'h1100;
assign s_test_ppn[ 2] = 20'hxxx;
assign s_test_ppn[ 3] = 20'h033;
assign s_test_ppn[ 4] = 20'h222;
assign s_test_ppn[ 5] = 20'hxxx;
assign s_test_ppn[ 6] = 20'h333;
assign s_test_ppn[ 7] = 20'h444;
assign s_test_ppn[ 8] = 20'h055;
assign s_test_ppn[ 9] = 20'h555;
assign s_test_ppn[10] = 20'h666;
assign s_test_ppn[11] = 20'hxxx;
assign s_test_ppn[12] = 20'h777;
assign s_test_ppn[13] = 20'h099;
assign s_test_ppn[14] = 20'hxxx;
assign s_test_ppn[15] = 20'hxxx;
assign s_test_ppn[16] = 20'h999;
assign s_test_ppn[17] = 20'h0bb;
assign s_test_ppn[18] = 20'hbbb;
assign s_test_ppn[19] = 20'h0dd;
assign s_test_ppn[20] = 20'hddd;
assign s_test_ppn[21] = 20'h0ff;
assign s_test_ppn[22] = 20'hfff;
assign s_test_ppn[23] = 20'h2000;
assign s_test_ppn[24] = 20'hxxx;
assign s_test_ppn[25] = 20'hxxx;

assign s_test_ps[ 0] = 14'h15;
assign s_test_ps[ 1] = 14'h15;
assign s_test_ps[ 2] = 14'hx;
assign s_test_ps[ 3] = 14'hc;
assign s_test_ps[ 4] = 14'hc;
assign s_test_ps[ 5] = 14'hx;
assign s_test_ps[ 6] = 14'hc;
assign s_test_ps[ 7] = 14'hc;
assign s_test_ps[ 8] = 14'hc;
assign s_test_ps[ 9] = 14'hc;
assign s_test_ps[10] = 14'hc;
assign s_test_ps[11] = 14'hx;
assign s_test_ps[12] = 14'hc;
assign s_test_ps[13] = 14'hc;
assign s_test_ps[14] = 14'hx;
assign s_test_ps[15] = 14'hx;
assign s_test_ps[16] = 14'hc;
assign s_test_ps[17] = 14'hc;
assign s_test_ps[18] = 14'hc;
assign s_test_ps[19] = 14'hc;
assign s_test_ps[20] = 14'hc;
assign s_test_ps[21] = 14'hc;
assign s_test_ps[22] = 14'hc;
assign s_test_ps[23] = 14'h15;
assign s_test_ps[24] = 14'hx;
assign s_test_ps[25] = 14'hx;

assign s_test_plv[ 0] = 2'h0;
assign s_test_plv[ 1] = 2'h0;
assign s_test_plv[ 2] = 2'hx;
assign s_test_plv[ 3] = 2'h0;
assign s_test_plv[ 4] = 2'h0;
assign s_test_plv[ 5] = 2'hx;
assign s_test_plv[ 6] = 2'h0;
assign s_test_plv[ 7] = 2'h0;
assign s_test_plv[ 8] = 2'h0;
assign s_test_plv[ 9] = 2'h0;
assign s_test_plv[10] = 2'h0;
assign s_test_plv[11] = 2'hx;
assign s_test_plv[12] = 2'h0;
assign s_test_plv[13] = 2'h0;
assign s_test_plv[14] = 2'hx;
assign s_test_plv[15] = 2'hx;
assign s_test_plv[16] = 2'h0;
assign s_test_plv[17] = 2'h0;
assign s_test_plv[18] = 2'h0;
assign s_test_plv[19] = 2'h0;
assign s_test_plv[20] = 2'h0;
assign s_test_plv[21] = 2'h0;
assign s_test_plv[22] = 2'h0;
assign s_test_plv[23] = 2'h0;
assign s_test_plv[24] = 2'hx;
assign s_test_plv[25] = 2'hx;

assign s_test_mat[ 0] = 2'h1;
assign s_test_mat[ 1] = 2'h1;
assign s_test_mat[ 2] = 2'hx;
assign s_test_mat[ 3] = 2'h1;
assign s_test_mat[ 4] = 2'h1;
assign s_test_mat[ 5] = 2'hx;
assign s_test_mat[ 6] = 2'h1;
assign s_test_mat[ 7] = 2'h1;
assign s_test_mat[ 8] = 2'h1;
assign s_test_mat[ 9] = 2'h1;
assign s_test_mat[10] = 2'h1;
assign s_test_mat[11] = 2'hx;
assign s_test_mat[12] = 2'h1;
assign s_test_mat[13] = 2'h1;
assign s_test_mat[14] = 2'hx;
assign s_test_mat[15] = 2'hx;
assign s_test_mat[16] = 2'h1;
assign s_test_mat[17] = 2'h1;
assign s_test_mat[18] = 2'h1;
assign s_test_mat[19] = 2'h1;
assign s_test_mat[20] = 2'h1;
assign s_test_mat[21] = 2'h1;
assign s_test_mat[22] = 2'h1;
assign s_test_mat[23] = 2'h1;
assign s_test_mat[24] = 2'hx;
assign s_test_mat[25] = 2'hx;

assign s_test_d[ 0] = 3'h1;
assign s_test_d[ 1] = 3'h1;
assign s_test_d[ 2] = 3'hx;
assign s_test_d[ 3] = 3'h1;
assign s_test_d[ 4] = 3'h1;
assign s_test_d[ 5] = 3'hx;
assign s_test_d[ 6] = 3'h1;
assign s_test_d[ 7] = 3'h1;
assign s_test_d[ 8] = 3'h1;
assign s_test_d[ 9] = 3'h1;
assign s_test_d[10] = 3'h1;
assign s_test_d[11] = 3'hx;
assign s_test_d[12] = 3'h1;
assign s_test_d[13] = 3'h1;
assign s_test_d[14] = 3'hx;
assign s_test_d[15] = 3'hx;
assign s_test_d[16] = 3'h1;
assign s_test_d[17] = 3'h1;
assign s_test_d[18] = 3'h1;
assign s_test_d[19] = 3'h1;
assign s_test_d[20] = 3'h1;
assign s_test_d[21] = 3'h1;
assign s_test_d[22] = 3'h1;
assign s_test_d[23] = 3'h1;
assign s_test_d[24] = 3'hx;
assign s_test_d[25] = 3'hx;

assign s_test_v[ 0] = 3'h1;
assign s_test_v[ 1] = 3'h1;
assign s_test_v[ 2] = 3'hx;
assign s_test_v[ 3] = 3'h1;
assign s_test_v[ 4] = 3'h1;
assign s_test_v[ 5] = 3'hx;
assign s_test_v[ 6] = 3'h1;
assign s_test_v[ 7] = 3'h1;
assign s_test_v[ 8] = 3'h1;
assign s_test_v[ 9] = 3'h1;
assign s_test_v[10] = 3'h1;
assign s_test_v[11] = 3'hx;
assign s_test_v[12] = 3'h1;
assign s_test_v[13] = 3'h1;
assign s_test_v[14] = 3'hx;
assign s_test_v[15] = 3'hx;
assign s_test_v[16] = 3'h1;
assign s_test_v[17] = 3'h1;
assign s_test_v[18] = 3'h1;
assign s_test_v[19] = 3'h1;
assign s_test_v[20] = 3'h1;
assign s_test_v[21] = 3'h1;
assign s_test_v[22] = 3'h1;
assign s_test_v[23] = 3'h1;
assign s_test_v[24] = 3'hx;
assign s_test_v[25] = 3'hx;
// write
always @(posedge clk_g) begin
    if(~resetn) begin
        tlb_w_test_ok <= 1'b0;
        tlb_w_cnt <= 4'b0;
    end
    else if(tlb_w_cnt==4'hf) begin
        tlb_w_test_ok <= 1'b1;
    end
    else if(~tlb_w_test_ok && wait_1s) begin
        tlb_w_cnt <= tlb_w_cnt + 1;
    end
end

// read
always @(posedge clk_g) begin
    if(~resetn) begin
        tlb_r_test_ok <= 1'b0;
        tlb_r_cnt <= 4'b0;
    end
    else if(tlb_r_cnt==4'hf && ~r_error) begin
        tlb_r_test_ok <= 1'b1;
    end
    else if(tlb_w_test_ok && ~tlb_r_test_ok && ~test_error && ~r_error && wait_1s) begin
        tlb_r_cnt <= tlb_r_cnt + 1;
    end
end

// search
always @(posedge clk_g) begin
    if(~resetn) begin
        tlb_s_test_ok <= 1'b0;
        tlb_s_cnt <= 4'b0;
    end
    else if(tlb_s_cnt==4'hc && ~s0_error && ~s1_error) begin
        tlb_s_test_ok <= 1'b1;
    end
    else if(tlb_w_test_ok && ~tlb_s_test_ok && ~test_error && ~s0_error && ~s1_error && wait_1s) begin
        tlb_s_cnt <= tlb_s_cnt + 1;
    end
end

assign we      =~tlb_w_test_ok;
assign w_index = tlb_w_cnt;
assign w_e     = tlb_e   [tlb_w_cnt];
assign w_ps    = tlb_ps  [tlb_w_cnt];
assign w_vppn  = tlb_vppn[tlb_w_cnt];
assign w_asid  = tlb_asid[tlb_w_cnt];
assign w_g     = tlb_g   [tlb_w_cnt];
assign w_ppn0  = tlb_ppn0[tlb_w_cnt];
assign w_plv0  = tlb_plv0[tlb_w_cnt];
assign w_mat0  = tlb_mat0[tlb_w_cnt];
assign w_d0    = tlb_d0  [tlb_w_cnt];
assign w_v0    = tlb_v0  [tlb_w_cnt];
assign w_ppn1  = tlb_ppn1[tlb_w_cnt];
assign w_plv1  = tlb_plv1[tlb_w_cnt];
assign w_mat1  = tlb_mat1[tlb_w_cnt];
assign w_d1    = tlb_d1  [tlb_w_cnt];
assign w_v1    = tlb_v1  [tlb_w_cnt];

assign r_index = tlb_r_cnt;
assign r_error = (r_e    != tlb_e   [tlb_r_cnt])
               | (r_vppn != tlb_vppn[tlb_r_cnt])
               | (r_ps   != tlb_ps  [tlb_r_cnt])
               | (r_asid != tlb_asid[tlb_r_cnt])
               | (r_g    != tlb_g   [tlb_r_cnt])
               | (r_ppn0 != tlb_ppn0[tlb_r_cnt])
               | (r_plv0 != tlb_plv0[tlb_r_cnt])
               | (r_mat0 != tlb_mat0[tlb_r_cnt])
               | (r_d0   != tlb_d0  [tlb_r_cnt])
               | (r_v0   != tlb_v0  [tlb_r_cnt])
               | (r_ppn1 != tlb_ppn1[tlb_r_cnt])
               | (r_plv1 != tlb_plv1[tlb_r_cnt])
               | (r_mat1 != tlb_mat1[tlb_r_cnt])
               | (r_d1   != tlb_d1  [tlb_r_cnt])
               | (r_v1   != tlb_v1  [tlb_r_cnt]);

wire [4:0] s0_test_id,s1_test_id;
assign s0_test_id = {tlb_s_cnt,1'b0};
assign s1_test_id = {tlb_s_cnt,1'b1};

assign s0_vppn     = s_test_vppn    [s0_test_id];
assign s0_va_bit12 = s_test_va_bit12[s0_test_id];
assign s0_asid     = s_test_asid    [s0_test_id];
assign s1_vppn     = s_test_vppn    [s1_test_id];
assign s1_va_bit12 = s_test_va_bit12[s1_test_id];
assign s1_asid     = s_test_asid    [s1_test_id];

assign s0_error = (s_test_found[s0_test_id] ^ s0_found) || (s_test_found[s0_test_id] &&
                  ( ~s0_found ||
                    (s0_ppn != s_test_ppn[s0_test_id]) ||
                    (s0_ps  != s_test_ps [s0_test_id]) ||
                    (s0_plv != s_test_plv[s0_test_id]) ||
                    (s0_mat != s_test_mat[s0_test_id]) ||
                    (s0_d   != s_test_d  [s0_test_id]) ||
                    (s0_v   != s_test_v  [s0_test_id]) )
                  );
                   
assign s1_error = (s_test_found[s1_test_id] ^ s1_found) || (s_test_found[s1_test_id] &&
                  ( ~s1_found ||
                    (s1_ppn != s_test_ppn[s1_test_id]) ||
                    (s1_ps  != s_test_ps [s1_test_id]) ||
                    (s1_plv != s_test_plv[s1_test_id]) ||
                    (s1_mat != s_test_mat[s1_test_id]) ||
                    (s1_d   != s_test_d  [s1_test_id]) ||
                    (s1_v   != s_test_v  [s1_test_id]) )
                  );
                   
always @(posedge clk_g) begin
    if(~resetn) begin
        test_error <= 1'b0;
    end
    else if(tlb_w_test_ok && ~tlb_r_test_ok && r_error) begin
        test_error <= 1'b1;
    end
    else if(tlb_w_test_ok && ~tlb_s_test_ok && (s0_error || s1_error)) begin
        test_error <= 1'b1;
    end
end

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
always @ ( posedge clk_g )  
begin
    if ( !resetn )
    begin
        scan_data <= 32'd0;  
        num_csn   <= 8'b1111_1111;
    end
    else
    begin
        case(count[19:17])
            3'b000 : scan_data <= {3'b0,s1_test_id[4]};
            3'b001 : scan_data <= s1_test_id[3:0];
            3'b010 : scan_data <= {3'b0,s0_test_id[4]};
            3'b011 : scan_data <= s0_test_id[3:0];
            3'b100 : scan_data <= 4'b0;
            3'b101 : scan_data <= tlb_r_cnt;
            3'b110 : scan_data <= 4'b0;
            3'b111 : scan_data <= tlb_w_cnt;
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

assign led = {~test_error,12'hfff,~tlb_w_test_ok,~tlb_r_test_ok,~tlb_s_test_ok};

endmodule
