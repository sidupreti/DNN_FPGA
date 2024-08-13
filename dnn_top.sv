module dnn_top #(
    parameter INPUT_SIZE = 784,
    parameter HIDDEN_NEURONS = 10,
    parameter OUTPUT_NEURONS = 10
)(
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic signed [15:0] input_vector [INPUT_SIZE], // Input vector representing the pixel values
    output logic [3:0] final_digit,                     // Final digit determined by argmax (4 bits to represent 0-9)
    output logic done
);

    logic done_signals [HIDDEN_NEURONS + OUTPUT_NEURONS];
    logic signed [15:0] hidden_output [HIDDEN_NEURONS];
    logic signed [15:0] output_values [OUTPUT_NEURONS];
    logic [HIDDEN_NEURONS-1:0] hidden_done_vector;
    integer i; // Loop variable for argmax calculation

    // Convert the array `done_signals` for hidden neurons to a vector `hidden_done_vector`
    always_comb begin
        for (i = 0; i < HIDDEN_NEURONS; i = i + 1) begin
            hidden_done_vector[i] = done_signals[i];
        end
    end

    // Instantiate hidden layer neurons
    genvar idx;
    generate
        for (idx = 0; idx < HIDDEN_NEURONS; idx = idx + 1) begin : hidden_neurons
            neuron #(
                .INPUT_SIZE(INPUT_SIZE),
                .NEURON_NUM(idx),
                .IS_HIDDEN_LAYER(1'b1)
            ) hidden_neuron_inst (
                .clk(clk),
                .rst_n(rst_n),
                .start(start),
                .input_vector(input_vector),
                .result(hidden_output[idx]),
                .done(done_signals[idx])
            );
        end
    endgenerate

    // Instantiate output layer neurons
    generate
        for (idx = 0; idx < OUTPUT_NEURONS; idx = idx + 1) begin : output_neurons
            neuron #(
                .INPUT_SIZE(HIDDEN_NEURONS),
                .NEURON_NUM(idx),
                .IS_HIDDEN_LAYER(1'b0)
            ) output_neuron_inst (
                .clk(clk),
                .rst_n(rst_n),
                .start(&hidden_done_vector), // Start when all hidden layer neurons are done
                .input_vector(hidden_output),
                .result(output_values[idx]),
                .done(done_signals[HIDDEN_NEURONS + idx])
            );
        end
    endgenerate

    // Argmax logic to determine the final output digit
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_digit <= 4'd0;
        end else if (&done_signals[HIDDEN_NEURONS:HIDDEN_NEURONS+OUTPUT_NEURONS-1]) begin
            logic signed [15:0] max_value;
            logic [3:0] max_index;

            max_value <= output_values[0];
            max_index <= 4'd0;

            for (i = 1; i < OUTPUT_NEURONS; i = i + 1) begin
                if (output_values[i] > max_value) begin
                    max_value <= output_values[i];
                    max_index <= i;
                end
            end

            final_digit <= max_index;
        end
    end

    assign done = &done_signals;

endmodule
