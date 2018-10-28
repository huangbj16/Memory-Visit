`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ������

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�������ON��ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //CPLD���ڿ������ź�
    output wire uart_rdn,         //�������źţ�����Ч
    output wire uart_wrn,         //д�����źţ�����Ч
    input wire uart_dataready,    //��������׼����
    input wire uart_tbre,         //�������ݱ�־
    input wire uart_tsre,         //���ݷ�����ϱ�־

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //USB �������źţ��ο� SL811 оƬ�ֲ�
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB�������������������dm9k_sd[7:0]����
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //����������źţ��ο� DM9000A оƬ�ֲ�
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);


/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock out ports
  .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������
  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
  // Status and control signals
  .reset(reset_btn), // PLL��λ����
  .locked(locked), // ���������"1"��ʾʱ���ȶ�������Ϊ�󼶵�·��λ
 // Clock in ports
  .clk_in1(clk_50M) // �ⲿʱ������
 );

reg reset_of_clk10M;
// �첽��λ��ͬ���ͷ�
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end

always@(posedge clk_10M or posedge reset_of_clk10M) begin
    if(reset_of_clk10M)begin
        // Your Code
    end
    else begin
        // Your Code
    end
end

// ��������ӹ�ϵʾ��ͼ��dpy1ͬ��
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7���������������ʾ����number��16������ʾ�����������
// reg[7:0] number;
// SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
// SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����


reg[15:0] led_bits;
assign leds = led_bits;
/*
reg[31:0] input_a;
reg[31:0] input_b;
reg[32:0] result;
reg[3:0] op;
reg cf, of, sf, zf;//��λ����������ţ���
reg[1:0] flag;

parameter INPUT_A = 2'b00;
parameter INPUT_B = 2'b01;
parameter CALC_OP = 2'b10;
parameter CALC_FO = 2'b11;


//ALU�����б�
//0000 ADD 0
//0001 SUB 1
//0010 AND 2
//0011 OR  3
//0100 XOR 4
//0101 NOT 5
//0110 SLL 6
//0111 SRL 7
//1000 SRA 8
//1001 ROL 9
//OTHERS DEFAULT NOTHING


always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn) begin // ��λ���£�������������LED�����Ϊ��ʼֵ
        flag <= INPUT_A;
        led_bits <= 16'b1010101010101010;
        input_a <= 32'b0;
        input_b <= 32'b0;
        result <= 33'b0;
        cf <= 0;
        sf <= 0;
        of <= 0;
        zf <= 0;
    end
    else begin // ÿ�ΰ���ʱ�Ӱ�ť����������õ����
       case(flag)
       INPUT_A : begin
            input_a <= dip_sw;
            flag <= INPUT_B;
            led_bits <= dip_sw[15:0];
       end
       INPUT_B : begin
            input_b <= dip_sw;
            flag <= CALC_OP;
            led_bits <= dip_sw[15:0];
       end
       CALC_OP : begin
            op = dip_sw[3:0];
            case(op)
            4'b0000 : begin // ADD
                result = {1'b0, input_a} + {1'b0, input_b};
                if(result[32]) 
                    cf <= 1;
                if((~input_a[31] && ~input_b[31] && result[31]) || (input_a[31] && input_b[31] && ~result[31]))
                    of <= 1;
            end
            4'b0001 : begin //SUB
                result = {1'b0, input_a} - {1'b0, input_b};
                if(result[32]) 
                    cf <= 1;
                if((input_a[31] && ~input_b[31] && ~result[31]) || (~input_a[31] && input_b[31] && result[31]))
                    of <= 1;
            end
            4'b0010 : begin //AND
                result = {1'b0, input_a & input_b};
            end
            4'b0011 : begin //OR
                result = {1'b0, input_a | input_b};
            end
            4'b0100 : begin //XOR
                result = {1'b0, input_a ^ input_b};
            end
            4'b0101 : begin //NOT
                result = {1'b0, ~input_a};
            end
            4'b0110 : begin //SLL
                result = {1'b0, input_a << input_b};
            end
            4'b0111 : begin //SRL
                result = {1'b0, input_a >> input_b};
            end
            4'b1000 : begin // SRA
                result = {1'b0, ($signed(input_a)) >>> input_b};
            end
            4'b1001 : begin //ROL
                result = {1'b0, (input_a << input_b)|(input_a >> (32-input_b))};
            end 
            default : begin // DEFAULT
                result = {input_a[31], input_a} + {input_b[31], input_b};
            end
            endcase
            led_bits = result[15:0];
            flag <= CALC_FO;
            //calc flag
            if(result[31:0] == 0)
                zf <= 1;
            if(result[31] == 1)
                sf <= 1;
       end
       CALC_FO : begin
            led_bits = 0;
            if(cf)
                led_bits[0] <= 1;
            if(zf)
                led_bits[1] <= 1;
            if(sf)
                led_bits[2] <= 1;
            if(of)
                led_bits[3] <= 1;
            flag <= INPUT_A;
       end
       default : begin
       end
       endcase
    end
end
*/
//�Զ����ı���
reg[31:0] input_address;
reg[31:0] input_data;
reg [1:0] state;
reg [3:0] count = 0;
localparam [1:0] SWITCH_ADDRESS = 2'b00,
                 SWITCH_DATA = 2'b01,
                 STORE_DATA = 2'b10,
                 LED_DATA = 2'b11;

//�ڴ��ȡ�ı���
reg begin_end = 1'b0;
reg data_got = 1'b0;
reg temp_ce, temp_oe, temp_we;
reg[31:0] temp_data;
reg[19:0] temp_addr;
reg[3:0] temp_be;
assign base_ram_ce_n = temp_ce;//BaseRAMƬѡ������Ч
assign base_ram_oe_n = temp_oe;//BaseRAM��ʹ�ܣ�����Ч
assign base_ram_we_n = temp_we; //BaseRAMдʹ�ܣ�����Ч
assign base_ram_data = temp_data;//BaseRAM���ݣ���8λ��CPLD���ڿ���������
assign base_ram_addr = temp_addr;//BaseRAM��ַ
assign base_ram_be_n = temp_be;//BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0

//define state machine of click clock
always @(posedge clock_btn or posedge reset_btn) begin//ram operation
    if(reset_btn) begin
        state <= SWITCH_ADDRESS;
    end
    else begin
        case(state)
        SWITCH_ADDRESS: begin
            input_address <= dip_sw;
            state <= SWITCH_DATA;
        end
        SWITCH_DATA: begin
            input_data <= dip_sw;
            state <= STORE_DATA;
        end
        STORE_DATA: begin
            state <= LED_DATA;
        end
        LED_DATA: begin
            state <= SWITCH_ADDRESS;
        end
        default: begin
            state <= SWITCH_ADDRESS;
        end
        endcase;
    end
end

always @(posedge clk_50M) begin
    if(clk_50M) begin
        temp_be <= 4'b0000;
        if(state == STORE_DATA) begin
            if(~begin_end) begin//start
                temp_addr <= input_address[19:0];
                temp_ce <= 1'b0;
                temp_oe <= 1'b1;
                temp_we <= 1'b0;
                temp_data <= input_data;
                begin_end <= 1'b1;
            end
            else begin
                temp_ce <= 1'b1;
                temp_oe <= 1'b1;
                temp_we <= 1'b1;
                begin_end <= 1'b0;
            end
        end
        else if(state == LED_DATA) begin
            if(~begin_end) begin//start
                temp_addr <= 5'h00002;
                temp_data <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
                temp_ce <= 1'b0;
                temp_oe <= 1'b0;
                temp_we <= 1'b1;
                begin_end <= 1'b1;
                data_got <= 1'b0;
            end
            else begin
                temp_ce <= 1'b1;
                temp_oe <= 1'b1;
                temp_we <= 1'b1;
                begin_end <= 1'b0;
                data_got <= 1'b1;
            end
        end
    end
end

always @(state, data_got) begin//control led_bits
    case(state)
    SWITCH_ADDRESS: begin
        led_bits <= 16'b0101010101010101;
    end
    SWITCH_DATA: begin
        led_bits <= input_address[15:0];
    end
    STORE_DATA: begin
        led_bits <= input_data[15:0];
    end
    LED_DATA: begin
        if(~data_got) begin
            led_bits <= 16'b0000000000000000;
        end
        else begin
            led_bits <= base_ram_data[15:0];
        end
    end
    default: begin
        led_bits <= 16'b0101010100000000;
    end
    endcase;
end
// always @(state, count) begin
//     if(state == STORE_DATA) begin
//         if(count == 0) begin
//             temp_addr = input_address[19:0];
//             temp_ce = 1'b0;
//             temp_oe = 1'b1;
//             temp_we = 1'b0;
//             temp_data = input_data;
//             begin_end = 1'b1;
//         end
//         else begin
//             temp_ce = 1'b1;
//             temp_oe = 1'b1;
//             temp_we = 1'b1;
//             begin_end = 1'b0; 
//         end
//     end
// end

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_r(
        .clk(clk_50M),                       //�ⲿʱ���ź�
        .RxD(rxd),                           //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
        .RxD_clear(ext_uart_ready),       //������ձ�־
        .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
    );
    
always @(posedge clk_50M) begin //���յ�������ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
always @(posedge clk_50M) begin //��������ext_uart_buffer���ͳ�ȥ
    if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clk_50M),                  //�ⲿʱ���ź�
        .TxD(txd),                      //�����ź����
        .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),    //��ʼ�����ź�
        .TxD_data(ext_uart_tx)        //�����͵�����
    );

//ͼ�������ʾ���ֱ���800x600@75Hz������ʱ��Ϊ50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //��ɫ����
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //��ɫ����
assign video_blue = hdata >= 532 ? 2'b11 : 0; //��ɫ����
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //������
    .vdata(),      //������
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */

endmodule