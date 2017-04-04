#!/usr/bin/perl

#    StrEmbed-4 - Embedding assembly structure on to a corresponding hypercube lattice
#    Copyright (C) 2017  University of Leeds
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

# StrEmbed-4.pl
# StrEmbed-4 release pre-A - HHC 2017-03-31
# HHC - 2017-03-07
# HHC - 2017-03-24

require 5.002;
use warnings;
use strict;
use StrEmbed::StrEmbed_4_hypercube;
use StrEmbed::StrEmbed_4_gui;
use StrEmbed::StrEmbed_4_step;
use StrEmbed::StrEmbed_4_tree_editor;

&tk_mainloop;