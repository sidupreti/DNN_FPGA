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

    logic [HIDDEN_NEURONS-1:0] hidden_done_vector;
    logic [OUTPUT_NEURONS-1:0] output_done_vector;
    logic signed [15:0] hidden_output [HIDDEN_NEURONS];
    logic signed [15:0] output_values [OUTPUT_NEURONS];
    logic hidden_layer_done;
    logic output_layer_done;
    integer i; // Loop variable for argmax calculation

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
                .done(hidden_done_vector[idx])
            );
        end
    endgenerate

    // Manually check if all hidden layer neurons are done
    always_comb begin
        hidden_layer_done = 1'b1;
        for (i = 0; i < HIDDEN_NEURONS; i = i + 1) begin
            if (!hidden_done_vector[i]) begin
                hidden_layer_done = 1'b0;
            end
        end
    end

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
                .start(hidden_layer_done), // Start when all hidden layer neurons are done
                .input_vector(hidden_output),
                .result(output_values[idx]),
                .done(output_done_vector[idx])
            );
        end
    endgenerate

    // Manually check if all output layer neurons are done
    always_comb begin
        output_layer_done = 1'b1;
        for (i = 0; i < OUTPUT_NEURONS; i = i + 1) begin
            if (!output_done_vector[i]) begin
                output_layer_done = 1'b0;
            end
        end
    end

    // Argmax logic to determine the final output digit
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_digit <= 4'd0;
        end else if (output_layer_done) begin
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

    // Indicate when the entire process is done
    assign done = output_layer_done;

endmodule
