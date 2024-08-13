module neuron #(
    parameter INPUT_SIZE = 784,
    parameter ADDR_WIDTH = 10,
    parameter NEURON_NUM = 0,        // Unique neuron identifier
    parameter IS_HIDDEN_LAYER = 1'b1 // 1 for hidden layer, 0 for output layer
)(
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic [15:0] input_vector [INPUT_SIZE],  // Input vector, unsigned by default
    output logic [15:0] result,                    // Neuron output, unsigned by default
    output logic done                              // Done signal
);

    logic signed [31:0] mac;                        // Multiply-Accumulate register
    logic signed [15:0] weight_rom [0:INPUT_SIZE-1]; // ROM for weights, signed
    logic signed [15:0] bias;                       // Bias, signed
    integer j;

    // Initialize weights based on neuron number
    initial begin
        if (IS_HIDDEN_LAYER) begin
            $readmemb($sformatf("weights_hidden_%0d.mem", NEURON_NUM), weight_rom);
        end else begin
            $readmemb($sformatf("weights_output_%0d.mem", NEURON_NUM), weight_rom);
        end
    end

    // Initialize bias based on neuron number
    initial begin
        if (IS_HIDDEN_LAYER) begin
            $readmemb($sformatf("bias_hidden_%0d.mem", NEURON_NUM), bias);
        end else begin
            $readmemb($sformatf("bias_output_%0d.mem", NEURON_NUM), bias);
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mac <= 32'sd0;
            done <= 1'b0;
        end else if (start) begin
            mac <= 32'sd0;
            for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                mac <= mac + $signed(input_vector[j]) * weight_rom[j];  // Casting input_vector as signed
            end

            // Add bias to MAC result and handle overflow/underflow
            logic signed [31:0] temp_result;
            temp_result = mac + {{16{bias[15]}}, bias}; // Bias sign-extension

            // Check for overflow/underflow and saturate if necessary
            if (temp_result > 32'sh00007FFF) begin
                result <= 16'h7FFF; // Positive overflow, max positive value
            end else if (temp_result < -32'sh00008000) begin
                result <= 16'h8000; // Negative overflow, max negative value
            end else begin
                result <= temp_result[30:15]; // Normal operation
            end

            done <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end
endmodule
