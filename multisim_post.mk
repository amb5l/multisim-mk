################################################################################
# multisim_pre.mk                                                              #
# See https://github.com/amb5l/multisim-mk                                     #
# include this in your makefile after your unit declarations                   #
################################################################################
# rule/recipe for elaboration step (GHDL, NVC)

# GHDL
GHDL_EXE=$(SIM_TOP)$(EXE_EXT)
$(GHDL_EXE): $(GHDL_UNITS)
	$(GHDL) -e $(GHDL_EOPTS) $(SIM_TOP)

# NVC
NVC_DLL=$(NVC_WORK)/_$(shell echo $(NVC_WORK).$(SIM_TOP)| tr a-z A-Z).elab.dll
$(NVC_DLL): $(NVC_UNITS)
	$(NVC) $(NVC_GOPTS) -e $(SIM_TOP) $(NVC_EOPTS)

################################################################################
# rule/recipe for run step

ghdl: $(GHDL_EXE)
	$(GHDL) -r $(SIM_TOP) $(GHDL_ROPTS)

nvc: $(NVC_DLL)
	$(NVC) $(NVC_GOPTS) -r $(SIM_TOP) $(NVC_ROPTS)

gen: $(GEN_UNITS)
	$(GEN_VSIM) $(GEN_VSIMOPTS) $(SIM_TOP)

clean:
	rm -f $(GHDL_EXE) *.cf *.o *.lst
	rm -f *.$(GEN_VCOM_LOG_EXT) *.ini transcript
	rm -rf $(NVC_WORK)
	rm -rf $(GEN_WORK)

################################################################################
# end of file