package pkg_sha3;

  //  configuration parameter
  parameter  SHA3_DIGEST_SIZE  =  256;  //  value can be either 256, 384 or 512

  //  fixed parameters
  parameter  SHA3_BRAM_DW      =  64;
  parameter  NUM_PLANE         =  5;
  parameter  NUM_SHEET         =  5;
  parameter  LOG_D             =  4;
  parameter  N                 =  SHA3_BRAM_DW;

  //  derived parameters
  parameter  SHA3_CAPACITY     =  2 * SHA3_DIGEST_SIZE;
  parameter  SHA3_RATE         =  1600 - SHA3_CAPACITY;
  parameter  SHA3_RATE_LINES   =  ((SHA3_RATE - 1) / SHA3_BRAM_DW) + 1;
  parameter  SHA3_DIGEST_LINES =  (SHA3_DIGEST_SIZE/SHA3_BRAM_DW);

  //  type definitions
  typedef  logic    [N-1:0]           k_lane;
  typedef  k_lane   [NUM_SHEET-1:0]   k_plane;
  typedef  k_plane  [NUM_PLANE-1:0]   k_state;

  //  helper function
  function int ABS (input int numberIn);
    ABS  =  (numberIn < 0) ? -numberIn : numberIn;
  endfunction

//////////////////////////////////////////////////////////
//      enum defining opcodes            //
//////////////////////////////////////////////////////////

  typedef  enum  logic  [1:0]
  {
    OPCODE_SHA3_IDLE        =  'd0,
    OPCODE_SHA3_START       =  'd1,
    OPCODE_SHA3_IN_MSG      =  'd2,
    OPCODE_SHA3_OUT_HASH    =  'd3
  }  opCodeSha3_t;

//////////////////////////////////////////////////////////
//      enum defining states            //
//////////////////////////////////////////////////////////

  typedef enum logic  [2:0]
  {
    SS_SHA3_IDLE            =  'd0,
    SS_SHA3_GET_MSG_1       =  'd1,
    SS_SHA3_GET_MSG_2       =  'd2,
    SS_SHA3_GET_MSG_3       =  'd3,
    SS_SHA3_PUT_HASH_1      =  'd4,
    SS_SHA3_PUT_HASH_2      =  'd5,
    SS_SHA3_PUT_HASH_3      =  'd6,
    SS_SHA3_ACK             =  'd7
  }  ssSha3_t;

endpackage
