# multisim-mk

Simple support for driving VHDL simulators from makefiles on Linux and Windows/MSYS2.

To get started: add `multisim-mk` to your repo as a submodule, copy the template makefile to your build directory, and edit it to add your sources.

When invoking make, the simulator must be specified (as a make target) as follows:

    make <simulator>

Supported simulators are listed below:

| \<simulator\> | Description                                    |
|---------------|------------------------------------------------|
| ghdl          | [GHDL](https://ghdl.free.fr/)                  |
| nvc           | [NVC](https://www.nickg.me.uk/nvc/)            |
| vsim          | uses vcom/vsim commands (ModelSim, Questa etc) |
| vivado        | Xilinx Vivado (project mode)                   |
| xsim          | Xilinx Vivado (non project mode)               |

Append `gtkwave` to the make command (e.g. `make ghdl gtkwave`) to produce VCD file(s) and invoke the GTKWave waveform viewer after simulation.

If the `vivado` target is specified, a Vivado project is generated that may be opened in the IDE.

**Note:** Beware running the Vivado "settings" script on Windows: this will prepend paths that include Xilinx MinGW builds of GNU tools to the system path, and stop multisim-mk from working. Instead, just add the main Vivado binary directory to your path.

## Dependancies

1) For the `vivado` target, https://github.com/amb5l/xilinx-mk is required.
3) For GTKWave support, https://github.com/amb5l/vcd2gtkw is recommended - this generates an initial waveform save file.

## License

This file is part of multisim-mk. multisim-mk is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

multisim-mk is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with multisim-mk. If not, see https://www.gnu.org/licenses/.

