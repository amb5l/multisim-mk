# template makefile
# See https://github.com/amb5l/multisim-mk

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SUBMODULES=$(REPO_ROOT)/submodules
MULTISIM_MK=$(SUBMODULES)/multisim-mk
SRC=$(REPO_ROOT)/src

# list sources in compilation order here
SOURCES=\
	$(SRC)/dut.vhd \
	$(SRC)/testbench.vhd

# sets of top level generics; simulation is repeated for each set
#GENERICS=gen1=1;gen2=2 gen1=3;gen2=4

# top unit name
TOP=testbench

# VHDL language standard: 1993 or 2008
VHDL_STANDARD=2008

# relaxed rules e.g. allow impure behaviour in pure functions
VHDL_RELAXED=TRUE

# suppress warnings from IEEE library units e.g. to_integer metavalues
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

# user prerequisites e.g. files to be read by simulation
#sim:: $(USER_FILES)

# GHDL libraries
#GHDL_LIBS=xilinx-vivado

# larger heap size for NVC
#NVC_GOPTS:=-H 32m

# include multisim.mk here
include $(MULTISIM_MK)/multisim.mk

# recipes to run after simulation, for example:
#sim::
#	diff --binary sim_output_file known_good_file

# add supplementary clean recipes here, for example:
#clean::
#	rm -f *.bin
