# multisim-mk

Simple support for driving VHDL simulators from makefiles.

To get started:
1. Add multisim-mk to your repo as a submodule.
2. Copy the template makefile to your build directory and edit it to add your design units, sources, and dependancies.

When invoking make, the simulator must be specified (as a make target) as follows:

    make <simulator>

Supported simulators are listed below:

| \<simulator\> | Description     |
|---------------|-----------------|
| ghdl          | GHDL            |
| nvc           | NVC             |
| msq           | ModelSim/Questa |

## License

This file is part of multisim-mk. multisim-mk is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

multisim-mk is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with multisim-mk. If not, see https://www.gnu.org/licenses/.

