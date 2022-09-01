################################################################################
# multisim_pre.mk															   #
# See https://github.com/amb5l/multisim-mk									   #
# include this in your makefile before your unit declarations				   #
################################################################################
# error if simulator not specified

all:
	$(info )
	$(info Please specify your chosen simulator after 'make' as follows:)
	$(info make <simulator>)
	$(info )
	$(info Supported options for <simulator>:)
	$(info ghdl (for GHDL))
	$(info nvc (for NVC))
	$(info msq (for ModelSim/Questa))
	$(info )
	$(error No simulator specified)

################################################################################
# global definitions

SIM=$(MAKECMDGOALS)

# get file extension for executables on this OS
ifeq ($(OS),Windows_NT)
	EXE_EXT=.exe
endif

# key-value lookup
LOOKUP=$(word 2,$(subst ;, ,$(filter $1;%,$(join $2,$(addprefix ;,$3)))))

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

NVC_WORK=work
NVC_WORK_DIR=nvc_work
NVC_WORK_NAME=$(shell echo $(NVC_WORK)| tr a-z A-Z)
NVC=nvc
NVC_GOPTS=--work=$(NVC_WORK):$(NVC_WORK_DIR)
NVC_AOPTS=
NVC_EOPTS=
NVC_ROPTS=

ifeq ($(VHDL_RELAXED),TRUE)
	NVC_AOPTS:=$(NVC_AOPTS) --relaxed
endif
ifeq ($(VHDL_STANDARD),2008)
	NVC_GOPTS:=--std=08 $(NVC_GOPTS)
endif
ifeq ($(VHDL_SUPPRESS_IEEE_ASSERTS),TRUE)
	NVC_ROPTS:=$(NVC_ROPTS) --ieee-warnings=off
endif

NVC_PREFIX=$(NVC_WORK_DIR)/$(NVC_WORK_NAME).

################################################################################
# Questa, ModelSim etc definitions

MSQ_WORK=msq_work
MSQ_VCOM=vcom
MSQ_VCOMOPTS=-work $(MSQ_WORK) -explicit -vopt -stats=none
MSQ_VCOM_LOG_EXT=vcom.log
MSQ_VSIM=vsim
MSQ_VSIMOPTS=-work $(MSQ_WORK) -t ps -c -onfinish stop -do "onfinish exit; run -all"

ifeq ($(VHDL_STANDARD),2008)
	MSQ_VCOMOPTS:=$(MSQ_VCOMOPTS) -2008
endif
ifeq ($(VHDL_SUPPRESS_IEEE_ASSERTS),TRUE)
	MSQ_VSIMOPTS:=-do "set NumericStdNoWarnings 1" $(MSQ_VSIMOPTS)
endif

################################################################################
# runtime rule/recipe for analysis step (GHDL, NVC, Questa/ModelSim etc)

define UNIT

SIM_TOP=$(strip $(1))
SIM_UNITS=$(SIM_UNITS) $(strip $(1))

# GHDL: compiled file takes name from source file
GHDL_UNITS=$(GHDL_UNITS) $(notdir $(basename $(strip $(2)))).o
GHDL_UNIT_DEPS=
$(foreach K,$(strip $(3)),$(eval GHDL_UNIT_DEPS=$(GHDL_UNIT_DEPS) $(call LOOKUP,$K,$(SIM_UNITS),$(GHDL_UNITS))))
$(notdir $(basename $(strip $(2)))).o: $(strip $(2)) $(GHDL_UNIT_DEPS)
	$(GHDL) -a $(GHDL_AOPTS) $$<

# NVC: compiled file takes name from design unit
NVC_UNITS=$(NVC_UNITS) $(NVC_PREFIX)$(shell echo $(strip $(1))| tr a-z A-Z)
$(NVC_PREFIX)$(shell echo $(strip $(1))| tr a-z A-Z): $(strip $(2)) $(addprefix $(NVC_PREFIX),$(shell echo $(strip $(3))| tr a-z A-Z))
	$(NVC) $(NVC_GOPTS) -a $$< $(NVC_AOPTS)

# Questa, ModelSim etc: use log files to record compilation status
MSQ_UNITS=$(MSQ_UNITS) $(strip $(1)).$(MSQ_VCOM_LOG_EXT)
$(strip $(1)).$(MSQ_VCOM_LOG_EXT): $(strip $(2)) $(addsuffix .$(MSQ_VCOM_LOG_EXT),$(strip $(3)))
	$(MSQ_VCOM) $(MSQ_VCOMOPTS) $$< >$(strip $(1)).$(MSQ_VCOM_LOG_EXT)

endef

################################################################################
# end of file