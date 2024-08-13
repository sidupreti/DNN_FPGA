`timescale 1ns / 1ps

module dnn_fpga_tb;

    // Parameters
    parameter INPUT_SIZE = 784;
    parameter HIDDEN_NEURONS = 10;
    parameter OUTPUT_NEURONS = 10;

    // Inputs
    logic clk;
    logic rst_n;
    logic start;
    logic signed [15:0] input_vector [INPUT_SIZE];

    // Outputs
    logic [3:0] final_digit;
    logic done;

    // Instantiate the top module
    dnn_top #(
        .INPUT_SIZE(INPUT_SIZE),
        .HIDDEN_NEURONS(HIDDEN_NEURONS),
        .OUTPUT_NEURONS(OUTPUT_NEURONS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .input_vector(input_vector),
        .final_digit(final_digit),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Testbench procedure
    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        start = 0;

        // Wait 100 ns for global reset to finish
        #100;

        // Apply reset
        rst_n = 1;

        // Load input image into the input_vector
        $readmemb("input_image.mem", input_vector);

        // Start the process
        start = 1;

        // Wait for the processing to complete
        wait(done);

        // Check the result
        $display("Predicted Digit: %d", final_digit);

        // Stop the simulation
        $stop;
    end

    // Simple test to check file access
    initial begin
        integer file;
        string file_names [10];

        // Hidden layer files
        for (int i = 0; i < HIDDEN_NEURONS; i = i + 1) begin
            file_names[i] = $sformatf("weights_hidden_%0d.mem", i);
            file = $fopen(file_names[i], "r");
            if (!file) begin
                $fatal("Error: Could not open %s", file_names[i]);
            end else begin
                $display("Successfully opened %s", file_names[i]);
            end
            $fclose(file);

            file_names[i] = $sformatf("bias_hidden_%0d.mem", i);
            file = $fopen(file_names[i], "r");
            if (!file) begin
                $fatal("Error: Could not open %s", file_names[i]);
            end else begin
                $display("Successfully opened %s", file_names[i]);
            end
            $fclose(file);
        end

        // Output layer files
        for (int i = 0; i < OUTPUT_NEURONS; i = i + 1) begin
            file_names[i] = $sformatf("weights_output_%0d.mem", i);
            file = $fopen(file_names[i], "r");
            if (!file) begin
                $fatal("Error: Could not open %s", file_names[i]);
            end else begin
                $display("Successfully opened %s", file_names[i]);
            end
            $fclose(file);

            file_names[i] = $sformatf("bias_output_%0d.mem", i);
            file = $fopen(file_names[i], "r");
            if (!file) begin
                $fatal("Error: Could not open %s", file_names[i]);
            end else begin
                $display("Successfully opened %s", file_names[i]);
            end
            $fclose(file);
        end

        // Check the input image file
        file = $fopen("input_image.mem", "r");
        if (!file) begin
            $fatal("Error: Could not open input_image.mem");
        end else begin
            $display("Successfully opened input_image.mem");
        end
        $fclose(file);
    end

endmodule
