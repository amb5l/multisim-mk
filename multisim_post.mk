################################################################################
# multisim_post.mk															   #
# See https://github.com/amb5l/multisim-mk									   #
# include this in your makefile after your unit declarations				   #
################################################################################
# GHDL elaboration step

ifeq ($(SIM),ghdl)
GHDL_EXE=$(SIM_TOP)$(DOT_EXE)
$(GHDL_EXE): $(GHDL_UNITS)
	$(GHDL) -e $(GHDL_EOPTS) $(SIM_TOP)
endif

################################################################################
# Vivado project

ifeq ($(SIM),vivado)
$(VIVADO_XPR): $(VIVADO_SRC)
ifeq ($(VHDL_STANDARD),2008)
	$(VIVADO_MK) create VHDL none sim_vhdl_2008: $(VIVADO_SRC) sim_top: $(SIM_TOP)
else
	$(VIVADO_MK) create VHDL none sim_vhdl: $(VIVADO_SRC) sim_top: $(SIM_TOP)
endif
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
else ifeq ($(SIM),vivado)
RUN_DEP=$(VIVADO_XPR)
RUN_CMD=$(VIVADO_MK) simulate gen: $(strip $(subst ;, ,$1))
endif

define RUN
run: $(RUN_DEP)
	$(RUN_CMD)
endef

ghdl: run
nvc: run
msq: run
vivado: run

################################################################################
# cleanup

clean::
	rm -f $(SIM_TOP) $(SIM_TOP).exe $(wildcard *.cf) $(wildcard *.o) $(wildcard *.lst)
	rm -rf $(NVC_WORK_DIR)
	rm -f $(wildcard *.$(MSQ_VCOM_LOG_EXT)) $(wildcard *.ini) transcript
	rm -rf $(MSQ_WORK)

################################################################################
# end of file