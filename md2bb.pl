#!/usr/bin/perl

# md2bb.pl -- A small markdown to BBCode converter.
# by Mibi88
#
# This software is licensed under the BSD-3-Clause license:
#
# Copyright 2026 Mibi88
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# FIXME: Some (non-)regular expressions used here are very inefficient.

my $text = "";

my $header = 1;
my $quote = 0;

while (<>) {
    # Handle quotes
    s/^((( {0,3}|\t)\>)+) ?//;
    my $indent = () = $1 =~ /\>/g;
    while($indent > $quote){
        print "\[quote\]\n";
        $quote++;
    }
    while($indent < $quote){
        print "\[\/quote\]\n";
        $quote--;
    }

    # Handle tables
    if(/(\|[[:space:]]*:?-{3,}:?[[:space:]]*)+\|/){
        $header = 0;
    }elsif(/(\|[^|]+)+\|/){
        s/\|$//;
        s/\|([^\|\n]+)/\[td\]$1\[\/td\]/g;
        if ($header){
            print "[table]\n";
            print "[th]$_\[\/th\]\n";
        }else{
            print "[tr]$_\[\/tr\]\n";
        }
    }else{
        if(!$header){
            print "\[\/table\]\n";
        }
        $header = 1;
        print;
    }
}
# End a table that wasn't closed yet
if(!$header){
    print "\[\/table\]\n";
}
