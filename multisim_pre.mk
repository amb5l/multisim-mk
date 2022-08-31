################################################################################
# multisim_pre.mk                                                              #
# See https://github.com/amb5l/multisim-mk                                     #
# include this in your makefile before your unit declarations                  #
################################################################################
# error if simulator not specified

all:
	$(info *** Please specify your chosen simulator after 'make' as follows: ***)
	$(info make <simulator>)
	$(info )
	$(info Supported options for <simulator>:)
	$(info ghdl (for GHDL))
	$(info nvc (for NVC))
	$(info gen (generic - for Questa, ModelSim etc))
	$(info vivado (for AMD/Xilinx Vivado))
	$(info )
	$(error No simulator specified)

################################################################################
# global definitions

# get file extension for executables on this OS
ifeq ($(OS),Windows_NT)
	EXE_EXT=.exe
endif

# key-value lookup shell command
define LOOKUP
LOOKUPS=($(1)); \
KEYS=($(2)); \
VALUES=($(3)); \
for i in $${!LOOKUPS[@]}; do \
    for j in $${!KEYS[@]}; do \
        if [[ "$${LOOKUPS[$$i]}" ==  "$${KEYS[$$j]}" ]]; then \
            echo "$${VALUES[$$j]}"; \
        fi; \
    done; \
done
endef

################################################################################
# GHDL definitions

GHDL=ghdl
GHDL_AOPTS=-fsynopsys
GHDL_EOPTS=
GHDL_ROPTS=--unbuffered

ifeq ($(VHDL_RELAXED),TRUE)
	GHDL_AOPTS:=-frelaxed $(GHDL_AOPTS)
	GHDL_EOPTS:=-frelaxed $(GHDL_EOPTS)
endif
ifeq ($(VHDL_STANDARD),2008)
	GHDL_AOPTS:=--std=08 $(GHDL_AOPTS)
	GHDL_EOPTS:=--std=08 $(GHDL_EOPTS)
endif
ifeq ($(VHDL_SUPPRESS_IEEE_ASSERTS),TRUE)
	GHDL_ROPTS:=$(GHDL_ROPTS) --ieee-asserts=disable
endif

################################################################################
# NVC definitions

NVC_WORK=nvc_work
NVC=nvc
NVC_GOPTS=--work=$(NVC_WORK)
NVC_AOPTS=
NVC_EOPTS=

ifeq ($(VHDL_RELAXED),TRUE)
	NVC_AOPTS:=$(NVC_AOPTS) --relaxed
endif
ifeq ($(VHDL_STANDARD),2008)
	NVC_GOPTS:=--std=08 $(NVC_GOPTS)
endif
ifdef $(VHDL_SUPPRESS_IEEE_ASSERTS)
	NVC_ROPTS:=$(GHDL_ROPTS) --ieee-warnings=off
endif

NVC_PREFIX=$(NVC_WORK)/$(shell echo $(NVC_WORK)| tr a-z A-Z).

################################################################################
# Questa, ModelSim etc definitions

GEN_WORK=gen_work
GEN_VCOM=vcom
GEN_VCOMOPTS=-work $(GEN_WORK) -explicit -vopt -stats=none
GEN_VCOM_LOG_EXT=vcom.log
GEN_VSIM=vsim
GEN_VSIMOPTS=-work $(GEN_WORK) -t ps -c -onfinish stop -do "onfinish exit; run -all"

ifeq ($(VHDL_STD),2008)
	GEN_VCOMOPTS:=$(GEN_VCOMOPTS) -2008
endif
ifdef $(VHDL_IEEE_ASSERTS)
	ifeq ($(VHDL_IEEE_ASSERTS),FALSE)
		GEN_VSIMOPTS=-t ps -c -onfinish stop -do "set NumericStdNoWarnings 1; onfinish exit; run -all"
	endif
endif

################################################################################
# runtime rule/recipe for analysis step (GHDL, NVC, Questa/ModelSim etc)

define UNIT

SIM_TOP=$(strip $(1))
SIM_UNITS=$(SIM_UNITS) $(strip $(1))

# GHDL: compiled file takes name from source file
GHDL_UNITS=$(GHDL_UNITS) $(notdir $(basename $(strip $(2)))).o
GHDL_UNIT_DEPS:=$(shell $(call LOOKUP,$(strip $(3)),$(SIM_UNITS),$(GHDL_UNITS)))
$(notdir $(basename $(strip $(2)))).o: $(strip $(2)) $(GHDL_UNIT_DEPS)
	$(GHDL) -a $(GHDL_AOPTS) $$<

# NVC: compiled file takes name from design unit
NVC_UNITS=$(NVC_UNITS) $(NVC_PREFIX)$(shell echo $(strip $(1))| tr a-z A-Z)
$(NVC_PREFIX)$(shell echo $(strip $(1))| tr a-z A-Z): $(strip $(2)) $(addprefix $(NVC_PREFIX),$(shell echo $(strip $(3))| tr a-z A-Z))
	$(NVC) $(NVC_GOPTS) -a $$< $(NVC_AOPTS)

# Questa, ModelSim etc: use log files to record compilation status
GEN_UNITS=$(GEN_UNITS) $(strip $(1)).$(GEN_VCOM_LOG_EXT)
$(strip $(1)).$(GEN_VCOM_LOG_EXT): $(strip $(2)) $(addsuffix .$(GEN_VCOM_LOG_EXT),$(strip $(3)))
	$(GEN_VCOM) $(GEN_VCOMOPTS) $$< >$(strip $(1)).$(GEN_VCOM_LOG_EXT)

endef

################################################################################
# end of file