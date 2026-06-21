`timescale 1ns / 1ps


module instruction_mem(
    input [31:0] instr_addr,
    output [31:0] instr_data
    );

    logic [31:0] rom[0:31];

    initial begin
        
        rom[0] =32'h004182b3;  //  ADD X5, X3, X4
        rom[1] = 32'h00812123; // SW x8, 2(x2),
        rom[2] = 32'h00212383;  // LW, x7 x2, 2
        rom[3] = 32'h00438413;  //  ADDI X8, X7, 4
        rom[4] = 32'h00840463; //BEQ x8 x8,8
        rom[5] =32'h004182b3;  //  ADD X5, X3, X4
        rom[6] = 32'h00812123; // SW x8, 2(x2),
    end

    assign instr_data = rom[instr_addr[31:2]]; // delete '0', '1'

endmodule

        //rom[0] = 32'h005102a3; // SB x5  5(x2)
        //rom[1] = 32'h002102a3; // SB x2  5(x2)
        //rom[2] = 32'h005102a3; // SB x5  5(x2)
        //rom[3] = 32'h002102a3; // SB x2  5(x2)
        //rom[4] = 32'h005102a3; // SB x5  5(x2)
        //rom[0] = 32'h00511123;  // SH x5 2(x2)
        
        //rom[3] = 32'h00211123;
        //rom[2] = 32'h00211123;
        //rom[2] =32'h402852b3;  