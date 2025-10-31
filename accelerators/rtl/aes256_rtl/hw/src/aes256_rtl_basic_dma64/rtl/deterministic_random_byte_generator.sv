module deterministic_random_byte_generator #(
    OUTPUT_BLOCKS   =   512
)(
    input               clk,
    input               reset_n,
    drbg_if.drbg        drbg_if
);

    localparam  AES_KEY_LENGTH      =   256;
    localparam  AES_BLOCK_LENGTH    =   128;
    localparam  PAD_CNT_SIZE        =   $clog2(OUTPUT_BLOCKS);

    localparam  KEY_XOR_CONSTANT    =   256'h530f8afbc74536b9a963b4f1c4cb738bcea7403d4d606b6e074ec5d3baf39d18;
    localparam  V_XOR_CONSTANT      =   128'h726003ca37a62a74d1a2f58e7506358e;

    enum    logic   [2:0]       {
                                    IDLE,
                                    INIT_WAIT_READY,
                                    INIT_START,
                                    INIT_WAIT_DONE,
                                    COMP_START,
                                    COMP_WAIT_DONE
                                }   ss, ss_next;

    logic                           ready_o_next;
    logic [AES_BLOCK_LENGTH - 1:0]  data_o_next;
    logic                           valid_o_next;

    logic                           init, init_next;
    logic                           next, next_next;
    logic                           ready;
    logic [AES_KEY_LENGTH - 1:0]    key, key_next;
    logic [AES_BLOCK_LENGTH - 1:0]  v, v_next;
    logic [AES_BLOCK_LENGTH - 1:0]  result;
    logic                           valid;

    logic [PAD_CNT_SIZE - 1:0]      pad_cnt, pad_cnt_next;

    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            ss                  <=  IDLE;
            init                <=  1'b0;
            next                <=  1'b0;
            key                 <=  {AES_KEY_LENGTH{1'b0}};
            v                   <=  {AES_BLOCK_LENGTH{1'b0}};
            pad_cnt             <=  {PAD_CNT_SIZE{1'b0}};
            drbg_if.ready       <=  1'b1;
            drbg_if.out         <=  {AES_BLOCK_LENGTH{1'b0}};
            drbg_if.valid       <=  1'b0;
        end
        else
        begin
            ss                  <=  ss_next;
            init                <=  init_next;
            next                <=  next_next;
            key                 <=  key_next;
            v                   <=  v_next;
            pad_cnt             <=  pad_cnt_next;
            drbg_if.ready       <=  ready_o_next;
            drbg_if.out         <=  data_o_next;
            drbg_if.valid       <=  valid_o_next;
        end
    end

    always_comb
    begin
        ss_next         =   ss;
        init_next       =   1'b0;
        next_next       =   1'b0;
        key_next        =   key;
        v_next          =   v;
        pad_cnt_next    =   pad_cnt;
        ready_o_next    =   drbg_if.ready;
        data_o_next     =   drbg_if.out;
        valid_o_next    =   1'b0;
        unique case (ss)
            IDLE:
            begin
                if (drbg_if.start)
                begin
                    ss_next             =   INIT_WAIT_READY;
                    ready_o_next        =   1'b0;
                end
            end
            INIT_WAIT_READY:
            begin
                if (ready)
                begin
                    ss_next             =   INIT_START;
                    init_next           =   1'b1;
                    key_next            =   drbg_if.seed[383:128] ^ KEY_XOR_CONSTANT;
                    v_next              =   drbg_if.seed[127:0]   ^ V_XOR_CONSTANT;
                end
            end
            INIT_START:
            begin
                if (~ready)
                begin
                    ss_next             =   INIT_WAIT_DONE;
                end
            end
            INIT_WAIT_DONE:
            begin
                if (ready)
                begin
                    ss_next             =   COMP_START;
                    next_next           =   1'b1;
                    v_next              =   v + 1;
                end
            end
            COMP_START:
            begin
                if (~ready)
                begin
                    ss_next             =   COMP_WAIT_DONE;
                end
            end
            COMP_WAIT_DONE:
            begin
                if (ready)
                begin
                    data_o_next         =   result;
                    valid_o_next        =   1'b1;
                    if (pad_cnt < OUTPUT_BLOCKS - 1)
                    begin
                        ss_next         =   COMP_START;
                        next_next       =   1'b1;
                        v_next          =   v + 1;
                        pad_cnt_next    =   pad_cnt + 1;
                    end
                    else
                    begin
                        ss_next         =   IDLE;
                        key_next        =   {AES_KEY_LENGTH{1'b0}};
                        v_next          =   {AES_BLOCK_LENGTH{1'b0}};
                        pad_cnt_next    =   {PAD_CNT_SIZE{1'b0}};
                        ready_o_next    =   1'b1;
                    end
                end
            end
            default:
            begin
            end
        endcase
    end

    aes_core core(
        .clk(clk),
        .reset_n(reset_n),
        .init(init),
        .next(next),
        .ready(ready),
        .key(key),
        .block(v),
        .result(result),
        .result_valid(valid)
    );

endmodule
