################################################################################
# https://github.com/amb5l/multisim-mk
# Simple support for driving VHDL simulations from makefiles.
# Supported simulators: GHDL, NVC, ModelSim, Questa, Vivado
# Supported waveform viewers: GTKWave
# Supported platforms: Linux, Windows/MSYS2
# Notes:
#  1) For Vivado support, https://github.com/amb5l/xilinx-mk is required.
#  2) For GTKWave support, https://github.com/amb5l/vcd2gtkw is recommended.
################################################################################
# check for supported simulator

SIM:=$(word 1,$(MAKECMDGOALS))
ifeq ($(filter $(SIM),ghdl nvc modelsim questa vivado clean),)
INDENT:=$(subst ,,  )
all:
	$(info )
	$(info Please specify your chosen simulator after 'make' as follows:)
	$(info $(INDENT)make <simulator>)
	$(info )
	$(info Supported options for <simulator>:)
	$(info $(INDENT)ghdl)
	$(info $(INDENT)nvc)
	$(info $(INDENT)questa)
	$(info $(INDENT)modelsim)
	$(info $(INDENT)vivado (project mode))
	$(info $(INDENT)xsim (non project mode))
	$(info )
	$(info Append gtkwave to your make command to invoke GTKWave following simulation:)
	$(info $(INDENT)make <simulator> gtkwave)
	$(info )
	$(error Unspecified or unsupported simulator)
endif

################################################################################
# global definitions

.PHONY: sim

# path to this makefile include
MULTISIM_MK:=$(lastword $(MAKEFILE_LIST))

# Windows/MSYS2 specific
ifeq ($(OS),Windows_NT)
# executable file extension
DOT_EXE=.exe
# check for MSYS2
ifeq ($(findstring msys,$(shell make --version)),)
$(info make executable: $(shell which make))
$(info $(shell make --version))
$(error not running MSYS2 make)
endif
endif

# VHDL standard defaults to 1993
ifeq ($(VHDL_STANDARD),)
VHDL_STANDARD:=1993
endif

# valid options for VHDL_STANDARD are 1993 and 2008 (common to all simulators)
ifneq ($(VHDL_STANDARD),1993)
ifneq ($(VHDL_STANDARD),2008)
$(error Unsupported VHDL standard: $(VHDL_STANDARD))
endif
endif

# work library name defaults to 'work'
ifeq ($(WORK),)
WORK:=work
endif

# number of runs = 1 or number of generic sets
RUNS=
$(foreach GEN,$(GENERICS),$(eval RUNS=$(RUNS) $(shell echo $$(($(lastword $(RUNS))+1)))))
ifeq ($(RUNS),)
RUNS=1
endif

# useful for cross referencing
LOOKUP=$(word 2,$(subst ¬, ,$(filter $1¬%,$(join $2,$(addprefix ¬,$3)))))

# check executable in path
define check_exe
$(if $(filter $1,$(notdir $(word 1,$(shell which $1 2>&1)))),,$(error $1 executable not found in path))
endef

################################################################################
# VCD waveform viewer support

ifneq ($(filter gtkwave,$(MAKECMDGOALS)),)

.PHONY: gtkwave

# executable
ifeq ($(GTKWAVE),)
GTKWAVE:=$(word 1,$(shell which gtkwave 2>&1))
endif
ifneq (gtkwave,$(basename $(notdir $(GTKWAVE))))
$(info )
$(error gtkwave executable not in path)
endif

# waveform file(s)
ifeq ($(VCD),)
ifeq ($(RUNS),1)
VCD:=wave.vcd
else
VCD=$(addsuffix .vcd,$(addprefix wave,$(RUNS)))
endif
endif

# check number of waveform files = number of generic sets
ifneq ($(words $(VCD)),$(words $(GENERICS)))
ifneq ($(GENERICS),)
$(info )
$(error Number of VCD filenames must match number of generic sets)
endif
endif

# path to vcd2gtkw script
# assume it is at same level of filesystem hierarchy as multisim-mk by default
ifeq ($(VCD2GTKW),)
VCD2GTKW=$(dir $(MULTISIM_MK))../vcd2gtkw/vcd2gtkw.sh
endif

# check for existence of vcd2gtkw script and use it if found
ifneq ($(wildcard $(VCD2GTKW)),)
# waveform save file
ifeq ($(GTKW),)
GTKW:=$(addsuffix .gtkw,$(basename $(VCD)))
endif
ifeq ($(VCD_LEVELS),)
VCD_LEVELS:=0
endif
$(GTKW): $(VCD)
	$(foreach W,$(VCD),$(VCD2GTKW) $W $(addsuffix .gtkw,$(basename $W)) $(VCD_LEVELS) ;)
gtkwave: $(GTKW)
	$(GTKWAVE) $(word 1, $(VCD)) $(word 1,$(GTKW))
else
gtkwave: $(VCD)
	$(GTKWAVE) $(word 1, $(VCD))
endif

else

VCD:=

endif

################################################################################

# timestamp at start of compile/run simulation
sim::
	@date "+%Y-%m-%d %H:%M:%S"

################################################################################
# GHDL simulator support

ifeq ($(SIM),ghdl)

.PHONY: ghdl

# executable
GHDL=ghdl
$(eval $(call check_exe,$(GHDL)))

# installation path
ifeq ($(GHDL_PREFIX),)
GHDL_PREFIX:=$(dir $(shell which $(GHDL)))..
endif

# options: analysis, elaboration, run
ifeq ($(VHDL_STANDARD),2008)
GHDL_STD:=08
else ifeq ($(VHDL_STANDARD),1993)
GHDL_STD:=93
endif
GHDL_AOPTS:=$(GHDL_AOPTS) --std=$(GHDL_STD) -fsynopsys -Wno-hide -Wno-shared $(addprefix -P$(GHDL_PREFIX)/lib/ghdl/vendors/,$(GHDL_LIBS))
GHDL_EOPTS:=$(GHDL_EOPTS) --std=$(GHDL_STD) -fsynopsys $(addprefix -P$(GHDL_PREFIX)/lib/ghdl/vendors/,$(GHDL_LIBS))
GHDL_ROPTS:=$(GHDL_ROPTS) --unbuffered --max-stack-alloc=0
ifeq ($(VHDL_RELAXED),TRUE)
GHDL_AOPTS:=$(GHDL_AOPTS) -frelaxed
GHDL_EOPTS:=$(GHDL_EOPTS) -frelaxed
endif
ifeq ($(VHDL_SUPPRESS_IEEE_ASSERTS),TRUE)
GHDL_ROPTS:=$(GHDL_ROPTS) --ieee-asserts=disable
endif

# compile and run
sim::
	$(GHDL) -a --work=$(WORK) $(GHDL_AOPTS) $(SOURCES)
ifeq ($(GENERICS),)
	$(GHDL) --elab-run --work=$(WORK) $(GHDL_EOPTS) $(TOP) $(GHDL_ROPTS) $(addprefix --vcd=,$(VCD))
else
define RR_SIMGEN
sim::
	$(GHDL) --elab-run --work=$(WORK) $(GHDL_EOPTS) $(TOP) $(GHDL_ROPTS) $(addprefix --vcd=,$2) $(strip $(addprefix -g,$(subst ;, ,$1)))
endef
$(foreach RUN,$(RUNS),$(eval $(call RR_SIMGEN,$(call LOOKUP,$(RUN),$(RUNS),$(GENERICS)),$(call LOOKUP,$(RUN),$(RUNS),$(VCD)))))
endif

ghdl: sim

endif

################################################################################
# NVC simulator support

ifeq ($(SIM),nvc)

.PHONY: nvc

# executable
NVC=nvc
$(eval $(call check_exe,$(NVC)))

# VHDL standard
NVC_STD:=$(VHDL_STANDARD)

# options: global, analysis, elaboration, run
NVC_GOPTS:=$(NVC_GOPTS) --std=$(NVC_STD)
NVC_AOPTS:=$(NVC_AOPTS)
NVC_EOPTS:=$(NVC_EOPTS)
NVC_ROPTS:=$(NVC_ROPTS)
ifeq ($(VHDL_RELAXED),TRUE)
NVC_AOPTS:=$(NVC_AOPTS) --relaxed
endif
ifeq ($(VHDL_SUPPRESS_IEEE_ASSERTS),TRUE)
NVC_ROPTS:=$(NVC_ROPTS) --ieee-warnings=off
endif

# compile and run
sim::
	$(NVC) $(NVC_GOPTS) --work=$(WORK) -a $(NVC_AOPTS) $(SOURCES)
ifeq ($(GENERICS),)
	$(NVC) $(NVC_GOPTS) --work=$(WORK) -e $(TOP) $(NVC_EOPTS)
	$(NVC) $(NVC_GOPTS) --work=$(WORK) -r $(TOP) $(NVC_ROPTS) $(addprefix --format=vcd --wave=,$(VCD))
else
define RR_SIMGEN
sim::
	$(NVC) $(NVC_GOPTS) --work=$(WORK) -e $(TOP) $(NVC_EOPTS) $(strip $(addprefix -g,$(subst ;, ,$1)))
	$(NVC) $(NVC_GOPTS) --work=$(WORK) -r $(TOP) $(NVC_ROPTS) $(addprefix --format=vcd --wave=,$2)
endef
$(foreach RUN,$(RUNS),$(eval $(call RR_SIMGEN,$(call LOOKUP,$(RUN),$(RUNS),$(GENERICS)),$(call LOOKUP,$(RUN),$(RUNS),$(VCD)))))
endif

nvc: sim

endif

################################################################################
# ModelSim/Questa simulator support

ifneq ($(filter $(SIM),modelsim questa),)

.PHONY: modelsim questa

# executables
VCOM=vcom
$(eval $(call check_exe,$(VCOM)))
VSIM=vsim
$(eval $(call check_exe,$(VSIM)))

# VHDL standard
ifeq ($(VHDL_STANDARD),2008)
VHDL_STD:=2008
else ifeq ($(VHDL_STANDARD),1993)
VHDL_STD:=93
endif

# default path to user compiled libraries
ifeq ($(OS),Windows_NT)
ifeq ($(HOME),)
SIM_LIB_PATH:=/c/work/.simlib
else
SIM_LIB_PATH:=$(shell cygpath $(HOME))/.simlib
endif
else
SIM_LIB_PATH:=~/.simlib
endif

# command options
VCOMOPTS:=$(VCOMOPTS) -$(VHDL_STD) -explicit -vopt -stats=none
VSIM:=vsim
VSIMTCL:=onfinish exit; run -all; exit
ifeq ($(VHDL_SUPPRESS_IEEE_ASSERTS),TRUE)
VSIMTCL:=set NumericStdNoWarnings 1; $(VSIMTCL)
endif
VSIMOPTS:=$(VSIMOPTS) -t ps -c -onfinish stop -do "$(VSIMTCL)"

# compile and run
VSIMVCD:=
ifneq ($(VCD),)
VSIMVCD:=-do "vcd file $(VCD); vcd add -r *"
endif
sim::
	$(VCOM) -work $(WORK) $(VCOMOPTS) $(SOURCES)
ifeq ($(GENERICS),)
	$(VSIM) -work $(WORK) $(VSIMVCD) $(VSIMOPTS) $(TOP)
else
define RR_SIMGEN
ifneq ($2,)
VSIMVCD:=-do "vcd file $2; vcd add -r *"
endif
sim::
	$(VSIM) -work $(WORK) $(VSIMVCD) $(VSIMOPTS) $(TOP) $(strip $(addprefix -g,$(subst ;, ,$1)));
endef
$(foreach RUN,$(RUNS),$(eval $(call RR_SIMGEN,$(call LOOKUP,$(RUN),$(RUNS),$(GENERICS)),$(call LOOKUP,$(RUN),$(RUNS),$(VCD)))))
endif

modelsim questa: sim

endif

################################################################################
# Xilinx Vivado simulator support (project mode)

ifeq ($(SIM),vivado)

.PHONY: vivado

$(eval $(call check_exe,vivado))

# path to xilinx-mk
# assume it is at same level of filesystem hierarchy as multisim-mk by default
ifeq ($(XILINX_MK),)
XILINX_MK=$(dir $(MULTISIM_MK))../xilinx-mk
endif
VIVADO_MK=vivado -mode tcl -notrace -nolog -nojournal -source $(XILINX_MK)/vivado_mk.tcl -tclargs xsim xsim

# compile and run
sim::
ifeq ($(VHDL_STANDARD),2008)
	$(VIVADO_MK) create VHDL none sim_vhdl_2008: $(SOURCES) sim_top: $(TOP)
else ifeq ($(VHDL_STANDARD),1993)
	$(VIVADO_MK) create VHDL none sim_vhdl: $(SOURCES) sim_top: $(TOP)
endif
ifeq ($(GENERICS),)
	$(VIVADO_MK) simulate $(addprefix vcd: ../../../../../,$(VCD))
else
define RR_SIMGEN
sim::
	$(VIVADO_MK) simulate gen: $(strip $(subst ;, ,$1)) $(addprefix vcd: ../../../../../,$2)
endef
$(foreach RUN,$(RUNS),$(eval $(call RR_SIMGEN,$(call LOOKUP,$(RUN),$(RUNS),$(GENERICS)),$(call LOOKUP,$(RUN),$(RUNS),$(VCD)))))
endif

vivado: sim

endif

################################################################################
# Xilinx Vivado simulator support (non project mode)

ifeq ($(SIM),xsim)

.PHONY: xsim

# executables
XVHDL=xvhdl
$(eval $(call check_exe,$(XVHDL)))
XELAB=xelab
$(eval $(call check_exe,$(XVHDL)))
XSIM=xsim
$(eval $(call check_exe,$(XSIM)))

# options
XVHDL_OPTS:=$(if $(filter 2008,$(VHDL_STANDARD)),--2008,)
XELAB_OPTS:=--debug typical --O2
XSIM_OPTS:=-runall --onerror quit --onfinish quit
ifneq ($(VHDL_RELAXED),)
XVHDL_OPTS:=$(XVHDL_OPTS) --relax
XELAB_OPTS:=$(XELAB_OPTS) --relax
endif
ifeq ($(VHDL_SUPPRESS_IEEE_ASSERTS),)
XSIM_OPTS:=$(XSIM_OPTS) --ieeewarnings
endif

# compile and run
sim::
ifeq ($(OS),Windows_NT)
	cmd.exe /C "call $(XVHDL).bat $(XVHDL_OPTS) --work $(WORK) $(SOURCES)"
else
	$(XVHDL) $(XVHDL_OPTS) --work $(WORK) $(SOURCES)
endif
ifeq ($(GENERICS),)
ifeq ($(OS),Windows_NT)
	cmd.exe /C "call $(XELAB).bat $(XELAB_OPTS) -top $(TOP) -snapshot $(TOP)_snapshot"
	cmd.exe /C "call $(XSIM).bat $(XSIM_OPTS) $(addprefix --vcdfile ,$(VCD)) $(TOP)_snapshot"
else
	$(XELAB) $(XELAB_OPTS) -top $(TOP) -snapshot $(TOP)_snapshot
	$(XSIM) $(XSIM_OPTS) $(addprefix --vcdfile ,$(VCD)) $(TOP)_snapshot
endif
else
define RR_SIMGEN
sim::
ifeq ($(OS),Windows_NT)
	cmd.exe /C "call $(XELAB).bat --debug typical --O2 --relax -L work --snapshot cfg_tb_hdmi_tpg_snapshot1 cfg_tb_hdmi_tpg $(addprefix -generic_top \",$(addsuffix \",$(subst ;, ,$2)))"
	cmd.exe /C "call $(XSIM).bat $(XSIM_OPTS) $(addprefix --vcdfile ,$3) $(TOP)_snapshot$1"
else
	$(XELAB) --debug typical --O2 --relax -L work --snapshot cfg_tb_hdmi_tpg_snapshot1 cfg_tb_hdmi_tpg $(addprefix -generic_top \",$(addsuffix \",$(subst ;, ,$2)))
	$(XSIM) $(XSIM_OPTS) $(addprefix --vcdfile ,$3) $(TOP)_snapshot$1
endif
endef
$(foreach RUN,$(RUNS),$(eval $(call RR_SIMGEN,$(RUN),$(call LOOKUP,$(RUN),$(RUNS),$(GENERICS)),$(call LOOKUP,$(RUN),$(RUNS),$(VCD)))))
endif

xsim: sim

endif

################################################################################

# timestamp at end of compile/run simulation
sim::
	@date "+%Y-%m-%d %H:%M:%S"

################################################################################
# cleanup (user makefile may add further recipes)

.PHONY: clean

# GHDL
clean::
	rm -f $(TOP) $(TOP).exe $(wildcard *.cf) $(wildcard *.o) $(wildcard *.lst)

# NVC, ModelSim, Questa
clean::
	rm -rf $(WORK)

# ModelSim, Questa
clean::
	rm -f modelsim.ini transcript $(wildcard *.vstf)

# Vivado (project mode)
clean::
	rm -f .Xil
	rm -rf xsim

# Vivado (non project mode)
clean::
	rm -f $(wildcard *.jou) $(wildcard *.log) $(wildcard *.pb) $(wildcard *.wdb)
	rm -rf xsim.dir

# waveform
clean::
	rm -f $(wildcard *.vcd) $(wildcard *.gtkw)
