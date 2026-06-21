`timescale 1ns / 1ps
`include "define.vh"

module rv32i_cpu(
    input logic        clk,
    input logic        rst,
    input logic [31:0] instr_data,
    input logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output  [2:0]       o_funct3,
    output              dwe,
    output [31:0]       daddr,
    output [31:0]       dwdata
    );

    logic rf_we,alu_src,branch, jalr_srcsel, jal_srcsel;
    logic [31:0] alu_result;
    logic [3:0] alu_control;
    logic [2:0] rfwd_src;


     control_unit U_CONTROL_UNIT(
    .funct7(instr_data[31:25]),
    .funct3(instr_data[14:12]),
    .opcode(instr_data[6:0]),
    .alu_src(alu_src),
    .rf_we(rf_we),
    .branch(branch),
    .jalr_srcsel(jalr_srcsel),
    .jal_srcsel(jal_srcsel),
    .rfwd_src(rfwd_src),
    .alu_control(alu_control),
    .o_funct3(o_funct3),
    .dwe(dwe)
);

 rv32i_datapath U_DATAPATH(
        .*
    );

endmodule


module control_unit(
    //input rst,
    input  logic [6:0] funct7,
    input  logic [2:0] funct3,
    input  logic [6:0] opcode,
    output logic       alu_src,
    output logic       rf_we,
    output logic       branch, //for B-type  
    output logic       jalr_srcsel,
    output logic       jal_srcsel, 
    output logic [3:0] alu_control,
    output logic [2:0]      rfwd_src,
    output logic [2:0] o_funct3,
    output logic       dwe
);


    always_comb begin 
        rf_we       = 1'b0;
        branch      = 1'b0;
        jalr_srcsel = 1'b0;
        jal_srcsel  = 1'b0;
        alu_control = 4'b0000;
        alu_src     = 1'b0;
        rfwd_src    = 3'b000;
        o_funct3    = 3'b000;
        dwe         = 1'b0;
        case (opcode)
            `R_TYPE: begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                jalr_srcsel = 1'b0;
                jal_srcsel  = 1'b0;
                alu_src     = 1'b0;
                alu_control = {funct7[5],funct3};    
                rfwd_src    =3'b000;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
            end  
             `B_TYPE:begin
                rf_we       = 1'b0;
                branch      = 1'b1;
                jalr_srcsel = 1'b0;
                jal_srcsel  = 1'b0;
                alu_src     = 1'b0;
                alu_control = {1'b0, funct3};  //adding compare control ???
                rfwd_src    =3'b000;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
            end
            `S_TYPE:begin
                rf_we       = 1'b0;
                branch      = 1'b0;
                jalr_srcsel = 1'b0;
                jal_srcsel  = 1'b0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    =3'b000;
                o_funct3    = funct3;
                dwe         = 1'b1;
            end
            `IL_TYPE:begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                jalr_srcsel = 1'b0;
                jal_srcsel  = 1'b0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    =3'b001;  //mux 5x1 --> 3bit 
                o_funct3    = funct3;
                dwe         = 1'b0;
            end
            `I_TYPE:begin
                rf_we   = 1'b1;
                branch      = 1'b0;
                jalr_srcsel = 1'b0;
                jal_srcsel  = 1'b0;
                alu_src     = 1'b1;
                if(funct3 == 3'b101)
                    alu_control = {funct7[5],funct3};
                else
                    alu_control = {1'b0,funct3};

                rfwd_src    = 3'b000;
                o_funct3    = funct3;
                dwe         = 1'b0;
            end
            `LUI_TYPE:begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                jalr_srcsel = 1'b0;
                jal_srcsel  = 1'b0;
                alu_src     = 1'b0;
                alu_control = 4'b0000;
                rfwd_src    =3'b011;  //mux 5x1 --> 3bit 
                o_funct3    = 3'b000;
                dwe         = 1'b0;
                
            end
            `AUIPC_TYPE:begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                jalr_srcsel = 1'b0;
                jal_srcsel  = 1'b0;
                alu_src     = 1'b0;
                alu_control = 4'b0000;
                rfwd_src    = 3'b010;
                o_funct3    = 3'b000;
                dwe         = 1'b0;

            end
            `JAL_TYPE:begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                jalr_srcsel = 1'b0;
                jal_srcsel  = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0000;    
                rfwd_src    =3'b100;  //mux 5x1 = in4
                o_funct3    = 3'b000;
                dwe         = 1'b0;
                
            end
            `JALR_TYPE:begin
                rf_we       = 1'b1;
                branch      = 1'b0;
                jalr_srcsel = 1'b1;
                jal_srcsel  = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0000;    
                rfwd_src    =3'b100; // mux 5x1 = in4
                o_funct3    = 3'b000;
                dwe         = 1'b0;
            end

        endcase
        
    end
    
    
    
endmodule
