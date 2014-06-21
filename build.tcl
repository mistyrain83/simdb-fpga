#set compile_directory     actel
set top_name              ./designer/impl1/SIM_DB
#set family                ProASIC3
#set part                  A3P400
#set package               "256 FBGA"
#set pdc_filename          ../../source/board_support/actel.pdc

proc run_designer {message script} {
    puts "Designer: $message"
    set f [open designer.tcl w]
    puts $f $script
    close $f
    puts [exec designer SCRIPT:designer.tcl]
}

run_designer "compile" "
  open_design $top_name.adb
  compile \
    -pdc_abort_on_error on \
    -pdc_eco_display_unmatched_objects off \
    -pdc_eco_max_warnings 10000 \
    -demote_globals off \
    -demote_globals_max_fanout 12 \
    -promote_globals off \
    -promote_globals_min_fanout 200 \
    -promote_globals_max_limit 0 \
    -localclock_max_shared_instances 12 \
    -localclock_buffer_tree_max_fanout 12 \
    -combine_register off \
    -delete_buffer_tree off \
    -delete_buffer_tree_max_fanout 12 \
    -report_high_fanout_nets_limit 10
  save_design $top_name.adb
"

run_designer "layout" "
  open_design $top_name.adb
  layout \
    -timing_driven \
    -run_placer on \
    -place_incremental off \
    -run_router on \
    -route_incremental off \
    -placer_high_effort off
  save_design $top_name.adb
"

# run_designer "exporting STAPL file" "
  # open_design $top_name.adb
  # export \
    # -format bts_stp \
    # -feature prog_fpga \
    # $top_name.stp
  # save_design $top_name.adb
# "

run_designer "exporting PDB file" "
  open_design $top_name.adb
  export \
    -format pdb \
    -feature prog_fpga \
    $top_name.pdb
  save_design $top_name.adb
"
