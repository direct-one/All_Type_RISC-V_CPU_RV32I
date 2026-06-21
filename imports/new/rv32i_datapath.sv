`timescale 1ns / 1ps
`include "define.vh"


module rv32i_datapath(
        input   logic           clk,
        input   logic           rst,
        input   logic           rf_we,
        input                   alu_src,
        input   logic  [ 3:0]   alu_control,
        input   logic  [31:0]   instr_data,
        input          [31:0]   drdata,
        input          [2:0]    rfwd_src,
        input                   branch,
        input                   jalr_srcsel,
        input                   jal_srcsel,
        output  logic   [31:0]  instr_addr,
        output          [31:0]  daddr,
        output          [31:0]  dwdata


    );

    logic [31:0] rd1, rd2,alu_result,imm_data, alurs2_data, pc_imm_out, pc_4_out;
    logic [31:0] rfwd_data, o_rs1_pc;
    logic btaken;

    assign daddr = alu_result;
    assign dwdata = rd2;


 program_counter U_PC (
    .clk(clk),
    .rst(rst),
    .btaken(btaken),
    .branch(branch),
    .jal_srcsel(jal_srcsel),
    .jalr_srcsel(jalr_srcsel),
    .imm_data(imm_data),
    .program_counter(instr_addr),
    .pc_imm_out(pc_imm_out),
    .pc_4_out(pc_4_out)
);




    register_file U_REG_FILE (
    .clk(clk),
    .rst(rst),
    .RA1(instr_data[19:15]),
    .RA2(instr_data[24:20]),
    .WA(instr_data[11:7]),
    .Wdata(rfwd_data),
    .rf_we(rf_we),
    .RD1(rd1),
    .RD2(rd2)
);


 imm_extender U_IMM_EXTENDER (
    .instr_data(instr_data) ,
    .imm_data(imm_data)
);


 mux_2x1 U_MUX_ALUSRC_RS2 (
    .in0(rd2), //sel 0
    .in1(imm_data), //sel 1
    .mux_sel(alu_src), 
    .out_mux(alurs2_data)
);

    alu U_ALU (
    .rd1(rd1),
    .rd2(alurs2_data),
    .alu_control(alu_control), 
    .alu_result(alu_result),
    .btaken(btaken) 
);

// change mux 5x1
 mux_5x1 U_WB_MUX (
    .in0(alu_result), //sel 0
    .in1(drdata), //sel 1
    .in2(pc_imm_out), //010
    .in3(imm_data), //011
    .in4(pc_4_out), //100
    .mux_sel(rfwd_src), 
    .o_mux_5x1(rfwd_data)
);



endmodule


module mux_5x1 (
    input  logic [31:0]  in0, //000
    input  logic [31:0]  in1, //001
    input  logic [31:0]  in2, //010
    input  logic [31:0]  in3, //011
    input  logic [31:0]  in4, //100
    input  logic [2:0]   mux_sel,
    output logic [31:0]  o_mux_5x1
);

    always_comb begin 
        o_mux_5x1 = 32'd0;
        case (mux_sel)
            3'b000: o_mux_5x1 = in0;
            3'b001: o_mux_5x1 = in1;
            3'b010: o_mux_5x1 = in2;
            3'b011: o_mux_5x1 = in3;
            3'b100: o_mux_5x1 = in4; 
             
        endcase
        
    end
    
endmodule




module mux_2x1 (
    input [31:0] in0, //sel 0
    input [31:0] in1, //sel 1
    input        mux_sel, 
    output logic [31:0] out_mux
);

    assign out_mux = (mux_sel) ? in1:in0;
    
    
endmodule




//imm_extender
module imm_extender (
    input        [31:0] instr_data,
    output logic [31:0] imm_data
);

        always_comb begin 
            imm_data = 32'd0;
            case (instr_data[6:0])
               `S_TYPE: begin
                imm_data = {{20{instr_data[31]}},instr_data[31:25],instr_data[11:7]
                };
               end 
                `I_TYPE, `IL_TYPE: begin
                imm_data = {{20{instr_data[31]}},instr_data[31:20]};
                 end
                 `B_TYPE:begin
                    imm_data = {
                        {19{instr_data[31]}},
                        instr_data[31],  //imm bit 11
                        instr_data[7],  //imm bit 10:5
                        instr_data[30:25], 
                        instr_data[11:8],
                        1'b0
                    };
                 end
                `LUI_TYPE, `AUIPC_TYPE:begin
                    imm_data = {instr_data[31:12],12'd0};
                end 
                `JAL_TYPE:begin
                    imm_data = {
                        {12{instr_data[31]}},
                        instr_data[20],     //1bit  
                        instr_data[19:12], // 8bit     
                        instr_data[10:1], //10bit 
                        1'b0              //1bit
                    };
                end


            endcase    

        end
    
endmodule


module register_file (
    input        clk,
    input        rst,
    input  [4:0] RA1,  // instruction code RS1
    input  [4:0] RA2,  // instruction code RS2
    input  [4:0] WA,   // instruction code RD
    input [31:0] Wdata,     //instruction RD wirte data
    input        rf_we,     // Register File wirte enable
    output [31:0] RD1,      //Register File RS1 ouput 
    output [31:0] RD2       //Register File RS2 output 
);

    logic [31:0] reg_file [0:31];

`ifdef SIMULATION
    initial begin
        for(int i =0; i<32; i++)begin
            reg_file [i] = i;
        end
        
    end
`endif


    always_ff @( posedge clk) begin 
            if(!rst & rf_we)begin
                reg_file[WA] <= Wdata;    
            
            end
        end


    //output CL

    assign RD1 = (RA1 != 0) ?  reg_file[RA1]:0;
    assign RD2 = (RA2 != 0) ?  reg_file[RA2]:0;
    
    
endmodule



module alu (
    input   logic [31:0] rd1,   //RS1  //$signed --> assign signed 
    input   logic [31:0] rd2,   //RS2
    input   logic [3:0]  alu_control,  //function7 [6],funct3 : 4bit   
    output  logic [31:0] alu_result,  //alu_result 
    output  logic        btaken 
);


    //R-TYPE 
    always_comb begin 
        alu_result = 0;
        case (alu_control)
                `ADD:  alu_result = rd1 + rd2;  //add rd  = rs1 + rs2
                `SUB:  alu_result = rd1 - rd2; //sub rd = rs1 - rs2
                `SLL:  alu_result = rd1 << rd2 [4:0]; // SLL rd = rs1 << rs2
                `SLT:  alu_result = ($signed(rd1) < $signed(rd2)) ? 1:0; // slt rd = (rs1 < rs2) ? 1:0 //zero extend
                `SLTU: alu_result = (rd1 < rd2) ? 1 : 0; //slt_u rd = rs1 - rs2
                `XOR:  alu_result = rd1 ^ rd2; //xor rd = rs1 ^ rs2
                `SRL:  alu_result = rd1 >> rd2[4:0]; //SRL rd = rs1 >> rs2
                `SRA:  alu_result = $signed(rd1) >>> rd2[4:0]; //SRA rd = rs1 >> rs2, msb_extention, arithmetic right shift 
                `OR:   alu_result = rd1 | rd2; //or rd = rs1 | rs2
                `AND:  alu_result = rd1 & rd2; //and rd = rs1 & rs2
        endcase
    end

    //B-Type
    always_comb begin 
        btaken = 0;
        case (alu_control)
                `BEQ:begin 
                if(rd1 == rd2) btaken = 1; //true: pc = pc +IMM
                else btaken = 0;           //false : pc = pc +4
                end 
                `BNE:begin
                    if(rd1!=rd2) btaken =1;  //true : pc = pc+IMM 
                    else btaken =0; //false :pc= pc +4
                end
                `BLT:begin
                    if(($signed(rd1))<($signed(rd2))) btaken =1;  //true : pc = pc+IMM 
                    else btaken =0; //false :pc= pc +4
                end
                `BGE:begin
                    if(($signed(rd1))>=($signed(rd2))) btaken =1;  //true : pc = pc+IMM 
                    else btaken =0; //false :pc= pc +4
                end
                `BLTU:begin
                    if(rd1<rd2) btaken =1;  //true : pc = pc+IMM  //zero extend 
                    else btaken =0; //false :pc= pc +4
                end
                `BGEU:begin
                    if(rd1>=rd2) btaken =1;  //true : pc = pc+IMM  //zero extend
                    else btaken =0; //false :pc= pc +4
                end

                
        endcase
    end

endmodule

module program_counter (
    input               clk,
    input               rst,
    input               btaken, //from alu btype 
    input               branch,
    input               jal_srcsel,
    input               jalr_srcsel,
    input        [31:0] rd1,
    input        [31:0] imm_data,
    output logic [31:0] program_counter,
    output logic [31:0] pc_imm_out,
    output logic [31:0] pc_4_out
    
);

logic [31:0] pc_next, o_rs1_pc;

 pc_alu U_PC_IMM (
    .a(imm_data),
    .b(o_rs1_pc), 
    .pc_alu_out(pc_imm_out) 
);
pc_alu U_PC_4 (
    .a(32'd4),
    .b(program_counter), 
    .pc_alu_out(pc_4_out) 
);
//for JAIR
 mux_2x1 U_RS1_PC (
    .in0(rd1), //sel 0
    .in1(program_counter), //sel 1
    .mux_sel(jalr_srcsel), 
    .out_mux(o_rs1_pc)
);


 

 mux_2x1 U_PC_NEXT_MUX(
    .in0(pc_4_out), //sel 0
    .in1(pc_imm_out), //sel 1
    .mux_sel( jal_srcsel | (btaken & branch)), 
    .out_mux(pc_next)
);


 register U_PC_REG (
    .clk(clk), 
    .rst(rst),
    .data_in(pc_next),
    .data_out(program_counter)
);

    
endmodule


module pc_alu (
    input [31:0] a,
    input [31:0] b, 
    output [31:0] pc_alu_out 
);

assign pc_alu_out = a+b;
    
endmodule


module register (
    input clk, 
    input rst,
    input [31:0] data_in,
    output [31:0] data_out
);

logic [31:0] reg_f;

always_ff @( posedge clk, posedge rst ) begin 
    if (rst) begin
        reg_f <= 0;
    end else begin
        reg_f <= data_in;
    end
end

assign data_out = reg_f;
    
endmodule

