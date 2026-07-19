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

# FIXME: Some regular expressions used here are very inefficient.

# TODO:  Support formatting in tables.
# TODO:  Add an option to escape BBCode that the markdown file may contain.
# TODO:  Align text properly in tables.
# TODO:  Allow generation of BBCode for other Websites than Planet Casio.
# TODO:  Handle horizontal lines.
# FIXME: The tags for formatting inside of a paragraph are sometimes in the
#        wrong order.

# NOTE:  Formatting with underscores and Setext-style headers are not
#        supported.

my $header = 1;
my $quote = 0;

my $paragraph = "";

my $code_block = 0;
my $code = 0;
my $list = 0;
my $ordered = 0;

my @header_start = (
    '[color=DarkRed][big][big][b][i]',
    '[color=DarkRed][big][b][i]',
    '[color=DarkRed][b][i]',
    '[color=DarkRed][b]',
    '[color=DarkRed][i]',
    '[color=DarkRed]'
);

my @header_end = (
    '[/i][/b][/big][/big][/color]',
    '[/i][/b][/big][/color]',
    '[/i][/b][/color]',
    '[/b][/color]',
    '[/i][/color]',
    '[/color]'
);

sub format_paragraph {
    my $paragraph = shift;

    my @pieces = split /`/, $paragraph;

    my $new_paragraph = "";
    my $code = 0;

    my $bold = '[b]';
    my $italic = '[i]';
    my $strike = '[strike]';

    my $start_code = '[color=DarkRed][b]`';
    my $end_code = '`[/b][/color]';

    my $i = 0;
    foreach my $piece (@pieces) {
        if (!$code){
            while ($piece =~ s/\*\*/$bold/){
                unless ($bold =~ s/\[\//\[/){
                    $bold =~ s/\[([^\/])/\[\/$1/;
                }
            }
            while ($piece =~ s/\*/$italic/){
                unless ($italic =~ s/\[\//\[/){
                    $italic =~ s/\[([^\/])/\[\/$1/;
                }
            }
            while ($piece =~ s/~~/$strike/){
                unless ($strike =~ s/\[\//\[/){
                    $strike =~ s/\[([^\/])/\[\/$1/;
                }
            }
            $piece =~ s/!\[([^]]*)\]\(([^)]*)\)/\[img\]$2\[\/img\]/g;
            $piece =~ s/\[([^]]*)\]\(([^)]*)\)/\[url=$2\]$1\[\/url\]/g;
        }
        $new_paragraph .= "$piece";
        if ($i != $#pieces && !$code){
            $new_paragraph .= $start_code;
        }elsif($code){
            $new_paragraph .= $end_code;
        }

        $code = !$code;
        $i++;
    }

    if ($bold =~ /\[\//){
        $new_paragraph .= $bold;
    }
    if ($italic =~ /\[\//){
        $new_paragraph .= $italic;
    }
    if ($strike =~ /\[\//){
        $new_paragraph .= $strike;
    }

    return $new_paragraph;
}

sub output_paragraph {
    my $paragraph = shift;

    $paragraph = format_paragraph $paragraph;

    print "$paragraph\n\n";
}

sub output_paragraph_inline {
    my $paragraph = shift;

    $paragraph = format_paragraph $paragraph;

    print "$paragraph";
}

while (<>) {
    # Handle quotes
    s/^((( {0,3}|\t)\>)+) ?//;
    my $indent = () = $1 =~ /\>/g;
    while ($indent > $quote){
        if ($paragraph ne ""){
            output_paragraph $paragraph;
            $paragraph = "";
        }
        if ($code){
            print '[/code]';
            $code = 0;
        }
        print "\[quote\]\n";
        $quote++;
    }
    while ($indent < $quote){
        if ($paragraph ne ""){
            output_paragraph $paragraph;
            $paragraph = "";
        }
        if ($code){
            print '[/code]';
            $code = 0;
        }
        print "\[\/quote\]\n";
        $quote--;
    }

    # Handle code
    if (!$code_block && !$list && s/^( {4}|\t)//){
        if (!$code){
            if ($paragraph ne ""){
                output_paragraph $paragraph;
                $paragraph = "";
            }
            print "\[code\]";
        }
        $code = 1;
    }elsif ($code){
        print "\[\/code\]\n";
        $code = 0;
    }

    if ($code_block && /^```/){
        print "\[\/code\]\n";
        $code_block = 0;
        next;
    }

    if ($code || $code_block){
        print;
        next;
    }

    if (!$code_block && /^```/){
        if ($paragraph ne ""){
            output_paragraph $paragraph;
            $paragraph = "";
        }
        print "\[code\]";
        $code_block = 1;
        next;
    }

    # Handle headers
    if (/^#+/){
        if ($paragraph ne ""){
            output_paragraph $paragraph;
            $paragraph = "";
        }
        s/^(#{0,6})[[:space:]]*//;
        $level = () = $1 =~ /#/g;
        s/[[:space:]]*#*$//;

        print $header_start[$level-1];
        chomp;
        output_paragraph_inline $_;
        print $header_end[$level-1];
        print "\n\n";

        $_ = "";
    }

    # Handle lists
    if (((!$list && $paragraph eq "") || $list)
        && s/^([[:space:]]*)([0-9]+.|[*+-])[[:space:]]+//){
        my $type = $2;
        $indent = () = $1 =~ / {4}/g;
        $indent++;
        if ($paragraph ne ""){
            output_paragraph_inline $paragraph;
            $paragraph = "";
        }
        if (!$list){
            if ($type =~ /[*+-]/){
                print "\[list\]\n";
                $list++;
                $ordered = 0;
            }else{
                print "\[list=ol\]\n";
                $list++;
                $ordered = 1;
            }
            print "\[li\]";
        }else{
            print "\[\/li\]\n";
            if ($type =~ /[*+-]/){
                if ($ordered && $list == $indent){
                    print "\[\/list\]\n";
                    print "\[list\]\n";
                }

                while($list > $indent){
                    print "\[\/list\]\n";
                    $list--;
                }
                while($list < $indent){
                    print "\[list\]\n";
                    $list++;
                }
                $ordered = 0;
            }else{
                if (!$ordered && $list == $indent){
                    print "\[\/list\]\n";
                    print "\[list=ol\]\n";
                }

                while($list > $indent){
                    print "\[\/list\]\n";
                    $list--;
                }
                while($list < $indent){
                    print "\[list=ol\]\n";
                    $list++;
                }
                $ordered = 1;
            }
            print "\[li\]";
        }
    }

    # Handle tables
    if (/(\|[[:space:]]*:?-{3,}:?[[:space:]]*)+\|/){
        $header = 0;
    }elsif (/(\|[^|]+)+\|/){
        s/\|$//;
        if ($header){
            s/\|([^\|\n]+)/\[th\]$1\[\/th\]/g;
            if ($paragraph ne ""){
                output_paragraph $paragraph;
                $paragraph = "";
            }
            print "[table]\n";
        }else{
            s/\|([^\|\n]+)/\[td\]$1\[\/td\]/g;
        }
        print "[tr]$_\[\/tr\]\n";
    }else{
        if (!$header){
            print "\[\/table\]\n";
        }
        $header = 1;
        if (/^[[:space:]]*$/ && $paragraph ne ""){
            if ($list){
                output_paragraph_inline $paragraph;
                print "\[\/li\]\n";
                while($list){
                    print "\[\/list\]\n";
                    $list--;
                }
            }else{
                output_paragraph $paragraph;
            }
            $paragraph = "";
        }
        chomp;
        s/  $/\n/;
        s/([^\n])$/$1 /m;
        $paragraph .= $_;
    }
}
# End a table that wasn't closed yet
if (!$header){
    print "\[\/table\]\n";
}elsif ($paragraph ne ""){
    output_paragraph $paragraph;
}
