`timescale 1ns / 1ps

module dnn_fpga_tb();

    // Testbench signals
    reg clk;
    reg rst_n;
    reg start;
    reg signed [15:0] input_vector [0:783]; // Image vector (28x28 pixels)
    wire [3:0] final_digit;                 // Predicted digit output
    wire done;                              // Done signal

    // Instantiate the DNN Top Module
    dnn_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .input_vector(input_vector),
        .final_digit(final_digit),
        .done(done)
    );

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize reset and start signals
        rst_n = 0;
        start = 0;
        #20 rst_n = 1;

        // Load the sample image into input_vector
        // Assume the image has been preprocessed and stored in "input_image.mem"
        $readmemh("/Users/sidupreti/Desktop/DNN_FPGA/input_image.mem", input_vector);

        // Start the DNN processing
        #20 start = 1;

        // Wait for the processing to complete
        wait(done);
        #10;

        // Display the predicted digit
        $display("Predicted Digit: %d", final_digit);

        // End the simulation
        $stop;
    end

endmodule
