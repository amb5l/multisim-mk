################################################################################
# template makefile                                                            #
# See https://github.com/amb5l/multisim-mk                                     #
################################################################################

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SUBMODULES=$(REPO_ROOT)/submodules
MULTISIM_MK=$(SUBMODULES)/multisim-mk

################################################################################
# preferences

# VHDL language standard: 1993 or 2008
VHDL_STANDARD=2008

# VHDL relaxed rules e.g. allow impure behaviour in pure functions
# comment out if not required
VHDL_RELAXED=TRUE

# suppress warnings from IEEE library units e.g. to_integer metavalues
# comment out if not required
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

################################################################################

# place before design unit declarations
include $(MULTISIM_MK)/multisim_pre.mk

################################################################################
# design units and their dependancies are declared here as follows:
# $(eval $(call UNIT, unit_name, source_file, dependencies ))
#
# where
#   unit_name = design unit (entity or package name)
#   source_file = VHDL source file
#   dependancies = whitespace separated list of design units (or empty)
#
# ensure units appear in the correct compilation order

# example:

SRC=$(REPO_ROOT)/src

$(eval $(call UNIT, my_pkg  , $(SRC)/my_design/my_pkg.vhd  ,                ))
$(eval $(call UNIT, my_comp , $(SRC)/my_design/my_comp.vhd , my_pkg         ))
$(eval $(call UNIT, my_top  , $(SRC)/my_design/my_comp.vhd , my_comp my_pkg ))

################################################################################

# place after design unit declarations
include $(MULTISIM_MK)/multisim_post.mk

################################################################################
# Run setup - simple example. Keep this or the one below, not both.

$(eval $(call RUN))

################################################################################
# Run setup - complex example. Testbench reads in binary files and outputs BMP
# files that you want to check against known good ones. The TB entity has
# generics that specify the files. We run the testbench once for each test
# case.

# Input, output and comparison (known good) files.
TESTS=test1 test2 test3
DATA_DIR=$(SRC)/my_design/data
INFILES=$(addprefix $(DATA_DIR)/,$(addsuffix .bin,$(TESTS)))
OUTFILES=$(addsuffix .bmp,$(TESTS))
CMPFILES=$(addprefix $(DATA_DIR)/,$(addsuffix .bmp,$(TESTS)))

# Here we generate rules/recipes for the output file for each test case.
# Make sure you include $(RUN_DEP) as a prerequsite in rules that invoke
# simulation. Note the call to RUN_GEN to run the simulation with specified
# generics (no spaces, semicolon seperator). Note also the use of the useful
# LOOKUP function.
define RR_OUTFILE
$1: $2 $(RUN_DEP)
	$(call RUN_GEN,infile=$2;outfile=$(basename $1))
endef
$(foreach OUTFILE,$(OUTFILES),$(eval $(call RR_OUTFILE,$(OUTFILE),$(call LOOKUP,$(OUTFILE),$(OUTFILES),$(INFILES)))))

# Here we generate the rules/recipes for the comparison files: these will be
# out of date until touched after a successful comparison. Their prerequisites
# are the corresponding output files.
define RR_CMPFILE
$1: $2
	diff --binary $$@ $$<
	touch $$@
endef
$(foreach CMPFILE,$(CMPFILES),$(eval $(call RR_CMPFILE,$(CMPFILE),$(call LOOKUP,$(CMPFILE),$(CMPFILES),$(OUTFILES)))))

# You must include this rule - it's a prerequisite of the rules named after
# the supported simulators (e.g. ghdl). In this case its prerequisites are
# the comparison (known good) BMP files.
run: $(CMPFILES)

################################################################################
# add supplementary clean recipes here

# example: for BMP files...
clean::
    rm -f *.bmp

################################################################################
# end of file