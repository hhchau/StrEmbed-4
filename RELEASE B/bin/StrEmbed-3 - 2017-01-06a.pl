#!/usr/bin/perl

#    StrEmbed-3 - Embedding assembly structure on to a corresponding hypercube lattice
#    Copyright (C) 2016  University of Leeds
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# HHC - 2016-10-23
# usage: hypercube.pl n
#        where n as in 2^n hypercube
# HHC - 2016-11-03 - joanna_lang_approach.pl efficient version using binary encording
# HHC - 2016-11-14
# HHC - 2016-11-18 - double_up_double_up.pl
# HHC - 2016-11-21 - perl module is now StrEmbed::hypercube_binary_encoding
# HHC - 2016-11-23 - hypercube_bin_encoding_only
# HHC - 2016-11-29 - hypercube_sorted.pl - StrEmbed/hypercube_sorted_binary_encoded.pm
# HHC - 2016-11-29 - StrEmbed3.pl <- StrEmbed3_lattice.pm + StrEmbed3_gui.pm + StrEmbed3_STEP.pm
# HHC - 2016-12-05 - added chase.pl (version 2016-09-01) date stamp 02/09/2016 15:49
#                  - to StrEmbed::hypercube_step.pm
# HHC - 2016-12-06 - filename is now StrEmbed-3.pl
# HHC - 2016-12-10 - changed directory tree structure, ready to be uploaded to GitHub
# HHC - 2016-12-19 - main programme does not share variable $max
# HHC - 2017-01-03 - back in Leeds

require 5.002;
use warnings;
use strict;
use StrEmbed::StrEmbed_3_hypercube;
use StrEmbed::StrEmbed_3_gui;
use StrEmbed::StrEmbed_3_step;
use StrEmbed::StrEmbed_3_tree_editor;

&tk_mainloop;