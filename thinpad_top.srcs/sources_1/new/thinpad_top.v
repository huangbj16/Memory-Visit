`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信号
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB数据线与网络控制器的dm9k_sd[7:0]共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);


/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock out ports
  .clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置
  .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked), // 锁定输出，"1"表示时钟稳定，可作为后级电路复位
 // Clock in ports
  .clk_in1(clk_50M) // 外部时钟输入
 );

reg reset_of_clk10M;
// 异步复位，同步释放
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

// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7段数码管译码器演示，将number用16进制显示在数码管上面
// reg[7:0] number;
// SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
// SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管


reg[15:0] led_bits;
assign leds = led_bits;
/*
reg[31:0] input_a;
reg[31:0] input_b;
reg[32:0] result;
reg[3:0] op;
reg cf, of, sf, zf;//进位，溢出，符号，零
reg[1:0] flag;

parameter INPUT_A = 2'b00;
parameter INPUT_B = 2'b01;
parameter CALC_OP = 2'b10;
parameter CALC_FO = 2'b11;


//ALU功能列表
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
    if(reset_btn) begin // 复位按下，设置输入数和LED数码管为初始值
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
    else begin // 每次按下时钟按钮，根据输入得到输出
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
//自动机的变量
reg[31:0] input_address;
reg[31:0] input_data;
reg [2:0] state;
reg [3:0] count = 0;//count to 10;
localparam [2:0] SWITCH_ADDRESS = 3'b000,
                 SWITCH_DATA = 3'b001,
                 STORE_DATA = 3'b010,
                 LED_DATA = 3'b011,
                 STORE_DATA2 = 3'b100,
                 LED_DATA2 = 3'b101;

//内存读取的变量
reg begin_end = 1'b0;
reg data_got = 1'b0;
reg temp_ce, temp_oe, temp_we;
reg[31:0] temp_data;
reg[19:0] temp_addr;
reg[3:0] temp_be;
assign base_ram_ce_n = temp_ce;//BaseRAM片选，低有效
assign base_ram_oe_n = temp_oe;//BaseRAM读使能，低有效
assign base_ram_we_n = temp_we;//BaseRAM写使能，低有效
assign base_ram_data = temp_data;//BaseRAM数据，低8位与CPLD串口控制器共享
assign base_ram_addr = temp_addr;//BaseRAM地址
assign base_ram_be_n = temp_be;//BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0

reg temp_ce2, temp_oe2, temp_we2;
reg[31:0] temp_data2;
reg[19:0] temp_addr2;
reg[3:0] temp_be2;
assign ext_ram_ce_n = temp_ce2;//ExtRAM片选，低有效
assign ext_ram_oe_n = temp_oe2;//ExtRAM读使能，低有效
assign ext_ram_we_n = temp_we2;//ExtRAM写使能，低有效
assign ext_ram_data = temp_data2;//ExtRAM数据，低8位与CPLD串口控制器共享
assign ext_ram_addr = temp_addr2;//ExtRAM地址
assign ext_ram_be_n = temp_be2;//ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0

//define state machine of click clock
always @(posedge clock_btn or posedge reset_btn) begin//ram operation
    if(reset_btn) begin
        state <= SWITCH_ADDRESS;
        count <= 4'b0000;
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
            if(count == 9) begin
                state <= LED_DATA;
                count <= 4'b0000;
            end
            else begin
                count <= count + 1'b1;
            end
        end
        LED_DATA: begin
            if(count == 9) begin
                state <= STORE_DATA2;
                count <= 4'b0000;
            end
            else begin
                count <= count + 1'b1;
            end
        end
        STORE_DATA2: begin
            if(count == 9) begin
                state <= LED_DATA2;
                count <= 4'b0000;
            end
            else begin
                count <= count + 1'b1;
            end
        end
        LED_DATA2: begin
            if(count == 9) begin
                state <= SWITCH_ADDRESS;
                count <= 4'b0000;
            end
            else begin
                count <= count + 1'b1;
            end
        end
        default: begin
            state <= SWITCH_ADDRESS;
            count <= 4'b0000;
        end
        endcase;
    end
end

always @(posedge clk_50M) begin
    if(clk_50M) begin
        temp_be <= 4'b0000;
        if(state == STORE_DATA) begin
            if(~begin_end) begin//start
                temp_addr <= input_address[19:0] + count;
                temp_ce <= 1'b0;
                temp_oe <= 1'b1;
                temp_we <= 1'b0;
                temp_data <= input_data + count;
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
                temp_addr <= input_address[19:0] + count;
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
        else if(state == STORE_DATA2) begin
            if(~begin_end) begin//start
                temp_addr <= input_address[19:0] + count;
                temp_data <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
                temp_ce <= 1'b0;
                temp_oe <= 1'b0;
                temp_we <= 1'b1;
                begin_end <= 1'b1;
                data_got <= 1'b0;

                temp_ce2 <= 1'b1;
                temp_oe2 <= 1'b1;
                temp_we2 <= 1'b1;
            end
            else begin
                temp_ce <= 1'b1;
                temp_oe <= 1'b1;
                temp_we <= 1'b1;
                begin_end <= 1'b0;
                data_got <= 1'b1;

                temp_data2 <= temp_data - 1'b1;
                temp_addr2 <= input_address[19:0] + count;
                temp_ce2 <= 1'b0;
                temp_oe2 <= 1'b1;
                temp_we2 <= 1'b0;
            end
        end
        else if(state == LED_DATA2) begin
            if(~begin_end) begin//start
                temp_addr2 <= input_address[19:0] + count;
                temp_data2 <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
                temp_ce2 <= 1'b0;
                temp_oe2 <= 1'b0;
                temp_we2 <= 1'b1;
                begin_end <= 1'b1;
                data_got <= 1'b0;
            end
            else begin
                temp_ce2 <= 1'b1;
                temp_oe2 <= 1'b1;
                temp_we2 <= 1'b1;
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
        led_bits <= {temp_addr[7:0], temp_data[7:0]};
    end
    LED_DATA: begin
        if(~data_got) begin
            led_bits <= 16'b0000000000000000;
        end
        else begin
            led_bits <= {temp_addr[7:0], temp_data[7:0]};
        end
    end
    STORE_DATA2: begin
        led_bits <= {temp_addr2[7:0], temp_data2[7:0]};
    end
    LED_DATA2: begin
        if(~data_got) begin
            led_bits <= 16'b0000000000000000;
        end
        else begin
            led_bits <= {temp_addr2[7:0], temp_data2[7:0]};
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

//直连串口接收发送演示，从直连串口收到的数据再发送出去
wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clk_50M),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标志
        .RxD_clear(ext_uart_ready),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的一字节数据
    );
    
always @(posedge clk_50M) begin //接收到缓冲区ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
always @(posedge clk_50M) begin //将缓冲区ext_uart_buffer发送出去
    if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk_50M),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出
        .TxD_busy(ext_uart_busy),       //发送器忙状态指示
        .TxD_start(ext_uart_start),    //开始发送信号
        .TxD_data(ext_uart_tx)        //待发送的数据
    );

//图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //横坐标
    .vdata(),      //纵坐标
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */

endmodule
