################################################################################
# multisim_post.mk															   #
# See https://github.com/amb5l/multisim-mk									   #
# include this in your makefile after your unit declarations				   #
################################################################################
# rule/recipe for elaboration step (GHDL, NVC)

# GHDL
GHDL_EXE=$(SIM_TOP)$(EXE_EXT)
$(GHDL_EXE): $(GHDL_UNITS)
	$(GHDL) -e $(GHDL_EOPTS) $(SIM_TOP)

# NVC
NVC_DLL=$(NVC_WORK_DIR)/_$(NVC_WORK_NAME).elab.dll
$(NVC_DLL): $(NVC_UNITS)
	$(NVC) $(NVC_GOPTS) -e $(SIM_TOP) $(NVC_EOPTS)

################################################################################
# rule/recipe for run step

ifeq ($(SIM),ghdl)
RUN_DEP=$(GHDL_EXE)
else ifeq ($(SIM),nvc)
RUN_DEP=$(NVC_UNITS)
else ifeq ($(SIM),msq)
RUN_DEP=$(MSQ_UNITS)
endif

define RUN
run: $(RUN_DEP)
	ifeq ($(SIM),ghdl)
	$(GHDL) -r $(SIM_TOP) $(GHDL_ROPTS)
	else ifeq ($(SIM),nvc)
	$(NVC) $(NVC_GOPTS) -e $(SIM_TOP) $(NVC_EOPTS)
	$(NVC) $(NVC_GOPTS) -r $(SIM_TOP) $(NVC_ROPTS)
	else ifeq ($(SIM),msq)
	$(MSQ_VSIM) $(MSQ_VSIMOPTS) $(SIM_TOP)
	endif
endef

define RUN_GEN
$(eval SIM_GEN=$(strip $(addprefix -g,$(subst ;, ,$1))))
ifeq ($(SIM),ghdl)
	$(GHDL) -r $(SIM_TOP) $(GHDL_ROPTS) $(SIM_GEN)
else ifeq ($(SIM),nvc)
	$(NVC) $(NVC_GOPTS) -e $(SIM_TOP) $(NVC_EOPTS) $(SIM_GEN)
	$(NVC) $(NVC_GOPTS) -r $(SIM_TOP) $(NVC_ROPTS)
else ifeq ($(SIM),msq)
	$(MSQ_VSIM) $(MSQ_VSIMOPTS) $(SIM_TOP) $(SIM_GEN)
endif
endef

ghdl: run
nvc:  run
msq:  run

################################################################################
# cleanup

clean::
	rm -f $(GHDL_EXE) *.cf *.o *.lst
	rm -f *.$(MSQ_VCOM_LOG_EXT) *.ini transcript
	rm -rf $(NVC_WORK_DIR)
	rm -rf $(MSQ_WORK)

################################################################################
# end of file