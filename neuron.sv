module neuron #(
    parameter INPUT_SIZE = 784,
    parameter ADDR_WIDTH = 10,
    parameter NEURON_NUM = 0,        // Unique neuron identifier
    parameter IS_HIDDEN_LAYER = 1'b1 // 1 for hidden layer, 0 for output layer
)(
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic [15:0] input_vector [INPUT_SIZE],  // Input vector
    output logic [15:0] result,                    // Neuron output
    output logic done                              // Done signal
);

    logic [31:0] mac;                        // Multiply-Accumulate register
    logic [15:0] weight_rom [0:INPUT_SIZE-1]; // ROM for weights
    logic [15:0] bias;                       // Bias
    integer j;
    integer bias_file;  // File descriptor for the bias file

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
            bias_file = $fopen($sformatf("bias_hidden_%0d.mem", NEURON_NUM), "r");
        end else begin
            bias_file = $fopen($sformatf("bias_output_%0d.mem", NEURON_NUM), "r");
        end

        if (bias_file) begin
            $fscanf(bias_file, "%b", bias);
            $fclose(bias_file);
        end else begin
            $display("Error: Could not open bias file for neuron %0d", NEURON_NUM);
            bias = 16'd0;  // Set a default value if file read fails
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mac <= 32'd0;
            done <= 1'b0;
        end else if (start) begin
            mac <= 32'd0;
            for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                mac <= mac + $signed(input_vector[j]) * $signed(weight_rom[j]); // Cast to signed during multiplication
            end

            // Add bias to MAC result and handle overflow/underflow
            logic [31:0] signed_mac;  // Renamed from temp_result to avoid conflict
            signed_mac = $signed(mac) + $signed({{16{bias[15]}}, bias}); // Cast mac and bias to signed for the addition

            // Check for overflow/underflow and saturate if necessary
            if (signed_mac > 32'sh00007FFF) begin
                result <= 16'h7FFF; // Positive overflow, max positive value
            end else if (signed_mac < -32'sh00008000) begin
                result <= 16'h8000; // Negative overflow, max negative value
            end else begin
                result <= signed_mac[30:15]; // Normal operation
            end

            done <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end
endmodule
