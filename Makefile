lint:
	verilator --lint-only -f list_file/list_rtl/list_core.f


# rm -rf obj_dir
# verilator --binary --timing --assert \
#   --top-module tb_alu \
#   -f list_file/list_rtl/list_core.f
# ./obj_dir/Vtb_alu


rm -rf obj_dir

verilator --binary --timing --assert --trace \
  --top-module regfile_top \
  -f list_file/list_rtl/list_core.f

./obj_dir/Vregfile_top



rm -rf obj_dir

verilator --binary --timing --trace \
  --top-module immgen_top \
  -f list_file/list_rtl/list_core.f

./obj_dir/Vimmgen_top