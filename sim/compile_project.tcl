# Quartus II 13.0sp1 Compilation Script
# This script performs the full compilation flow

proc quartus_build {} {
    # Open the project
    project_open i2c_master_morphic
    
    # Execute analysis & synthesis
    puts "Running Analysis & Synthesis..."
    execute_module -tool map
    
    if {[get_unassigned_pins] != ""} {
        puts "WARNING: Unassigned pins found!"
    }
    
    # Perform fitting
    puts "Running Fitter (Place & Route)..."
    execute_module -tool fit
    
    # Run timing analysis
    puts "Running Timing Analysis..."
    execute_module -tool sta
    
    # Generate reports
    puts "Generating Reports..."
    report_timing -file morphic_timing.rpt
    report_messages -file morphic_messages.rpt
    
    # Create SOF file for SRAM
    puts "Creating SOF file..."
    execute_module -tool asm
    
    # Close project
    project_close
    
    puts "Compilation complete!"
}

# Run the build
quartus_build
