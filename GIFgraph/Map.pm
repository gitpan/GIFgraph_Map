package GIFgraph::Map;

use GIFgraph::axestype;
use GIFgraph::utils qw(:all);
use strict qw(vars subs refs);
use vars qw(@EXPORT_OK $VERSION);
require Exporter;

@GIFgraph::Map::ISA = qw(Exporter);
@EXPORT_OK = qw(set imagemap);
$VERSION = 1.01;

#--------------------------------------------- set defaults
my $ANGLE_OFFSET = 90;
my %Defaults = ( #Default Href is JavaScript code, which do nothing
                 href   => 'javascript:;',
		 hrefs  => [],
		 lhrefs => [],
		 #Open new navigator window? 
		 newWindow          => 0,
		 window_height      => 0,
		 window_width       => 0,
		 window_resizeable  => 0,
		 window_toolbar     => 0,
		 window_location    => 0,
		 window_directoties => 0,
		 window_status      => 0,
		 window_menubar     => 0,
		 window_scrollbars  => 0,
		 #Default information and legend
                 info   => 'x=%x   y=%y',
		 legend => '%l',
               );

my @No_Tags = ('img_src', 'img_usemap', 'img_ismap', 'img_width', 
               'img_height', 'img_border');

#********************************************* PUBLIC methods of class

#--------------------------------------------- constructor of object
sub new($) #($graphics)
{ my $type = shift;
  my $self = {};
  bless $self, $type;
  my $GIFgraph = shift;
  $self->{GIFgraph} = $GIFgraph;
  map
  { $self->{$_} = $Defaults{$_};
  } keys (%Defaults);
  return $self;
} #new

#--------------------------------------------- routine for set options
sub set
{ my $self = shift;
  my %options = @_;
  my ($i, $no);
  map
  { $no = 0;
    foreach $i (@No_Tags) { $no = 1 if $i eq lc($_)}
    $self->{$_} = $options{$_} unless $no;
  } keys %options;
} #set

#--------------------------------------------- routine for make image maps
sub imagemap($$$) #($file, \@data)
{ my $self = shift;
  my $type = ref $self->{GIFgraph};
  if ($type eq 'GIFgraph::pie') { $self->piemap(shift, shift) }
  elsif ($type eq 'GIFgraph::bars') { $self->barsmap(shift, shift) }
  elsif ($type eq 'GIFgraph::points') { $self->pointsmap(shift, shift) }
  elsif ($type eq 'GIFgraph::linespoints') { $self->pointsmap(shift, shift) }
  else {die "object $type is not supported"};
} #imagemap


#********************************************* PRIVATE methods of class

#--------------------------------------------- make map for Points graphic
sub pointsmap($$) #($file, \@data)
{ my $self = shift;
  my $file = shift;
  my $data = shift;
  my $name = $^T;
  my $gr = $self->{GIFgraph};
  $gr->check_data($data);
  $gr->setup_coords($data);
  my $s = "<Map Name=$name>\n";
  foreach (1 .. $gr->{numsets})
  { my $type = $gr->pick_marker($_);
    my $i;
    foreach $i (0 .. $gr->{numpoints})
    { next if (!defined($$data[$_][$i]));
      my ($xp, $yp) = $gr->val_to_pixel($i+1, $$data[$_][$i], $_);
      my $l = $xp - $gr->{marker_size};
      my $r = $xp + $gr->{marker_size};
      my $b = $yp + $gr->{marker_size};
      my $t = $yp - $gr->{marker_size};      
      MARKER: 
      { ($type <= 4) && do
        { $s .= "\t<Area Shape=\"rect\" Coords=\"$l, $t, $r, $b\" ";
	  last MARKER;
	}; #do
        (($type == 5) or ($type == 6)) && do
        { $s .= "\t<Area Shape=\"polygon\" Coords=\"$l, $yp, $xp, $t, $r, $yp, $xp, $b\" ";
	  last MARKER;
	}; #do
        ($type >= 7) && do
        { $s .= "\t<Area Shape=\"circle\" Coords=\"$xp, $yp, ".2 * $gr->{marker_size}."\" ";
	  last MARKER;
	}; #do
      } #MARKER:
      my $href = @{$self->{hrefs}}->[$_ - 1][$i];
      $href = $self->{href} unless defined($href);
      my $info = $self->{info};
      $info = $1.(sprintf "%$2f", $data->[0][$i]).$3 if ($info =~ /(^.*)%(\.\d)?x(.*$)/);
      $info = $1.(sprintf "%$2f", $data->[$_][$i]).$3 if ($info =~ /(^.*)%(\.\d)?y(.*$)/);
      $info =~ s/%l/@{$gr->{legend}}->[$_ - 1]/g;
      $s .= "Href=\"$href\" Alt=\"$info\" onMouseOver=\"window.status=\'$info\'\" onMouseOut=\"window.status=\'\'\"";
      if ($self->{newWindow})
      { my $s_;
        map
        { $s_ .= "$1=".$self->{$_}."," if (($_ =~ /window_(\w*)/) and ($self->{$_} != 0))
        } keys %{$self};
        chop $s_;
        $s .= " Target=\"".($name + 1)."\"";
        $s .= " onClick=\"window.open(\'\', \'".($name + 1)."\', \'$s_\')\"";
      } #if
      $s .= ">\n";
    } #foreach
  } #foreach
  if (defined($gr->{legend}))
  { my $xl = $gr->{lg_xs} + $gr->{legend_spacing};
    my $y = $gr->{lg_ys} + $gr->{legend_spacing} - 1;
    my $i = 0;
    my $row = 1;
    my $x = $xl;
    foreach (@{$gr->{legend}})
    { $i++;
      last if ($i > $gr->{numsets});
      my $xe = $x;
      next if (!defined($_) or $_ eq "");
      my $lhref = @{$self->{lhrefs}}->[$i - 1];
      $lhref = $self->{href} unless defined($lhref);
      my $legend = $self->{legend};
      $legend =~ s/%l/$_/g;
      my $old_ms = $gr->{marker_size};
      my $ms = _min($gr->{legend_marker_height}, $gr->{legend_marker_width});
      ($gr->{marker_size} > $ms/2) and $gr->{marker_size} = $ms/2;
      my $x1 += $xe + int($gr->{legend_marker_width}/2);
      my $y1 += $y + int($gr->{lg_el_height}/2);
      my $n = $gr->pick_marker($i);
      my $l = $x1 - $gr->{marker_size};
      my $r = $x1 - $gr->{marker_size} + $gr->{lg_el_width};
      my $b = $y1 + $gr->{marker_size};
      my $t = $y1 - $gr->{marker_size};
      $s .= "\t<Area Shape=\"rect\" Coords=\"$l, $t, $r, $b\" Href=\"$lhref\" Alt=\"$legend\" onMouseOver=\"window.status=\'$legend\'\" onMouseOut=\"window.status=\'\'\"";
      if ($self->{newWindow})
      { my $s_;
        map
        { $s_ .= "$1=".$self->{$_}."," if (($_ =~ /window_(\w*)/) and ($self->{$_} != 0))
        } keys %{$self};
        chop $s_;
        $s .= " Target=\"".($name + 1)."\"";
        $s .= " onClick=\"window.open(\'\', \'".($name + 1)."\', \'$s_\')\"";
      } #if
      $s .= ">\n";
      $gr->{marker_size} = $old_ms;
      $xe += $gr->{legend_marker_width} + $gr->{legend_spacing};
      my $ys = int($y + $gr->{lg_el_height}/2 - $gr->{lgfh}/2);
      $x += $gr->{lg_el_width};
      if (++$row > $gr->{lg_cols})
      { $row = 1;
        $y += $gr->{lg_el_height};
        $x = $xl;
      } #if
    } #foreach
  } #if				  
  $s .= "</Map>\n";
  $s .= "<Img UseMap=\"#$name\" Src=\"$file\" border=0 Height=".($gr->{gify})." Width=".($gr->{gifx})." ";
  map
  { $s .= "$1=".($self->{$_})." " if ($_ =~ /img_(\w*)/) and defined($self->{$_})
  } keys %{$self};
  chop $s;
  $s .= ">\n";
  return $s;
} #pointsmap

#--------------------------------------------- make map for Bar graphic
sub barsmap($$) #($file, \@data)
{ my $self = shift;
  my $file = shift;
  my $data = shift;
  my $name = $^T;
  my $gr = $self->{GIFgraph};
  $gr->check_data($data);
  $gr->setup_coords($data);
  my $s = "<Map Name=\"$name\">\n";
  my $zero = $gr->{zeropoint};
  foreach (0 .. $gr->{numpoints})
  { my $bottom = $zero;
    my $i;
    foreach $i (1 .. $gr->{numsets})
    { next if (!defined($$data[$i][$_]));
      my ($xp, $t) = $gr->val_to_pixel($_+1, $$data[$i][$_], $i);
      $s .= "\t<Area Shape=\"rect\" Coords=\"";
      if ($gr->{overwrite})
      { my $l = int($xp - _round($gr->{x_step}/2));
        my $r = int($xp + _round($gr->{x_step}/2));
	$t -= ($zero - $bottom); # if ($gr->{overwrite} == 2);
        $t = int $t;
	$s .= ($$data[$i][$_] >= 0) ? "$l, $t, $r, $bottom\" " : "$l, $bottom, $r, $t\" ";
	$bottom = $t; # if ($gr->{overwrite} == 2);
      } #if
      else
      { my $l = int($xp - $gr->{x_step}/2 + _round(($i-1) * $gr->{x_step}/$gr->{numsets}));
        my $r = int($xp - $gr->{x_step}/2 + _round($i *  $gr->{x_step}/$gr->{numsets}));
	$t = int $t;
	$s .= ($$data[$i][$_] >= 0) ? "$l, $t, $r, $zero\" " : "$l, $zero, $r, $t\" ";
      } #else
      my $href = @{$self->{hrefs}}->[$i - 1][$_];
      $href = $self->{href} unless defined($href);
      my $info = $self->{info};
      $info = $1.(sprintf "%$2f", $data->[0][$_]).$3 if ($info =~ /(^.*)%(\.\d)?x(.*$)/);
      $info = $1.(sprintf "%$2f", $data->[$i][$_]).$3 if ($info =~ /(^.*)%(\.\d)?y(.*$)/);
      $info =~ s/%l/@{$gr->{legend}}->[$i - 1]/g;
      $s .= "Href=\"$href\" Alt=\"$info\" onMouseOver=\"window.status=\'$info\'\" onMouseOut=\"window.status=\'\'\"";
      if ($self->{newWindow})
      { my $s_;
        map
        { $s_ .= "$1=".$self->{$_}."," if (($_ =~ /window_(\w*)/) and ($self->{$_} != 0))
        } keys %{$self};
        chop $s_;
        $s .= " Target=\"".($name + 1)."\"";
        $s .= " onClick=\"window.open(\'\', \'".($name + 1)."\', \'$s_\')\"";
      } #if
      $s .= ">\n";
    } #foreach
  } #foreach
  if (defined($gr->{legend}))
  { my $xl = $gr->{lg_xs} + $gr->{legend_spacing};
    my $y = $gr->{lg_ys} + $gr->{legend_spacing} - 1;
    my $i = 0;
    my $row = 1;
    my $x = $xl;
    foreach (@{$gr->{legend}})
    { $i++;
      last if ($i > $gr->{numsets});
      my $xe = $x;
      next if (!defined($_) or $_ eq "");
      my $lhref = @{$self->{lhrefs}}->[$i - 1];
      $lhref = $self->{href} unless defined($lhref);
      my $legend = $self->{legend};
      $legend =~ s/%l/$_/g;	
      my $ye = $y + int($gr->{lg_el_height}/2 - $gr->{legend_marker_height}/2);
      $s .= "\t<Area Shape=\"rect\" Coords=\"$xe, $ye, ".($xe + $gr->{lg_el_width}).", ".($ye + $gr->{legend_marker_height})."\" Href=\"$lhref\" Alt=\"$legend\" onMouseOver=\"window.status=\'$legend\'\" onMouseOut=\"window.status=\'\'\"";
      if ($self->{newWindow})
      { my $s_;
        map
        { $s_ .= "$1=".$self->{$_}."," if (($_ =~ /window_(\w*)/) and ($self->{$_} != 0))
        } keys %{$self};
        chop $s_;
        $s .= " Target=\"".($name + 1)."\"";
        $s .= " onClick=\"window.open(\'\', \'".($name + 1)."\', \'$s_\')\"";
      } #if
      $s .= ">\n";
      $xe += $gr->{legend_marker_width} + $gr->{legend_spacing};
      my $ys = int($y + $gr->{lg_el_height}/2 - $gr->{lgfh}/2);
      $x += $gr->{lg_el_width};
      if (++$row > $gr->{lg_cols})
      { $row = 1;
	$y += $gr->{lg_el_height};
	$x = $xl;
      } #if
    } #foreach
  } #if
  $s .= "</Map>\n";
  $s .= "<Img UseMap=\"#$name\" Src=\"$file\" border=0 Height=".($gr->{gify})." Width=".($gr->{gifx})." ";
  map
  { $s .= "$1=".($self->{$_})." " if ($_ =~ /img_(\w*)/) and defined($self->{$_})
  } keys %{$self};
  chop $s;
  $s .= ">\n";
  return $s;
} #barsmap

#--------------------------------------------- make map for Pie graphic
sub piemap($$) #($file, \@data)
{ my $self = shift;
  my $file = shift; 
  my $data = shift;
  my $gr = $self->{GIFgraph};
  $gr->check_data($data);
  $gr->setup_coords();
  my $sum = 0;
  my $i = 0;
  $sum += $data->[1][$i++] while $i <= $gr->{numpoints};
  die "no Total" unless $sum;
  my $pa = $gr->{start_angle};
  my $xc = $gr->{xc};
  my $yc = $gr->{yc};
  my $PI=4*atan2(1, 1);
  my ($pb, $j, $oldj);
  my $name = $^T;
  my $s = "<Map Name=\"$name\">\n";
  foreach $i (0 .. $gr->{numpoints})
  { $pb = $pa + 360 * $data->[1][$i] / $sum;
    $s .= "\t<Area Shape=\"polygon\" Coords=\"".(int $xc).", ".(int $yc);
    $oldj = $pa;
    for ($j = $pa; $j < $pb; $j += 10)
    { my $xe = int($xc + $gr->{w} * cos(($ANGLE_OFFSET + $j) * $PI / 180) / 2);
      my $ye = int($yc + $gr->{h} * sin(($ANGLE_OFFSET + $j) * $PI / 180) / 2);
      if ($gr->{'3d'})
      { $s .= ", $xe, $ye" if ($j == $pa and in_front($pa));
        $s .= ", ".$gr->{left}.", ".($ye + $gr->{pie_height}).", ".$gr->{left}.", ".$ye if (($j > 90) and ($oldj < 90));
        $s .= ", ".$gr->{right}.", ".($ye + $gr->{pie_height}).", ".$gr->{right}.", ".$ye if (($j > 270) and ($oldj < 270));
	if (in_front($j)) { $s .= ", $xe, ".($ye + $gr->{pie_height}) } 
	else { $s .= ", $xe, $ye" }
      } #if
      else { $s .= ", $xe, $ye" }
      $oldj = $j;			
    } #for
    my $xe = int($xc + $gr->{w} * cos(($ANGLE_OFFSET + $pb) * $PI / 180) / 2);
    my $ye = int($yc + $gr->{h} * sin(($ANGLE_OFFSET + $pb) * $PI / 180) / 2);
    $s .= ", $xe, ".($ye + $gr->{pie_height}) if (in_front($pb) and ($gr->{'3d'}));
    my $href = @{$self->{hrefs}}->[$i];
    $href = $self->{href} unless $href;
    my $info = $self->{info};
    $pa = 100 * $data->[1][$i] / $sum; 
    $info = $1.(sprintf "%$2f", $pa).$3 if ($info =~ /(^.*)%(\.\d)?p(.*$)/);
    $info = $1.(sprintf "%$2f", $sum).$3 if ($info =~ /(^.*)%(\.\d)?s(.*$)/);
    $info =~ s/%x/$data->[0][$i]/g;
    $info = $1.(sprintf "%$2f", $data->[1][$i]).$3 if ($info =~ /(^.*)%(\.\d)?y(.*$)/);
    $s .= ", $xe, $ye\" Href=\"$href\" Alt=\"$info\" onMouseOver=\"window.status=\'$info\'\" onMouseOut=\"window.status=\'\'\"";
    if ($self->{newWindow})
    { my $s_;
      map
      { $s_ .= "$1=".$self->{$_}."," if (($_ =~ /window_(\w*)/) and ($self->{$_} != 0))
      } keys %{$self};
      chop $s_;
      $s .= " Target=\"".($name + 1)."\"";
      $s .= " onClick=\"window.open(\'\', \'".($name + 1)."\', \'$s_\')\"";
    } #if
    $s .= ">\n";
    $pa = $pb;
  } #foreach
  $s .= "</Map>\n";
  $s .= "<Img UseMap=\"#$name\" Src=\"$file\" border=0 Height=".($gr->{gify})." Width=".($gr->{gifx})." ";
  map
  { $s .= "$1=".($self->{$_})." " if ($_ =~ /img_(\w*)/) and defined($self->{$_})
  } keys %{$self};
  chop $s;
  $s .= ">\n";
  return $s;
} #piemap

#--------------------------------------------- routines are used piemap
sub in_front($) #(angle)
{ my $a = level_angle(shift);
  ($a < $ANGLE_OFFSET or $a > (360 - $ANGLE_OFFSET)) ? 1 : 0;
} #in_front

sub level_angle($) #(angle)
{ my $a = shift;
  return level_angle($a - 360) if $a > 360;
  return level_angle($a + 360) if $a < 0;
  return $a;
} #level_angle

1;

__END__

=head1 NAME

B<GIFgraph::Map> - generates HTML map text.

=head1 SYNOPSIS

use GIFgraph::Map;

=head1 DESCRIPTION

B<GIFgraph> is a I<perl5> module to generate HTML map text for following
graphics objects B<GIFgraph::pie>, B<GIFgraph::bars>, R<GIFgraph::point> 
and B<GIFgraph::linespoints>.

=head1 EXAMPLES

See the samples directory in the distribution.

=head1 USAGE

Creat the B<GIFgrath> object, set options if you need it, creat the array
of data and use plot_to_gif routine for creat GIF image.
For example creat B<GIFgraph::pie> object

	$graphic = new GIFgraph::pie;
	
	$graphic->set('title'        => 'A Pie Chart',
	              'label'        => 'Label',
		      'axislabelclr' => 'black',
		      'pie_height'   => 80);
		      
	@data = (["1st","2nd","3rd","4th","5th","6th"],
	         [    4,    2,    3,    4,    3,  3.5]);
		 
	$GIFimage = 'Demo.gif';
	
	$graphic->plot_to_gif($GIFimage, \@data);

Then creat the B<GIFgraph::Map> object

	$map = new GIFgraph::Map($graphic);

	Use set routine for set options.

	$map->set(info => "%x slice contains %.1p% of %s (%x)");
	
	And creat HTML map text using the same name of GIF image
	and array of data.

	$HTML_map = $map->imagemap($GIFimage, \@data);

Now you may insert $HTML_map on your HTML page.


=head1 METHODS AND FUNCTIONS

=over 4

=item imagemap(I<file>, I<\@data>)

Generates HTML map text using GIF file "file" and reference to 
array of data "\@data". This parametres must be the same as are 
use in plot_to_gif routine.

=item set(I<key1> => I<value1>, I<key2> => I<value2> .... )

Set options. See OPTIONS.

=back

=head1 OPTIONS

=over *

=item B<hrefs>, B<lhrefs>

Set hyper reference for each data (hrefs), and for each legend (lhrefs). 
Array @hrefs must the same size as arrays in @data, otherwise null 
elements of @hrefs set to default. Analogely array @lhrefs must the
same size as legend array. Default use the simple JavaScript 
code 'javascript:;' instead reference, with do nothing.

Example of I<@hrefs> array:

for I<GIFgraph::pie>

if     @data  = ([  "1st",  "2nd",  "3rd"],
                 [      4,      2,      3]);

then   @hrefs =  ["1.htm","2.htm","3.htm"];


for I<GIFgraph::bars> I<GIFgraph::point> and I<GIFgraph::linespoints>

if     @data  = ([  "1st",  "2nd",  "3rd"],
                 [      5,     12,     24],
                 [      1,      2,      5]);

then   @hrefs = (["1.htm","2.htm","3.htm"],
                 ["4.htm","5.htm","6.htm"]);

Example of I<@lhrefs> array;

if    @legend = [  'one',  'two','three'];

then  @lhrefs = ["1.htm","2.htm","3.htm"];



=item B<info>, B<legend>

Set information string for data and for legend. This will show in 
status window of your broswer.
Format of this string the same for each data,
but you may use special symbols for receive indiwidual information.
For %x, %y, %s and $p parameters you may use spacial format for
round data: %.d{x|y|p|s}, where d is digit from 0 to 9. For
example %.0p or %.3x.
Default is 'x=%x   y=%y' for info, and '%l' for legend.

I<%x> - Replace to x values in @data - first array

I<%y> - Replace to y values in @data - other arrays

I<%s> - Replace to sum of all y values. Only for GIFgraph::pie object.

I<%p> - Replace to value, which show what part of all contains this data.
Only for GIFgraph::pie object.

I<%l> - Replace to legend. Only for GIFgraph::bars, GIFgraph::poins and
GIFgraph::linespoins objects.

=item B<img_option>

You may set any attribute in IMG tag (excluding UseMap, Src, Width, Height
and Border they will set automaticuly) use set routine:
set(img_option => value), where option is IMG attribute. For example:
routine set(img_Alt => 'Example'); include Alt='Example' to IMG tag.

=item B<newWindow>, B<window_option>

If newWindow set to TRUE, then link will open in new navigator window.
Parameters of new window you can set using window_option parameters,
analogely img_option option.

=back

=head1 AUTHOR

Roman Kosenko

=head2 Contact info

E-mail:    romik@amk.al.lg.ua

Home page: http://amk.al.lg.ua/~romik

=head2 Copyright

Copyright (C) 1999 Roman Kosenko.
All rights reserved.  This package is free software; 
you can redistribute it and/or modify it under the same 
terms as Perl itself.

