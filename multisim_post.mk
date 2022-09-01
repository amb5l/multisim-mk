################################################################################
# multisim_post.mk															   #
# See https://github.com/amb5l/multisim-mk									   #
# include this in your makefile after your unit declarations				   #
################################################################################
# rule/recipe for elaboration step (GHDL, NVC)

# GHDL
ifeq ($(SIM),ghdl)
GHDL_EXE=$(SIM_TOP)$(EXE_EXT)
$(GHDL_EXE): $(GHDL_UNITS)
	$(GHDL) -e $(GHDL_EOPTS) $(SIM_TOP)
endif

# NVC
ifeq ($(SIM),nvc)
NVC_DLL=$(NVC_WORK_DIR)/_$(NVC_WORK_NAME).elab.dll
$(NVC_DLL): $(NVC_UNITS)
	$(NVC) $(NVC_GOPTS) -e $(SIM_TOP) $(NVC_EOPTS)
endif

################################################################################
# rule/recipe for run step

ifeq ($(SIM),ghdl)
RUN_DEP=$(GHDL_EXE)
RUN_CMD=$(GHDL) -r $(SIM_TOP) $(GHDL_ROPTS) $(strip $(addprefix -g,$(subst ;, ,$1)))
else ifeq ($(SIM),nvc)
RUN_DEP=$(NVC_UNITS)
RUN_CMD=$(NVC) $(NVC_GOPTS) -e $(SIM_TOP) $(NVC_EOPTS) $(strip $(addprefix -g,$(subst ;, ,$1))); $(NVC) $(NVC_GOPTS) -r $(SIM_TOP) $(NVC_ROPTS)
else ifeq ($(SIM),msq)
RUN_DEP=$(MSQ_UNITS)
RUN_CMD=$(MSQ_VSIM) $(MSQ_VSIMOPTS) $(SIM_TOP) $(strip $(addprefix -g,$(subst ;, ,$1)))
endif

define RUN
run: $(RUN_DEP)
	$(RUN_CMD)
endef

ghdl: run
nvc:  run
msq:  run

################################################################################
# cleanup

clean::
	rm -f $(GHDL_EXE) *.cf *.o *.lst
	rm -rf $(NVC_WORK_DIR)
	rm -f *.$(MSQ_VCOM_LOG_EXT) *.ini transcript
	rm -rf $(MSQ_WORK)

################################################################################
# end of file