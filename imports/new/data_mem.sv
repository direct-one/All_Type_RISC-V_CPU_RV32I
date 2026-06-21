`timescale 1ns / 1ps

module data_mem(
    input        clk,
    input        rst,
    input        dwe,
    input   logic [2:0]  i_funct3,
    input   logic [31:0] daddr,
    input   logic [31:0] dwdata,
    output  logic  [31:0] drdata
    );


    //block ram(word address) 
    
    
    //S-type 
    logic [31:0] dmem[0:31];
    always_ff @( posedge  clk ) begin  //store the data (write)
        if (dwe) begin
            case (i_funct3)
                3'b010:begin //SW
                    dmem[daddr[6:2]] <= dwdata;
                end 
                3'b001:begin //SH
                    if(daddr[1])begin
                    dmem[daddr[6:2]][31:16] <= dwdata[15:0];
                end else begin
                    dmem[daddr[6:2]][15:0] <= dwdata[15:0];
                end
                end 
                3'b000:begin //SB
                    case (daddr[1:0])
                        2'b00:dmem[daddr[6:2]][7:0] <= dwdata[7:0]; 
                        2'b01:dmem[daddr[6:2]][15:8] <= dwdata[7:0];
                        2'b10:dmem[daddr[6:2]][23:16] <= dwdata[7:0];
                        2'b11:dmem[daddr[6:2]][31:24] <= dwdata[7:0]; 
                    
                    endcase
                end
            endcase
        
        end
        
    end 

    //IL-type (+zero_extend)
    logic [31:0] load_data;
    logic [7:0] byte_data;
    logic [15:0] half_data;

    assign load_data = dmem[daddr[6:2]];

    always_comb begin  //Load the data(read)
        case (daddr[1:0])
            2'b00: byte_data = load_data[7:0];
            2'b01: byte_data = load_data[15:8];
            2'b10: byte_data = load_data[23:16];
            2'b11: byte_data = load_data[31:24]; 
        endcase
        if(daddr[1])begin
            half_data = load_data[31:16];
        end else begin
            half_data = load_data[15:0];
        end
        
    end

    always_comb begin 
        drdata = load_data;
        case (i_funct3)
            3'b000: drdata = {{24{byte_data[7]}}, byte_data}; //LB
            3'b001: drdata = {{16{byte_data[15]}}, half_data}; //LH
            3'b010: drdata = load_data;                        //LW
            3'b100: drdata = {24'd0, byte_data}; //LBU  (zero extend)
            3'b101: drdata = {16'd0, half_data}; //LHU  (zero extend)
        endcase
        
    end


endmodule





//before 
//if(i_funct3 == 3'b010)begin 
//            dmem[daddr[31:2]] <= dwdata;
//end



///module zero_extender (
///    input i_funct3
///    input drdata,
///    output o_drdata
///);
///
///    always_comb begin 
///        case (i_funct3)
///            : 
///            default: 
///        endcase
///        
///    end
///
///endmodule
///    
///    
//byte address
//    logic [7:0]  dmem[0:31];
//
//    always_ff @( posedge clk, posedge rst ) begin : blockName
//        if (rst) begin
//            
//        end else begin 
//            if (dwe) begin
//                dmem[daddr+0] <= dwdata[7:0];
//                dmem[daddr+1] <= dwdata[15:8];
//                dmem[daddr+2] <= dwdata[23:16];
//                dmem[daddr+3] <= dwdata[31:24];
//            end
//        end 
//    end

