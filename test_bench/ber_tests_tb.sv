`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2020 11:40:52 PM
// Design Name: 
// Module Name: ber_tests_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import channel_tasks_pkg::*;

module ber_tests_tb();

logic clk;
int count = 10000;
real snrDb;
real snr;
int errors;
real BER;

task SNR_vs_BER(real snrDbIn);
  real noise;
  snrDb = snrDbIn;
  snr = $pow(10, snrDb/10.0);
  errors = 0;
  for (int i = 0; i < count; i++)
    begin
      noise = (RandStdNormal() * 1.0) / $sqrt(snr);
      if (noise >= 1)
        errors++;
    end
  BER = errors / (1.0 * count);
  @(posedge clk);
endtask

task Repeat_SNR_vs_BER(real snrDb, int count);
  for (int i = 0; i < count; i++)
    SNR_vs_BER(snrDb);
endtask

task TestRandStdNormal();
  real noise;
  snr = 1;
  snrDb = 1;
  errors = 0;
  for (int i = 0; i < count; i++)
    begin
      noise = (RandStdNormal() * 1.0);
      if (noise >= 1)
        errors++;
    end
  BER = errors / (1.0 * count);
  @(posedge clk);
  snr = -1;
  snrDb = -1;
endtask

task TestRandStdNormalInPhase();
  real noise;
  real PI;
  PI = 3.14159;
  snr = 1;
  snrDb = 1;
  errors = 0;
  for (int i = 0; i < count; i++)
    begin
      noise = (RandStdNormal() * $cos(RandStdNormal() * 2 * PI));
      if (noise >= 1)
        errors++;
    end
  BER = errors / (1.0 * count);
  @(posedge clk);
  snr = -1;
  snrDb = -1;
endtask

initial
  begin
    @(posedge clk);
    TestRandStdNormal();    // Should fail about 15.9% of the time -- outside of one sigma
    TestRandStdNormal();
    TestRandStdNormal();
    TestRandStdNormal();
    TestRandStdNormal();
    TestRandStdNormal();
    @(posedge clk);
    TestRandStdNormalInPhase();     // Is this the same as using N0/2 ?
    TestRandStdNormalInPhase();
    TestRandStdNormalInPhase();
    TestRandStdNormalInPhase();
    TestRandStdNormalInPhase();
    TestRandStdNormalInPhase();
    @(posedge clk);
    Repeat_SNR_vs_BER(1.0, 10);
    Repeat_SNR_vs_BER(2.0, 10);
    Repeat_SNR_vs_BER(3.0, 10);
    Repeat_SNR_vs_BER(4.0, 10);
    Repeat_SNR_vs_BER(5.0, 10);
    Repeat_SNR_vs_BER(6.0, 10);
    Repeat_SNR_vs_BER(7.0, 10);
    Repeat_SNR_vs_BER(8.0, 10);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    $stop;
  end

initial
  begin
    clk = 0;
    forever #10 clk = ~clk;
  end

endmodule
