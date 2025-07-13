#############################################################################
## Name:        Smart.pm
## Purpose:     XML::Smart
## Author:      Graciliano M. P.
## Modified by:
## Created:     10/05/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package XML::Smart ;
use 5.006 ;

no warnings ;

use Object::MultiType ;
use vars qw(@ISA) ;
@ISA = qw(Object::MultiType) ;

use XML::Smart::Tree ;

our ($VERSION) ;
$VERSION = '1.3.1' ;

#######
# NEW #
#######

sub new {
  my $class = shift ;
  my $file = shift ;
  my $parser = shift ;
  
  my $this = Object::MultiType->new(
  boolsub   => \&boolean ,
  scalarsub => \&content ,
  tiearray  => 'XML::Smart::TieArray' ,
  tiehash   => 'XML::Smart::TieHash' ,
  tieonuse  => 1 ,
  code      => \&find_arg , 
  ) ;
  
  my $parser = &XML::Smart::Tree::load($parser) ;
  
  if ($file eq '') { $$this->{tree} = {} ;}
  else { $$this->{tree} = &XML::Smart::Tree::parse($file,$parser,@_) ;}

  $$this->{point} = $$this->{tree} ;
  
  bless($this,$class) ;
}

#########
# CLONE #
#########

sub clone {
  my $saver = shift ;
  
  my ($pointer , $back , $array , $key , $i , $null_clone) ;

  if ($#_ == 0 && !ref $_[0]) {
    my $nullkey = shift ;
    $pointer = {} ;
    $back = {} ;
    $null_clone = 1 ;
    
    ($i) = ( $nullkey =~ /(?:^|\/)\/\[(\d+)\]$/s );
    ($key) = ( $nullkey =~ /(.*?)(?:\/\/\[\d+\])?$/s );
    if ($key =~ /^\/\[\d+\]$/) { $key = undef ;}
  }

  else {
    $pointer = shift ;
    $back = shift ;
    $array = shift ;
    $key = shift ;
    $i = shift ;
  }

  my $clone = Object::MultiType->new(
  boolsub   => \&boolean ,
  scalarsub => \&content ,
  tiearray  => 'XML::Smart::TieArray' ,
  tiehash   => 'XML::Smart::TieHash' ,
  tieonuse  => 1 ,
  code      => \&find_arg ,
  ) ;
  bless($clone,__PACKAGE__) ;  
  
  if ( !$saver->is_saver ) { $saver = $$saver ;}
  
  if (!$back) {
    if (!$pointer) { $back = $saver->{back} ;}
    else { $back = $saver->{point} ;}
  }
  
  if (!$array && !$pointer) { $array = $saver->{array} ;}

  my @keyprev ;

  if (defined $key) { @keyprev = $key ;}
  elsif (defined $i) { @keyprev = "[$i]" ;}

  if (!defined $key) { $key = $saver->{key} ;}
  if (!defined $i) { $i = $saver->{i} ;}
  
  if (!$pointer) { $pointer = $saver->{point} ;}
  
  #my @call = caller ;
  #print "CLONE>> $key , $i >> @{$saver->{keyprev}}\n" ;

  $$clone->{tree} = $saver->{tree} ;
  $$clone->{point} = $pointer ;
  $$clone->{back} = $back ;
  $$clone->{array} = $array ;
  $$clone->{key} = $key ;
  $$clone->{i} = $i ;
  
  if ( @keyprev ) {
    $$clone->{keyprev} = [@{$saver->{keyprev}}] ;
    push(@{$$clone->{keyprev}} , @keyprev) ;
  }
  
  if (defined $_[0]) { $$clone->{content} = \$_[0] ;}

  if ( $null_clone || defined $saver->{null} ) {
    $$clone->{null} = 1 ;
    ## $$clone->{self} = $clone ;
  }
  
  return( $clone ) ;
}

###########
# BOOLEAN #
###########

sub boolean {
  my $this = shift ;
  if ( $this->null ) { return 0 ;}
  return( 1 ) ;
}

########
# NULL #
########

sub null {
  my $this = shift ;
  if ( $$this->{null} ) { return 1 ;}
  if ( (keys %{$$this->{tree}}) < 1 ) { return 1 ;}
  return ;
}

########
# BASE #
########

sub base {
  my $this = shift ;
  
  my $base = Object::MultiType->new(
  boolsub   => \&boolean ,
  scalarsub => \&content ,
  tiearray  => 'XML::Smart::TieArray' ,
  tiehash   => 'XML::Smart::TieHash' ,
  tieonuse  => 1 ,
  code      => \&find_arg , 
  ) ;
  
  $$base->{tree} = $this->tree ;
  $$base->{point} = $$base->{tree} ;
  
  return( $base ) ;
}

########
# BACK #
########

sub back {
  my $this = shift ;
  
  my @tree = @{$$this->{keyprev}} ;
  if (!@tree) { return back ;}
  
  my $last = pop(@tree) ;
  my $i = 0 ;
  if ($last =~ /^\[(\d+)\]$/) { $i = $1 ; $last = pop(@tree) ;}
  
  my $back = $this->base ;
  
  foreach my $tree_i ( @tree ) {
    if ($tree_i =~ /^\[(\d+)\]$/) {
      my $i = $1 ;
      $back = $back->[$i] ;
    }
    else { $back = $back->{$tree_i} ;}
  }
  
  if ( wantarray ) { return( $back , $last , $i ) ;}
  return( $back ) ;
}

#######
# KEY #
#######

sub key {
  my $this = shift ;
  my $k = @{$$this->{keyprev}}[ $#{$$this->{keyprev}} ] ;
  #my $i = 0 ;
  if ($k =~ /^\[(\d+)\]$/) {
    #$i = $1 ;
    $k = @{$$this->{keyprev}}[ $#{$$this->{keyprev}} -1 ] ;
  }
  
  #if ( wantarray ) { return( $k , $i ) ;}
  return $k ;
}

#####
# I #
#####

sub i {
  my $this = shift ;
  my $i = $$this->{i} || 0 ;
  return $i ;
}

########
# COPY #
########

sub copy {
  my $this = shift ;

  my $copy = Object::MultiType->new(
  boolsub   => \&boolean ,
  scalarsub => \&content ,
  tiearray  => 'XML::Smart::TieArray' ,
  tiehash   => 'XML::Smart::TieHash' ,
  tieonuse  => 1 ,
  code      => \&find_arg , 
  ) ;
  
  $$copy->{tree} = &_copy_hash($this->tree) ;
  $$copy->{keyprev} = $$this->{keyprev} ;
  
  my ( $back , $key , $i ) = $copy->back ;
  
  $copy = $back->{$key} ;
  $copy = $back->[$i] if $i ;
  
  return( $copy ) ;
}

##############
# _COPY_HASH #
##############

sub _copy_hash {
  my ( $ref ) = @_ ;
  my $copy ;
  
  if (ref $ref eq 'HASH') {
    $copy = {} ;
    foreach my $Key ( keys %$ref ) {
      if (ref $$ref{$Key}) {
        $$copy{$Key} =&_copy_hash($$ref{$Key}) ;
      }
      else { $$copy{$Key} = $$ref{$Key} ;}
    }
  }
  elsif (ref $ref eq 'ARRAY') {
    $copy = [] ;
    foreach my $i ( @$ref ) {
      if (ref $i) {
        push(@$copy , &_copy_hash($i) ) ;
      }
      else { push(@$copy , $i) ;}
    }
  }
  elsif (ref $ref eq 'SCALAR') {
    my $copy = $$ref ;
    return( \$copy ) ;
  }
  else { return( {} ) ;}

  return( $copy ) ;
}

########
# TREE #
########

sub tree { return( ${$_[0]}->{tree} ) ;}

###########
# POINTER #
###########

sub pointer { return( ${$_[0]}->{point} ) ;}

############
# CUT_ROOT #
############

sub cut_root {
  my $this = shift ;

  if (keys %{$this} > 1) { return $this ;}
  
  my $root = (keys %{$this})[0] ;
  return( $this->{$root} ) ;
}

###########
# IS_NODE #
###########

sub is_node {
  my $this = shift ;
  my $key = $this->key ;
  foreach my $k ( @{ $this->back->{'/keys'} } ) {
    return 1 if $k eq $key ;
  }
  return undef ;
}

#########
# NODES #
#########

sub nodes {
  my $this = shift ;
  
  my @keys = @{ $this->{'/keys'} } if defined $this->{'/keys'} ;
  my (@nodes,%i) ;
  
  foreach my $keys_i ( @keys ) {
    my $i = $i{$keys_i}++ ;
    push(@nodes , $this->{$keys_i}[$i]) ;
  }

  return @nodes ;
}

##############
# NODES_KEYS #
##############

sub nodes_keys {
  my $this = shift ;
  
  my @keys = @{ $this->{'/keys'} } if defined $this->{'/keys'} ;
  my (@nodes,%ks) ;
  
  foreach my $keys_i ( @keys ) {
    if ( !$ks{$keys_i} ) {
      push(@nodes , $keys_i) ;
      $ks{$keys_i} = 1 ;
    }
  }

  return @nodes ;
}

#######
# RET #
#######

sub ret {
  my $this = shift ;
  my $type = shift ;
  
  if ($type =~ /^\s*<xml>\s*$/si ) {
    return $this->data_pointer( noheader => 1 ) ;
  }
  
  my @ret ;
  $type =~ s/[^<\$\@\%k]//gs ;
  
  if ($type =~ /^</) {
    $type =~ s/^<+// ;    
    
    my ($back , $key , $i) = $this->back ;

    if    ($type =~ /\$$/) { @ret = $back->{$key}[$i]->content ;}
    elsif ($type =~ /\@$/) {
      @ret = @{$back} ;
      foreach my $ret_i ( @ret ) {
        $ret_i = $ret_i->{$key}[$i] ;
      }
    }
    elsif ($type =~ /\%$/) { @ret = %{$back->{$key}[$i]} ;}
  }
  else {
    if    ($type =~ /\$$/) { @ret = $this->content ;}
    elsif ($type =~ /\@$/) { @ret = @{$this} ;}
    elsif ($type =~ /\%$/) { @ret = %{$this} ;}
    elsif ($type =~ /[\@\%]k$/) {
      my @keys = keys %{$this} ;
      foreach my $key ( @keys ) {
        my $n = $#{ $this->{$key} } ;
        if ($n > 0) {
          my @multi = ($key) x ($n+1) ;
          push(@ret , @multi) ;
        }
        else { push(@ret , $key) ;}
      }
    }
  }
  
  if ($type =~ /^\$./) {
    foreach my $ret_i ( @ret ) {
      if (ref($ret_i) eq 'XML::Smart') { $ret_i = $ret_i->content ;}
    }
  }
  
  if ( wantarray ) { return( @ret ) ;}
  return $ret[0] ;
}

########
# FIND #
########

sub find { &find_arg } ;

############
# FIND_ARG #
############

sub find_arg {
  my $this = shift ;
  my ($name , $type , $value) = @_ ;
  
  if ($#_ == 0) { return $this->ret(@_) ;}

  elsif ($#_ == 1 && $_[0] eq '[@]') {
    my $arg = $_[1] ;
    return $this->{$arg}('<@') ;
  }
  
  $type =~ s/\s//gs ;

  my $key = $$this->{key} ;

  my @hashes ;
  
  if (ref($$this->{array})) {
    push(@hashes , @{$$this->{array}}) ;
  }
  else {
    push(@hashes , $$this->{point}) ;
    if (ref $$this->{point} eq 'HASH') {
      foreach my $k ( sort keys %{$$this->{point}} ) {
        push(@hashes , [$k,$$this->{point}{$k}]) if ref($$this->{point}{$k}) eq 'HASH' ;
      }
    }
  }

  my $i = -1 ;
  my (@hash , @i) ;
  my $notwant = !wantarray ;

  foreach my $hash_i ( @hashes ) {
    $i++ ;
    my $hash ;
    if (ref $hash_i eq 'ARRAY') { $hash = @$hash_i[1] ;}
    else { $hash = $hash_i ;}
    
    if    ($type eq 'eq'  && $$hash{$name} eq $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq 'ne'  && $$hash{$name} ne $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '=='  && $$hash{$name} == $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '!='  && $$hash{$name} != $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '<='  && $$hash{$name} <= $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '>='  && $$hash{$name} >= $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '<'   && $$hash{$name} <  $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '>'   && $$hash{$name} >  $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '=~'  && $$hash{$name} =~ /$value/s)  { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
    elsif ($type eq '=~i' && $$hash{$name} =~ /$value/i)  { push(@hash,$hash_i) ; push(@i,$i) ; last if $notwant ;}
  }
                           
  my $back = $$this->{back} ;
  
  #print "FIND>> @{$$this->{keyprev}} >> $i\n" ;
  
  if (@hash) {
    if ($notwant) {
      my ($k,$hash) = (undef) ;
      if (ref $hash[0] eq 'ARRAY') { ($k,$hash) = @{$hash[0]} ;}
      else { $hash = $hash[0] ;}
      return &XML::Smart::clone($this,$hash,$back,undef, $k,$i[0]) ;
    }
    else {
      my $c = -1 ;
      foreach my $hash_i ( @hash ) {
        $c++ ;
        my ($k,$hash) = (undef) ;
        if (ref $hash_i eq 'ARRAY') { ($k,$hash) = @{$hash_i} ;}
        else { $hash = $hash_i ;}        
        $hash_i = &XML::Smart::clone($this,$hash,$back,undef, $k,$i[$c]) ;
      }
      return( @hash ) ;
    }
  }
  
  if (wantarray) { return() ;}
  return &XML::Smart::clone($this,'') ;
}

###########
# CONTENT #
###########

sub content {
  my $this = shift ;
  
  if ( defined $$this->{content} ) {
    return ${$$this->{content}} ;
  }
  
  my $key = 'CONTENT' ;
  my $i = $$this->{i} ;
  
  if (ref($$this->{point}{$key}) eq 'ARRAY') {
    if ($i eq '') { $i = 0 ;}
    return $$this->{point}{$key}[$i] ;
  }
  elsif (defined $$this->{point}{$key}) {
    return $$this->{point}{$key} ;
  }
  
  return '' ;
}

########
# SAVE #
########

sub save {
  my $this = shift ;
  my $file = shift ;
  
  if (-d $file || (-e $file && !-w $file)) { return ;}
  
  my ($data,$unicode) = $this->data(@_) ;
  
  my $fh ;
  open ($fh,">$file") ; binmode($fh) if $unicode ;
  print $fh $data ;
  close ($fh) ;
  
  return( 1 ) ;
}

################
# DATA_POINTER #
################

sub data_pointer {
  my $this = shift ;
  if ( $this->null ) { return ;}
  
  my ($point,$key) ;
  
  if ( exists $$this->{content} ) {
    my $back = $this->back ;
    my $root = $back->key ;
    my $k = $this->key ;
    $point = $back->pointer ;
    $point = $$point{ $this->key } ;
    $point = {$root => {$k => $point} } ;
  }
  else {
    $point = $$this->{point} ;
    $key = $this->key ;
  }
  
  $this->data( tree => $point , root => $key , @_) ;
}

########
# DATA #
########

sub data {
  my $this = shift ;
  my ( %args ) = @_ ;
  
  my $tree ;
  
  if ( $args{tree} ) { $tree = $args{tree} ;}
  else { $tree = $this->tree ;}
  
  {
    my $addroot ;

    if ( ref $tree ne 'HASH' ) { $addroot = 1 ;}
    else {
      my $ks = keys %$tree ;
      my $n = defined $$tree{'/keys'} ? 2 : 1 ;
      if ($ks > $n) { $addroot = 1 ;}
      else {
        my $k = (keys %$tree)[0] ;
        if (ref $$tree{$k} eq 'ARRAY' && $#{$$tree{$k}} > 0) {
          my ($c,$ok) ;
          foreach my $i ( @{$$tree{$k}} ) {
            if ( $i && &is_valid_tree($i) ) { $c++ ; $ok = $i ;}
            if ($c > 1) { $addroot = 1 ; last ;}
          }
          if (!$addroot && $ok) { $$tree{$k} = $ok ;}
        }
        elsif (ref $$tree{$k} =~ /^(?:HASH|)$/) {$addroot = 1 ;}
      }
    }
    
    if ($addroot) {
      my $root = $args{root} || 'root' ;
      $tree = {$root => $tree} ;
    }
  }
  
  if ( $args{lowtag} ) { $args{lowtag} = 1 ;}
  if ( $args{upertag} ) { $args{lowtag} = 2 ;}
  
  if ( $args{lowarg} ) { $args{lowarg} = 1 ;}
  if ( $args{uperarg} ) { $args{lowarg} = 2 ;}

  my ($data,$unicode) ;
  {
    my $parsed = {} ;
    &_data(\$data,$tree,'',-1, $parsed , $args{noident} , $args{nospace} , $args{lowtag} , $args{lowarg} , $args{wild} ) ;
    $data .= "\n" if !$args{nospace} ;
    if ( &_is_unicode($data) ) { $unicode = 1 ;}
  }

  my $enc = 'iso-8859-1' ;
  if ($unicode) { $enc = 'utf-8' ;}
    
  my $meta ;
  if ( $args{meta} ) {
    my @metas ;
    if (ref($args{meta}) eq 'ARRAY') { @metas = @{$args{meta}} ;}
    elsif (ref($args{meta}) eq 'HASH') { @metas = $args{meta} ;}
    else { @metas = $args{meta} ;}
    
    foreach my $metas_i ( @metas ) {
      if (ref($metas_i) eq 'HASH') {
        my $meta ;
        foreach my $Key (sort keys %$metas_i ) {
          $meta .= " $Key=" . &_add_quote($$metas_i{$Key}) ;
        }
        $metas_i = $meta ;
      }
    }
    
    foreach my $meta ( @metas ) {
      $meta =~ s/^[<\?\s*]//s ;
      $meta =~ s/[\s\?>]*$//s ;
      $meta =~ s/^meta\s+//s ;
      $meta = "<?meta $meta ?>" ;
    }
    
    $meta = "\n" . join ("\n", @metas) ;
  }
  
  my $wild = ' [format: wild]' if $args{wild} ;
  
  my $metagen = qq`\n<?meta name="GENERATOR" content="XML::Smart $VERSION$wild" ?>` ;
  if ( $args{nometagen} ) { $metagen = '' ;}
  
  my $length ;
  if ( $args{length} ) {
    $length = ' length="' . (length($metagen) + length($meta) + length($data)) . '"' ;
  }
  
  my $xml = qq`<?xml version="1.0" encoding="$enc"$length ?>` ;
  
  if ( $args{noheader} ) { $xml = '' ; $metagen = '' if $args{nometagen} eq '' ;}
  
  $data = $xml . $metagen . $meta . $data ;
  
  if ($xml eq '') { $data =~ s/^\s+//gs ;}
  
  if (wantarray) { return($data , $unicode) ;}
  return($data) ;
}

#################
# IS_VALID_TREE #
#################

sub is_valid_tree {
  my ( $tree ) = @_ ;
  my $found ;
  if (ref($tree) eq 'HASH') {
    foreach my $Key (sort keys %$tree ) {
      if ($Key eq '' || $Key eq '/keys') { next ;}
      if (ref($$tree{$Key})) { $found = &is_valid_tree($$tree{$Key}) ;}
      elsif ($$tree{$Key} ne '') { $found = 1 ;}
      if ($found) { last ;}
    }
  }
  elsif (ref($tree) eq 'ARRAY') {
    foreach my $value (@$tree) {
      if (ref($value)) { $found = &is_valid_tree($value) ;}
      elsif ($value ne '') { $found = 1 ;}
      if ($found) { last ;}      
    }
  }
  elsif (ref($tree) eq 'SCALAR' && $$tree ne '') { $found = 1 ;}
  
  return $found ;
}

###############
# _IS_UNICODE #
###############

sub _is_unicode {
  if ($] >= 5.8) {
    eval(q`
      if ( $data =~ /[\x{100}-\x{10FFFF}]/s) { return 1 ;}}
    `);
  }
  else {
    ## No Perl internal support for UTF-8! ;-/
    ## Is better to handle as Latin1.
    return undef ;
  }

  return undef ;
}

#########
# _DATA #
#########

sub _data {
  my ( $data , $tree , $tag , $level , $parsed , @stat ) = @_ ;

  if (ref($tree) eq 'XML::Smart') { $tree = $$tree->{point} ;}
  
  if ($$parsed{"$tree"}) { return ;}
  $$parsed{"$tree"}++ ;
  
  my $ident = "\n" ;
  $ident .= '  ' x $level if !$stat[0] ;
  
  if ($stat[1]) { $ident = '' ;}
  
  my $tag_org = $tag ;
  $tag = $stat[4] ? $tag : &_check_tag($tag) ;
  if    ($stat[2] == 1) { $tag = "\L$tag\E" ;}
  elsif ($stat[2] == 2) { $tag = "\U$tag\E" ;}

  if (ref($tree) eq 'HASH') {
    my ($args,$args_end,$tags,$cont) ;
    
    #if ( (defined $$tree{CONTENT} && $$tree{CONTENT} ne '') || (defined $$tree{content} && $$tree{content} ne '')) { $stat[0] = 1 ; $ident = '' ;}
    
    foreach my $Key (sort keys %$tree ) {
      if ($Key eq '' || $Key eq '/keys') { next ;}
      if (ref($$tree{$Key})) {
        my $k = $$tree{$Key} ;
        if (ref $k eq 'XML::Smart') { $k = ${$$tree{$Key}}->{point} ;}
        $args .= &_data(\$tags,$k,$Key, $level+1 , $parsed , @stat) ;
      }
      elsif ("\L$Key\E" eq 'content') { $cont .= $$tree{$Key} ;}
      elsif ( $Key eq '!--' && (!ref($$tree{$Key}) || ( ref($$tree{$Key}) eq 'HASH' && keys %{$$tree{$Key}} == 1 && (defined $$tree{$Key}{CONTENT} || defined $$tree{$Key}{content}) ) ) ) {
        my $ct = $$tree{$Key} ;
        if (ref $$tree{$Key}) { $ct = defined $$tree{$Key}{CONTENT} ? $$tree{$Key}{CONTENT} : $$tree{$Key}{content} ;} ;
        $cont .= '<!--' . $ct . '-->' ;
      }
      elsif ( $stat[4] && $$tree{$Key} eq '') { $args_end .= " $Key" ;}
      else {
        my $tp = _data_type($$tree{$Key}) ;
        if    ($tp == 1) {
          my $k = $stat[4] ? $Key : &_check_key($Key) ;
          if    ($stat[3] == 1) { $k = "\L$Key\E" ;}
          elsif ($stat[3] == 2) { $k = "\U$Key\E" ;}
          $args .= " $k=" . &_add_quote($$tree{$Key}) ;
        }
        else {
          my $k = $stat[4] ? $Key : &_check_key($Key) ;
          if    ($stat[2] == 1) { $k = "\L$Key\E" ;}
          elsif ($stat[2] == 2) { $k = "\U$Key\E" ;}

          if ($tp == 2) {
            my $cont = $$tree{$Key} ; &_add_basic_entity($cont) ;
            $tags .= qq`$ident<$k>$cont</$k>` ;
          }
          elsif ($tp == 3) { $tags .= qq`$ident<$k><![CDATA[$$tree{$Key}]]></$k>`;}
          elsif ($tp == 4) {
            require XML::Smart::Base64 ;
            my $base64 = &XML::Smart::Base64::encode_base64($$tree{$Key}) ;
            $base64 =~ s/\s$//s ;
            $tags .= qq`$ident<$k dt:dt="binary.base64">$base64</$k>`;
          }
        }
      }
    }
    
    &_add_basic_entity($cont) if $cont ne '' ;
    
    if ($args_end ne '') {
      $args .= $args_end ;
      $args_end = undef ;
    }
    
    if ($args ne '' && $tags ne '') {
      $$data .= qq`$ident<$tag$args>` if $tag ne '' ;
      $$data .= $tags ;
      $$data .= $cont ;
      $$data .= $ident if $cont eq '' ;
      $$data .= qq`</$tag>` if $tag ne '' ;
    }
    elsif ($args ne '' && $cont ne '') {
      $$data .= qq`$ident<$tag$args>` if $tag ne '' ;
      $$data .= $cont ;
      $$data .= $ident if $cont eq '' ;
      $$data .= qq`</$tag>` if $tag ne '' ;
    }
    elsif ($args ne '') {
      $$data .= qq`$ident<$tag$args/>`;
    }
    elsif ($tags ne '') {
      $$data .= qq`$ident<$tag>` if $tag ne '' ;
      $$data .= $tags ;
      $$data .= $cont ;
      $$data .= $ident if $cont eq '' ;
      $$data .= qq`</$tag>` if $tag ne '' ;
    }
  }
  elsif (ref($tree) eq 'ARRAY') {
    my ($c,$v,$tags) ;
    foreach my $value_i (@$tree) {
      my $value = $value_i ;
      if (ref $value_i eq 'XML::Smart') { $value = $$value_i->{point} ;}
      
      my $do_val = 1 ;
      if ( $tag_org eq '!--' && ( !ref($value) || ( ref($value) eq 'HASH' && keys %{$value} == 1 && (defined $$value{CONTENT} || defined $$value{content}) ) ) ) {
        $c++ ;
        my $ct = $value ;
        if (ref $value) { $ct = defined $$value{CONTENT} ? $$value{CONTENT} : $$value{content} ;} ;
        $tags .= $ident . '<!--' . $ct . '-->' ;
        $v = $ct if $c == 1 ;
        $do_val = 0 ;
      }
      elsif (ref($value)) {
        if (ref($value) eq 'HASH') {
          $c = 2 ;
          &_data(\$tags,$value,$tag,$level, $parsed , @stat) ;
          $do_val = 0 ;
        }
        elsif (ref($value) eq 'SCALAR') { $value = $$value ;}
        elsif (ref($value) ne 'ARRAY') { $value = "$value" ;}
      }
      if ( $do_val && $value ne '') {
        my $tp = _data_type($value) ;
        if ($tp <= 2) {
          $c++ ;
          my $cont = $value ; &_add_basic_entity($value) ;
          &_add_basic_entity($cont) ;
          $tags .= qq`$ident<$tag>$cont</$tag>`;
          $v = $cont if $c == 1 ;
        }
        elsif ($tp == 3) {
          $c++ ;
          $tags .= qq`$ident<$tag><![CDATA[$value]]></$tag>`;
          $v = $value if $c == 1 ;
        }
        elsif ($tp == 4) {
          $c++ ;
          require XML::Smart::Base64 ;
          my $base64 = &XML::Smart::Base64::encode_base64($value) ;
          $base64 =~ s/\s$//s ;
          $tags .= qq`$ident<$tag dt:dt="binary.base64">$base64</$tag>`;
          $v = $value if $c == 1 ;
        }
      }
    }
    if ($c <= 1) {
      my $k = $stat[4] ? $tag : &_check_key($tag) ;
      if    ($stat[3] == 1) { $k = "\L$k\E" ;}
      elsif ($stat[3] == 2) { $k = "\U$k\E" ;}
      delete $$parsed{"$tree"} ;
      return " $k=" . &_add_quote($v) ;
    }
    else { $$data .= $tags ;}
  }
  elsif (ref($tree) eq 'SCALAR') {
    my $k = $stat[4] ? $tag : &_check_key($tag) ;
    if    ($stat[3] == 1) { $k = "\L$k\E" ;}
    elsif ($stat[3] == 2) { $k = "\U$k\E" ;}
    delete $$parsed{"$tree"} ;
    return " $k=" . &_add_quote($$tree) ;
  }
  elsif (ref($tree)) {
    my $k = $stat[4] ? $tag : &_check_key($tag) ;
    if    ($stat[3] == 1) { $k = "\L$k\E" ;}
    elsif ($stat[3] == 2) { $k = "\U$k\E" ;}
    delete $$parsed{"$tree"} ;
    return " $k=" . &_add_quote("$tree") ;
  }

  delete $$parsed{"$tree"} ;
  return ;
}

##############
# _DATA_TYPE #
##############

sub _data_type {
  return 4 if ($_[0] =~ /[^\w\d\s!"#\$\%&'\(\)\*\+,\-\.\/:;<=>\?\@\[\\\]\^\`\{\|}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ]/s) ;
  return 3 if ($_[0] =~ /<.*?>/s) ;
  return 2 if ($_[0] =~ /[\r\n\t]/s) ;
  return 1 ;
}

##############
# _CHECK_TAG #
##############

sub _check_tag { &_check_key ;}

##############
# _CHECK_KEY #
##############

sub _check_key {
  if ($_[0] =~ /(?:^[.:-]|[^\w\:\.\-])/s) {
    my $k = $_[0] ;
    $k =~ s/^[.:-]+//s ;
    $k =~ s/[^\w\:\.\-]+/_/gs ;
    return( $k ) ;
  }
  return( $_[0] ) ;
}

#######################
# _PARSE_BASIC_ENTITY #
#######################

sub _parse_basic_entity {
  $_[0] =~ s/&lt;/</gs ;
  $_[0] =~ s/&gt;/>/gs ;
  $_[0] =~ s/&amp;/&/gs ;
  $_[0] =~ s/&apos;/'/gs ;
  $_[0] =~ s/&quot;/"/gs ;
  
  $_[0] =~ s/&#(\d+);/ $1 > 255 ? pack("U",$1) : pack("C",$1)/egs ;
  $_[0] =~ s/&#x([a-fA-F\d]+);/pack("U",hex($1))/egs ;
  
  return( $_[0] ) ;
}

#####################
# _ADD_BASIC_ENTITY #
#####################

sub _add_basic_entity {
  $_[0] =~ s/(&(?:\w+;)?)/{_is_amp($1) or $1}/sgex ;
  $_[0] =~ s/</&lt;/gs ;
  $_[0] =~ s/>/&gt;/gs ;
  return( $_[0] ) ;
}

###########
# _IS_AMP #
###########

sub _is_amp {
  if ($_[0] eq '&') { return( '&amp;' ) ;}
  return( undef ) ;
}

##############
# _ADD_QUOTE #
##############

sub _add_quote {
  my ($data) = @_ ;
  $data =~ s/\\$/\\\\/s ;
  
  &_add_basic_entity($data) ;
  
  my $q1 = 1 if $data =~ /"/s ;
  my $q2 = 1 if $data =~ /'/s ;
  
  if (!$q1 && !$q2) { return( qq`"$data"` ) ;}
  
  if ($q1 && $q2) {
    $data =~ s/"/&quot;/gs ;
    return( qq`"$data"` ) ;
  }
  
  if ($q1) { return( qq`'$data'` ) ;}
  if ($q2) { return( qq`"$data"` ) ;}

  return( qq`"$data"` ) ;
}

######################
# _GENERATE_NULLTREE #
######################

sub _generate_nulltree {
  my $saver = shift ;
  my ( $K , $I ) = @_ ;
  if ( !$saver->{keyprev} ) {
    $saver->{null} = 0 ;
    return ;
  }
  
  my @tree = @{$saver->{keyprev}} ;
  if (!@tree) {
    print "****\n" ;
    $saver->{null} = 0 ;
    return ;  
  }
  
  if ( $I > 0 ) { push(@tree , "[$I]") ;}
  
  #print ">> @tree >> $K , $I\n" ;
  
  my $tree = $saver->{tree} ;
  
  my ($keyprev , $treeprev , $array , $key , $i) ;
  foreach my $tree_i ( @tree ) {

    if (ref $tree ne 'HASH' && ref $tree ne 'ARRAY') {
      my $cont = $$treeprev{$keyprev} ;
      $$treeprev{$keyprev} = {} ;
      $$treeprev{$keyprev}{CONTENT} = $cont ;
    }
      
    if ($tree_i =~ /^\[(\d+)\]$/) {
      $i = $1 ;
      if (exists $$treeprev{$keyprev}) {
        if (ref $$treeprev{$keyprev} ne 'ARRAY') {
          my $prev = $$treeprev{$keyprev} ;
          $$treeprev{$keyprev} = [$prev] ;
        }
      }
      else { $$treeprev{$keyprev} = [] ;}
      
      if (!exists $$treeprev{$keyprev}[$i]) { $$treeprev{$keyprev}[$i] = {} ;}
      
      my $prev = $tree ;
      $tree = $$treeprev{$keyprev}[$i] ;
      $array = $$treeprev{$keyprev} ;
      $treeprev = $prev ;
    }
    elsif (ref $tree eq 'ARRAY') {
      my $prev = $tree ;
      $tree = $$treeprev{$keyprev}[0] ;
      $array = $$treeprev{$keyprev} ;
      $treeprev = $prev ;
    }
    else {
      if (exists $$tree{$tree_i}) {
        if (ref $$tree{$tree_i} ne 'HASH' && ref $$tree{$tree_i} ne 'ARRAY') {
          if ( $$tree{$tree_i} ne '' ) {
            my $cont = $$tree{$tree_i} ;
            $$tree{$tree_i} = {} ;
            $$tree{$tree_i}{CONTENT} = $cont ;
          }
          else { $$tree{$tree_i} = {} ;}
        }
      }
      else { $$tree{$tree_i} = {} ;}
      $keyprev = $tree_i ;
      $treeprev = $tree ;
      $tree = $$tree{$tree_i} ;
      $key = $tree_i ;
    }
  }
  
  $saver->{point} = $tree ;
  $saver->{back} = $treeprev ;
  $saver->{array} = $array ;
  $saver->{key} = $key ;
  $saver->{i} = $i ;

  $saver->{null} = 0 ;

  return( 1 ) ;
}

###########
# DESTROY #
###########

sub DESTROY {
  my $this = shift ;
  $$this->clean ;
}

########################
# XML::SMART::TIEARRAY #
########################

package XML::Smart::TieArray ;

sub TIEARRAY {
  my $class = shift ;
  my $saver = shift ;
  my $this = { saver => $saver } ;
  bless($this,$class) ;
}

sub FETCH {
  my $this = shift ;
  my ($i) = @_ ;
  my $key = $this->{saver}->{key} ;
  
  my $point = '' ;
  
  #print ">> @{$this->{saver}->{keyprev}}\n" ;
  
  if ($this->{saver}->{array}) {
    if (!exists $this->{saver}->{array}[$i] ) {
      return &XML::Smart::clone($this->{saver},"/[$i]") ;
    }
    $point = $this->{saver}->{array}[$i] ;
  }
  elsif (exists $this->{saver}->{back}{$key}) {
    if (ref $this->{saver}->{back}{$key} eq 'ARRAY') {
      $point = $this->{saver}->{back}{$key}[$i] ;
    }
    else {
      if ($i == 0) { $point = $this->{saver}->{back}{$key} ;}
      else { return &XML::Smart::clone($this->{saver},"/[$i]") ;}
    }
  }  
  else {
    return &XML::Smart::clone($this->{saver},"/[$i]") ;
  }
  
  if (ref $point) {
    return &XML::Smart::clone($this->{saver},$point,undef,undef,undef,$i) ;
  }
  else {
    return &XML::Smart::clone($this->{saver},    {},undef,undef,undef,$i,$point) ;
  }
}

sub STORE {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
  
  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }
  
  if ($this->{saver}->{array}) {
    return $this->{saver}->{array}[$i] = $_[0] ;
  }
  elsif ($i == 0) {
    if (ref $this->{saver}->{back}{$key} eq 'ARRAY') {
      return $this->{saver}->{back}{$key}[0] = $_[0] ;
    }
    else {
      return $this->{saver}->{back}{$key} = $_[0] ;    
    }
  }
  else {
    if (exists $this->{saver}->{back}{$key}) {
      my $k = $this->{saver}->{back}{$key} ;
      $this->{saver}->{back}{$key} = [$k] ;
    }
    else { $this->{saver}->{back}{$key} = [] ;}
    $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
    return $this->{saver}->{array}[$i] = $_[0] ;
  }

  return ;
}

sub FETCHSIZE {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
  
  my @call = caller ;

  if ($this->{saver}->{array}) {
    return( $#{$this->{saver}->{array}} + 1 ) ;
  }
  elsif ($i == 0 && exists $this->{saver}->{back}{$key}) { return 1 ;}

  ## Always return 1! Then when the FETCH(0) is made, it returns a NULL object.
  ## This will avoid warnings!
  return 1 ;
}

sub EXISTS {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
  
  if ($this->{saver}->{array}) {
    if (exists $this->{saver}->{array}[$i]) { return 1 ;}
  }
  elsif ($i == 0 && exists $this->{saver}->{back}{$key}) { return 1 ;}
  
  return ;
}

sub DELETE {
  my $this = shift ;
  my $i = shift ;
  my $key = $this->{saver}->{key} ;
                              
  if ($this->{saver}->{array}) {
    if (exists $this->{saver}->{array}[$i]) {
      return delete $this->{saver}->{array}[$i] ;
    }
  }
  elsif ($i == 0 && exists $this->{saver}->{back}{$key}) {
    my $k = $this->{saver}->{back}{$key} ;
    $this->{saver}->{back}{$key} = undef ;
    return $k  ;
  }
  
  return ;
}

sub CLEAR {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;
  
  if ($this->{saver}->{array}) {
    return @{$this->{saver}->{array}} = () ;
  }
  elsif (exists $this->{saver}->{back}{$key}) {
    return $this->{saver}->{back}{$key} = () ;
  }
  
  return ;
}

sub PUSH {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;

  #print "PUSH>> $key >> @{$this->{saver}->{keyprev}}\n" ;

  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }

  if ( !$this->{saver}->{array} ) {  
    if (exists $this->{saver}->{back}{$key}) {
      if ( ref $this->{saver}->{back}{$key} ne 'ARRAY' ) {
        my $k = $this->{saver}->{back}{$key} ;
        $this->{saver}->{back}{$key} = [$k] ;      
      }
    }
    else { $this->{saver}->{back}{$key} = [] ;}
    $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
    $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
  }
  
  return push(@{$this->{saver}->{array}} , @_) ;
}

sub UNSHIFT {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;

  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }

  if ( !$this->{saver}->{array} ) {
    if (exists $this->{saver}->{back}{$key}) {
      if ( ref $this->{saver}->{back}{$key} ne 'ARRAY' ) {
        my $k = $this->{saver}->{back}{$key} ;
        $this->{saver}->{back}{$key} = [$k] ;      
      }
    }
    else { $this->{saver}->{back}{$key} = [] ;}
    $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
    $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
  }
  
  return unshift(@{$this->{saver}->{array}} , @_) ;
}

sub SPLICE {
  my $this = shift ;
  my $offset = shift || 0 ;
  my $length = shift || $this->FETCHSIZE() - $offset ;
  
  my $key = $this->{saver}->{key} ;
  
  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }

  if ( !$this->{saver}->{array} ) {
    if (exists $this->{saver}->{back}{$key}) {
      if ( ref $this->{saver}->{back}{$key} ne 'ARRAY' ) {
        my $k = $this->{saver}->{back}{$key} ;
        $this->{saver}->{back}{$key} = [$k] ;      
      }
    }
    else { $this->{saver}->{back}{$key} = [] ;}
    $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
    $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
  }
  
  return splice(@{$this->{saver}->{array}} , $offset , $length , @_) ;
}

sub POP {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;

  my $pop ;

  if (!$this->{saver}->{array} && exists $this->{saver}->{back}{$key}) {
    if ( ref $this->{saver}->{back}{$key} eq 'ARRAY' ) {
      $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
      $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
    }
    else { $pop = delete $this->{saver}->{back}{$key} ;}
  }
  
  if ($this->{saver}->{array}) {
    $pop = pop( @{$this->{saver}->{array}} ) ;
    
    if ( $#{$this->{saver}->{array}} == 0 ) {
      $this->{saver}->{back}{$key} = $this->{saver}->{array}[0] ;
      $this->{saver}->{array} = undef ;
      $this->{saver}->{i} = undef ;
    }
    elsif ( $#{$this->{saver}->{array}} < 0 ) {
      $this->{saver}->{back}{$key} = undef ;
      $this->{saver}->{array} = undef ;
      $this->{saver}->{i} = undef ;
    }
  }
  
  return $pop ;
}

sub SHIFT {
  my $this = shift ;
  my $key = $this->{saver}->{key} ;

  my $shift ;

  if (!$this->{saver}->{array} && exists $this->{saver}->{back}{$key}) {
    if ( ref $this->{saver}->{back}{$key} eq 'ARRAY' ) {
      $this->{saver}->{array} = $this->{saver}->{back}{$key} ;
      $this->{saver}->{point} = $this->{saver}->{back}{$key}[0] ;
    }
    else { $shift = delete $this->{saver}->{back}{$key} ;}
  }
  
  if ($this->{saver}->{array}) {
    $shift = shift( @{$this->{saver}->{array}} ) ;
    
    if ( $#{$this->{saver}->{array}} == 0 ) {
      $this->{saver}->{back}{$key} = $this->{saver}->{array}[0] ;
      $this->{saver}->{array} = undef ;
      $this->{saver}->{i} = undef ;
    }
    elsif ( $#{$this->{saver}->{array}} < 0 ) {
      $this->{saver}->{back}{$key} = undef ;
      $this->{saver}->{array} = undef ;
      $this->{saver}->{i} = undef ;
    }
  }
  
  return $shift ;
}

sub STORESIZE {}
sub EXTEND {}

sub UNTIE {}
sub DESTROY  {}

#######################
# XML::SMART::TIEHASH #
#######################

package XML::Smart::TieHash ;

sub TIEHASH {
  my $class = shift ;
  my $saver = shift ;
  my $this = { saver => $saver } ;
  bless($this,$class) ;
}

sub FETCH {
  my $this = shift ;
  my ( $key ) = @_ ;
  my $i ;

  #print "H-FETCH>> $key , $i >> @{$this->{saver}->{keyprev}}\n" ;

  my $point = '' ;
  my $array ;
  
  if (ref($this->{saver}->{point}{$key}) eq 'ARRAY') {
    $array = $this->{saver}->{point}{$key} ;
    $point = $this->{saver}->{point}{$key}[0] ;
    $i = 0 ;
  }
  elsif ( exists $this->{saver}->{point}{$key} ) {
    $point = $this->{saver}->{point}{$key} ;
  }
  else {
    return &XML::Smart::clone($this->{saver},$key) ;
  }
  
  if (ref $point) {
    return &XML::Smart::clone($this->{saver},$point,undef,$array,$key,$i) ;
  }
  else {
    return &XML::Smart::clone($this->{saver},{} ,undef,$array,$key,$i,$point) ;
  }
}

sub FIRSTKEY {
  my $this = shift ;
   
  if (!$this->{saver}->{keyorder}) { $this->_keyorder ;}
  
  return( @{$this->{saver}->{keyorder}}[0] ) ; 
}

sub NEXTKEY  {
  my $this = shift ;
  my ( $key ) = @_ ;
  
  if (!$this->{saver}->{keyorder}) { $this->_keyorder ;}
    
  my $found ;
  foreach my $key_i ( @{$this->{saver}->{keyorder}} ) {
    if ($found) { return($key_i) ;}
    if ($key eq $key_i) { $found = 1 ;}
  }

  return ;
}

sub STORE {
  my $this = shift ;
  my $key = shift ;
  
  if ( $this->{saver}->{null} ) {
    &XML::Smart::_generate_nulltree($this->{saver},$key,$i) ;
  }
  
  if ( ref($this->{saver}->{point}{$key}) eq 'ARRAY' ) {
    return $this->{saver}->{point}{$key}[0] = $_[0] ;
  }
  else {
    if ( !exists $this->{saver}->{point}{$key} ) {
      if (!$this->{saver}->{keyorder}) { $this->_keyorder ;}
      push(@{$this->{saver}->{keyorder}} , $key) ;
    }
    return $this->{saver}->{point}{$key} = $_[0] ;
  }
  return ;
}

sub DELETE   {
  my $this = shift ;
  my ( $key ) = @_ ;
  if ( exists $this->{saver}->{point}{$key} ) {
    $this->{saver}->{keyorder} = undef ;
    return delete $this->{saver}->{point}{$key} ;
  }
  return ;
}

sub CLEAR {
  my $this = shift ;
  $this->{saver}->{keyorder} = undef ;
  %{$this->{saver}->{point}} = () ;
}

sub EXISTS {
  my $this = shift ;
  my ( $key ) = @_ ;
  if ( exists $this->{saver}->{point}{$key} ) { return( 1 ) ;}
  return ;
}

sub UNTIE {}
sub DESTROY  {}

sub _keyorder {
  my $this = shift ;
  my @order ;
  
  foreach my $Key ( sort keys %{ $this->{saver}->{point} } ) {
    if ($Key eq '' || $Key eq '/keys') { next ;}
    push(@order , $Key) ;
  }
  
  $this->{saver}->{keyorder} = \@order ;
}

#######
# END #
#######

1;

__END__

=head1 NAME

XML::Smart - A smart, easy and powerful way to access/create XML files/data.

=head1 DESCRIPTION

This module has an easy way to access/create XML data. It's based on the HASH
tree that is made of the XML data, and enable a dynamic access to it with the
Perl syntax for Hashe and Array, without needing to care if you have a Hashe or an
Array in the tree. In other words, B<each point in the tree work as a Hash and
an Array at the same time>!

You also have extra resources, like a search for nodes by attribute, selection
of an attribute value in each multiple node,  change the returned format, etc...

The module alson handle automatically binary data (encoding/decoding to/from base64),
CDATA (like contents with <tags>) and Unicode. It can be used to create XML files,
load XML from the Web (just pasting an URL as a file path) and it has an easy
way to send XML data through socket, just adding the length of the data in
the <?xml?> header.

You can use I<XML::Smart> with L<XML::Parser>, or with the 2 standart parsers of
XML::Smart:

=over 10

=item I<XML::Smart::Parser>

=item I<XML::Smart::HTMLParser>.

=back

I<XML::Smart::HTMLParser> can be used to load/parse wild/bad XML data, or HTML tags.

=head1 USAGE

  ## Create the object and load the file:
  my $XML = XML::Smart->new('file.xml') ;
  
  ## Force the use of the parser 'XML::Smart::Parser'.
  my $XML = XML::Smart->new('file.xml' , 'XML::Smart::Parser') ;
  
  ## Get from the web:
  my $XML = XML::Smart->new('http://www.perlmonks.org/index.pl?node_id=16046') ;

  ## Cut the root:
  $XML = $XML->cut_root ;

  ## Or change the root:
  $XML = $XML->{hosts} ;

  ## Get the address [0] of server [0]:
  my $srv0_addr0 = $XML->{server}[0]{address}[0] ;
  ## ...or...
  my $srv0_addr0 = $XML->{server}{address} ;
  
  ## Get the server where the attibute 'type' eq 'suse':
  my $server = $XML->{server}('type','eq','suse') ;
  
  ## Get the address again:
  my $addr1 = $server->{address}[1] ;
  ## ...or...
  my $addr1 = $XML->{server}('type','eq','suse'){address}[1] ;
  
  ## Get all the addresses of a server:
  my @addrs = @{$XML->{server}{address}} ;
  ## ...or...
  my @addrs = $XML->{server}{address}('@') ;
  
  ## Get a list of types of all the servers:
  my @types = $XML->{server}('[@]','type') ;
  
  ## Add a new server node:
  my $newsrv = {
  os      => 'Linux' ,
  type    => 'Mandrake' ,
  version => 8.9 ,
  address => [qw(192.168.3.201 192.168.3.202)]
  } ;
  
  push(@{$XML->{server}} , $newsrv) ;

  ## Get/rebuild the XML data:
  my $xmldata = $XML->data ;
  
  ## Save in some file:
  $XML->save('newfile.xml') ;
  
  ## Send through a socket:
  print $socket $XML->data(length => 1) ; ## show the 'length' in the XML header to the
                                          ## socket know the amount of data to read.
  
  __DATA__
  <?xml version="1.0" encoding="iso-8859-1"?>
  <hosts>
    <server os="linux" type="redhat" version="8.0">
      <address>192.168.0.1</address>
      <address>192.168.0.2</address>
    </server>
    <server os="linux" type="suse" version="7.0">
      <address>192.168.1.10</address>
      <address>192.168.1.20</address>
    </server>
    <server address="192.168.2.100" os="linux" type="conectiva" version="9.0"/>
  </hosts>

=head1 METHODS

=head2 new (FILE|DATA|URL , PARSER)

Create a XML object.

B<Arguments:>

=over 10

=item FILE|DATA|URL

The first argument can be:

  - XML data as string.
  - File path.
  - File Handle (GLOB).
  - URL (Need LWP::UserAgent).

If not paste, a null XML tree is started, where you should create your own
XML data, than build/save/send it.

=item PARSER B<(optional)>

Set the XML parser to use. Options:

  XML::Parser
  XML::Smart::Parser
  XML::Smart::HTMLParser

I<XML::Smart::Parser> can only handle basic XML data (not supported PCDATA, and any header like: ENTITY, NOTATION, etc...),
but is a good choice when you don't want to install big modules to parse XML, since it
comes with the main module. But it still can handle CDATA and binary data.

** See I<"PARSING HTML as XML"> for B<XML::Smart::HTMLParser>.

Aliases for the options:

  SMART|REGEXP   => XML::Smart::Parser
  HTML           => XML::Smart::HTMLParser

I<Default:>

If not set it will look for XML::Parser and load it.
If XML::Parser can't be loaded it will use XML::Smart::Parser, that actually is a
clone of XML::Parser::Lite with some fixes.

=back

=head2 copy()

Return a copy of the XML::Smart object (pointing to the base).

** This is good when you want to keep 2 versions of the same XML tree in the memory,
since one object can't change the tree of the other!

=head2 base()

Get back to the base of the tree.

Each query to the XML::Smart object return an object pointing to a different place
in the tree (and share the same HASH tree). So, you can get the main object
again (an object that points to the base):

  my $srv = $XML->{root}{host}{server} ;
  my $addr = $srv->{adress} ;
  my $XML2 = $srv->base() ;
  $XML2->{root}{hosts}...

=head2 back()

Get back one level the pointer in the tree.

** Se I<base()>.

=head2 cut_root()

Cut the root key:

  my $srv = $XML->{rootx}{host}{server} ;
  
  ## Or if you don't know the root name:
  $XML = $XML->cut_root() ;
  my $srv = $XML->{host}{server} ;

** Note that this will cut the root of the pointer in the tree.
So, if you are in some place that have more than one key (multiple roots), the
same object will be retuned without cut anything.

=head2 key()

Return the key of the value.

If wantarray return the index too: return(KEY , I) ;

=head2 i()

Return the index of the value. If the value is from an key (not an ARRAY ref), return 0.

=head2 null()

Return I<true> if the XML object has a null tree or if the pointer is in some place that doesn't exist.

=head2 content()

Return the content of a node:

  ## Data:
  <foo>my content</foo>
  
  ## Access:
  
  my $content = $XML->{foo}->content ;
  print "<<$content>>\n" ; ## show: <<my content>>
  
  ## or just:
  my $content = $XML->{foo} ;

=head2 tree()

Return the HASH tree of the XML data.

** Note that the real HASH tree is returned here. All the other ways return an
object that works like a HASH/ARRAY through tie.

=head2 pointer

Return the HASH tree from the pointer.

=head2 data (OPTIONS)

Return the data of the XML object (rebuilding it).

B<Options:>

=over 10

=item noident

If set to true the data isn't idented.

=item nospace

If set to true the data isn't idented and doesn't have space between the
tags (unless the CONTENT have).

=item lowtag

Make the tags lower case.

=item lowarg

Make the arguments lower case.

=item upertag

Make the tags uper case.

=item uperarg

Make the arguments uper case.

=item length

If set true, add the attribute 'length' with the size of the data to the xml header (<?xml ...?>).
This is useful when you send the data through a socket, since the socket can know the total amount
of data to read.

=item noheader

Do not add  the <?xml ...?> header.

=item nometagen

Do not add the meta generator tag: <?meta generator="XML::Smart" ?>

=item meta

Set the meta tags of the XML document.

Examples:

    my $meta = {
    build_from => "wxWindows 2.4.0" ,
    file => "wx26.htm" ,
    } ;
    
    print $XML->data( meta => $meta ) ;
    
    __DATA__
    <?meta build_from="wxWindows 2.4.0" file="wx283.htm" ?>

Multiple meta:

    my $meta = [
    {build_from => "wxWindows 2.4.0" , file => "wx26.htm" } ,
    {script => "genxml.pl" , ver => "1.0" } ,
    ] ;
    
    __DATA__
    <?meta build_from="wxWindows 2.4.0" file="wx26.htm" ?>
    <?meta script="genxml.pl" ver="1.0" ?>

Or set directly the meta tag:

    my $meta = '<?meta foo="bar" ?>' ;

    ## For multiple:
    my $meta = ['<?meta foo="bar" ?>' , '<?meta x="1" ?>'] ;
    
    print $XML->data( meta => $meta ) ;

=item tree

Set the HASH tree to parse. If not set will use the tree of the XML::Smart object (I<tree()>). ;

=item wild

Accept wild tags and arguments.

** This wont fix wrong keys and tags.

=back

=head2 data_pointer (OPTIONS)

Make the tree from current point in the XML tree (not from the base as data()).

Accept the same OPTIONS of the method B<I<data()>>.

=head2 save (FILEPATH , OPTIONS)

Save the XML data inside a file.

Accept the same OPTIONS of the method B<I<data()>>.

=head1 ACCESS

To access the data you use the object in a way similar to HASH and ARRAY:

  my $XML = XML::Smart->new('file.xml') ;
  
  my $server = $XML->{server} ;

But when you get a key {server}, you are actually accessing the data through tie(),
not directly to the HASH tree inside the object, (This will fix wrong accesses): 

  ## {server} is a normal key, not an ARRAY ref:

  my $server = $XML->{server}[0] ; ## return $XML->{server}
  my $server = $XML->{server}[1] ; ## return UNDEF
  
  ## {server} has an ARRAY with 2 items:

  my $server = $XML->{server} ;    ## return $XML->{server}[0]
  my $server = $XML->{server}[0] ; ## return $XML->{server}[0]
  my $server = $XML->{server}[1] ; ## return $XML->{server}[1]

To get all the values of a multiple attribute/key:

  ## This work having only a string inside {address}, or with an ARRAY ref:
  my @addrsses = @{$XML->{server}{address}} ;

=head2 Select search

When you don't know the position of the nodes, you can select it by some attribute value:

  my $server = $XML->{server}('type','eq','suse') ; ## return $XML->{server}[1]

Syntax for the select search:

  (NAME, CONDITION , VALUE)


=over 10

=item NAME

The attribute name in the node (tag).

=item CONDITION

Can be

  eq  ne  ==  !=  <=  >=  <  >

For REGEX:

  =~  !~
  
  ## Case insensitive:
  =~i !~i

=item VALUE

The value.

For REGEX use like this:

  $XML->{server}('type','=~','^s\w+$') ;

=back

=head2 Select attributes in multiple nodes:

You can get the list of values of an attribute looking in all multiple nodes:

  ## Get all the server types:
  my @types = $XML->{server}('[@]','type') ;

Also as:

  my @types = $XML->{server}{type}('<@') ;

Without the resource:

  my @list ;
  my @servers = @{$XML->{server}} ;
  
  foreach my $servers_i ( @servers ) {
    push(@list , $servers_i->{type} ) ;
  }

=head2 Return format

You can change the returned format:

Syntax:

  (TYPE)

Where TYPE can be:

  $  ## the content
  @  ## an array (list of multiple values)
  %  ## a hash
  
  $@  ## an array, but with the content, not an objects.
  $%  ## a hash, but the values are the content, not an object.
  
  ## The use of $@ and $% is good if you don't want to keep the object
  ## reference (and save memory).
  
  @keys  ## The keys of the node. note that if you have a key with
         ## multiple nodes, it will be replicated (this is the
         ## difference of "keys %{$this->{node}}" ).

  <@ ## Return the attribute in the previous node, but looking for
     ## multiple nodes. Example:
     
  my @names = $this->{method}{wxFrame}{arg}{name}('<@') ;
  #### @names = (parent , id , title) ;
     
  __DATA__
  <method>
    <wxFrame return="wxFrame">
      <arg name="parent" type="wxWindow" /> 
      <arg name="id" type="wxWindowID" /> 
      <arg name="title" type="wxString" /> 
    </wxFrame>
  </method>

Example:

  ## All the servers
  my $name = $XML->{server}{name}('$') ;
  ## ... or:
  my $name = $XML->{server}{name}->content ;
  ## ... or:
  my $name = $XML->{server}{name} ;
  $name = "$name" ;
  
  ## All the servers
  my @servers = $XML->{server}('@') ;
  ## ... or:
  my @servers = @{$XML->{server}} ;
  
  ## It still has the object reference:
  @servers[0]->{name} ;
  
  ## Without the reference:
  my @servers = $XML->{server}('$@') ;


=head2 CONTENT

If a {key} has a content you can access it directly from the variable or
from the method:

  my $server = $XML->{server} ;

  print "Content: $server\n" ;
  ## ...or...
  print "Content: ". $server->content ."\n" ;

So, if you use the object as a string it works as a string,
if you use as an object it works as an object! ;-P

=head1 CREATING XML DATA

To create XML data is easy, you just use as a normal HASH, but you don't need
to care with multiple nodes, and ARRAY creation/convertion!

  ## Create a null XML object:
  my $XML = XML::Smart->new() ;
  
  ## Add a server to the list:
  $XML->{server} = {
  os => 'Linux' ,
  type => 'mandrake' ,
  version => 8.9 ,
  address => '192.168.3.201' ,
  } ;
  
  ## The data now:
  <server address="192.168.3.201" os="Linux" type="mandrake" version="8.9"/>
  
  ## Add a new address to the server. Have an ARRAY creation, convertion
  ## of the previous key to ARRAY:
  $XML->{server}{address}[1] = '192.168.3.202' ;
  
  ## The data now:
  <server os="Linux" type="mandrake" version="8.9">
    <address>192.168.3.201</address>
    <address>192.168.3.202</address>
  </server>ok 19

After create your XML tree you just save it or get the data:

  ## Get the data:
  my $data = $XML->data ;
  
  ## Or save it directly:
  $XML->save('newfile.xml') ;
  
  ## Or send to a socket:
  print $socket $XML->data(length => 1) ;

=head1 BINARY DATA & CDATA

From version 1.2 I<XML::Smart> can handle binary data and CDATA blocks automatically.

B<When parsing>, binary data will be detected as:

  <code dt:dt="binary.base64">f1NPTUUgQklOQVJZIERBVEE=</code>

I<Since this is the oficial automatically format for binary data at L<XML.com|http://www.xml.com/pub/a/98/07/binary/binary.html>.>
The content will be decoded from base64 and saved in the object tree.

CDATA will be parsed as any other content, since CDATA is only a block that
won't be parsed.

B<When creating XML data>, like at $XML->data(), the binary format and CDATA are
detected using this roles:

  BINARY:
  - If have characters that can't be in XML.

  * Characters accepted:
    
    \s \w \d
    !"#$%&'()*+,-./:;<=>?@[\]^`{|}~
    €‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿
    ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
  
  CDATA:
  - If have tags: <...>
  
  CONTENT: (<tag>content</tag>)
  - If have \r\n\t, or ' and " at the same time.


So, this will be a CDATA content:

  <code><![CDATA[
    line1
    <tag_not_parsed>
    line2
  ]]></code>

If a binary content is detected, it will be converted to B<base64> and a B<dt:dt>
attribute added in the tag to tell the format.

  <code dt:dt="binary.base64">f1NPTUUgQklOQVJZIERBVEE=</code>

=head1 UNICODE and ASCII-extended (ISO-8859-1)

I<XML::Smart> support only this 2 encode types, Unicode (UTF-8) and ASCII-extended (ISO-8859-1),
and must be enough. (B<Note that UTF-8 is only supported on Perl-5.8+>).

When creating XML data, if any UTF-8 character is detected the I<encoding> attribute
in the <?xml ...?> header will be set to UTF-8:

  <?xml version="1.0" encoding="utf-8" ?>
  <data>Ã€</data>

If not, the I<iso-8859-1> is used:

  <?xml version="1.0" encoding="iso-8859-1" ?>
  <data>€</data>

When loading XML data with UTF-8, Perl (5.8+) should make all the work internally.

=head1 PARSING HTML as XML, or BAD XML formats

You can use the special parser B<XML::Smart::HTMLParser> to "use" HTML as XML
or not well-formed XML data.

The differences between an normal XML parser and I<XML::Smart::HTMLParser> are:

  - Accept values without quotes:
    <foo bar=x>
    
  - Accept any data in the values, including <> and &:
    <root><echo sample="echo \"Hello!\">out.txt"></root>
    
  - Accpet URI values without quotes:
    <link url=http://www.foo.com/dir/file?query?q=v&x=y target=#_blank>
  
  - Don't need to close the tags adding the '/' before '>':
    <root><foo bar="1"></root>
    
    ** Note that the parse will try hard to detect the nodes, and where
       auto-close or not.
  
  - Don't need to have only one root:
    <foo>data</foo><bar>data</bar>

So, I<XML::Smart::HTMLParser> is a willd way to load markuped data (like HTML),
or if you don't want to care with quotes, end tags, etc... when writing by hand your XML data.
So, you can write by hand a bad XML file, load it with I<XML::Smart::HTMLParser>, and B<rewrite well>
saving it again! ;-P

** Note that <SCRIPT> tags will only by parse right if the content is inside
comments <!--...-->, since they can have tags:

  <SCRIPT LANGUAGE="JavaScript"><!--
  document.writeln("some <tag> in the string");
  --></SCRIPT>

=head1 ENTITIES

Entities (ENTITY) are handled by the parser. So, if you use L<XML::Parser> it will do all the job fine.
But If you use I<XML::Smart::Parser> or I<XML::Smart::HMLParser>, only the basic entities (defaults)
will be parsed:

  &lt;   => The less than sign (<).
  &gt;   => The greater than sign (>).
  &amp;  => The ampersand (&).
  &apos; => The single quote or apostrophe (').
  &quot; => The double quote (").
  
  &#ddd;  => An ASCII character or an Unicode character (>255). Where ddd is a decimal.
  &#xHHH; => An Unicode character. Where HHH is in hexadecimal.

B<When creating XML data>, already existent Entities won't be changed, and the
characters '<', '&' and '>' will be converted to the appropriated entity.

** Note that if a content have a <tag>, the characters '<' and '>' won't be converted
to entities, and this content will be inside a CDATA block.

=head1 WHY AND HOW IT WORKS

Every one that have tried to use Perl HASH and ARRAY to access XML data, like in L<XML::Simple>,
have some problems to add new nodes, or to access the node when the user doesn't know if it's
inside an ARRAY, a HASH or a HASH key. I<XML::Smart> create around it a very dynamic way to
access the data, since at the same time any node/point in the tree can be a HASH and
an ARRAY. You also have other extra resources, like a search for nodes by attribute:

  my $server = $XML->{server}('type','eq','suse') ; ## This syntax is not wrong! ;-)

  ## Instead of:
  my $server = $XML->{server}[1] ;
  
  __DATA__
  <hosts>
    <server os="linux" type="redhat" version="8.0">
    <server os="linux" type="suse" version="7.0">
  </hosts>

The idea for this module, came from the problem that exists to access a complex struture in XML.
You just need to know how is this structure, something that is generally made looking the XML file (what is wrong).
But in the same time is hard to always check (by code) the struture, before access it.
XML is a good and easy format to declare your data, but to extrac it in a tree way, at least in my opinion,
isn't easy. To fix that, came to my mind a way to access the data with some query language, like SQL.
The first idea was to access using something like:

  XML.foo.bar.baz{arg1}

  X = XML.foo.bar*
  X.baz{arg1}
  
  XML.hosts.server[0]{argx}

And saw that this is very similar to Hashes and Arrays in Perl:

  $XML->{foo}{bar}{baz}{arg1} ;
  
  $X = $XML->{foo}{bar} ;
  $X->{baz}{arg1} ;
  
  $XML->{hosts}{server}[0]{argx} ;

But the problem of Hash and Array, is not knowing when you have an Array reference or not.
For example, in XML::Simple:

  ## This is very diffenrent
  $XML->{server}{address} ;
  ## ... of this:
  $XML->{server}{address}[0] ;

So, why don't make both ways work? Because you need to make something crazy!

To create I<XML::Smart>, first I have created the module L<Object::MultiType>.
With it you can have an object that works at the same time as a HASH, ARRAY, SCALAR,
CODE & GLOB. So you can do things like this with the same object:

  $obj = Object::MultiType->new() ;
  
  $obj->{key} ;
  $obj->[0] ;
  $obj->method ;  
  
  @l = @{$obj} ;
  %h = %{$obj} ;
  
  &$obj(args) ;
  
  print $obj "send data\n" ;

Seems to be crazy, and can be more if you use tie() inside it, and this is what I<XML::Smart> does.

For I<XML::Smart>, the access in the Hash and Array way paste through tie(). In other words, you have a tied HASH
and tied ARRAY inside it. This tied Hash and Array work together, soo B<you can access a Hash key
as the index 0 of an Array, or access an index 0 as the Hash key>:

  %hash = (
  key => ['a','b','c']
  ) ;
  
  $hash->{key}    ## return $hash{key}[0]
  $hash->{key}[0] ## return $hash{key}[0]  
  $hash->{key}[1] ## return $hash{key}[1]
  
  ## Inverse:
  
  %hash = ( key => 'a' ) ;
  
  $hash->{key}    ## return $hash{key}
  $hash->{key}[0] ## return $hash{key}
  $hash->{key}[1] ## return undef

The best thing of this new resource is to avoid wrong access to the data and warnings when you try to
access a Hash having an Array (and the inverse). Thing that generally make the script die().

Once having an easy access to the data, you can use the same resource to B<create> data!
For example:

  ## Previous data:
  <hosts>
    <server address="192.168.2.100" os="linux" type="conectiva" version="9.0"/>
  </hosts>
  
  ## Now you have {address} as a normal key with a string inside:
  $XML->{hosts}{server}{address}
  
  ## And to add a new address, the key {address} need to be an ARRAY ref!
  ## So, XML::Smart make the convertion: ;-P
  $XML->{hosts}{server}{address}[1] = '192.168.2.101' ;
  
  ## Adding to a list that you don't know the size:
  push(@{$XML->{hosts}{server}{address}} , '192.168.2.102') ;
  
  ## The data now:
  <hosts>
    <server os="linux" type="conectiva" version="9.0"/>
      <address>192.168.2.100</address>
      <address>192.168.2.101</address>
      <address>192.168.2.102</address>
    </server>
  </hosts>

Than after changing your XML tree using the Hash and Array resources you just
get the data remade (through the Hash tree inside the object):

  my $xmldata = $XML->data ;

B<But note that I<XML::Smart> always return an object>! Even when you get a final
key. So this actually returns another object, pointhing (inside it) to the key:

  $addr = $XML->{hosts}{server}{address}[0] ;
  
  ## Since $addr is an object you can TRY to access more data:
  $addr->{foo}{bar} ; ## This doens't make warnings! just return UNDEF.

  ## But you can use it like a normal SCALAR too:

  print "$addr\n" ;

  $addr .= ':80' ; ## After this $addr isn't an object any more, just a SCALAR!

=head1 SEE ALSO

L<XML::Parser>, L<XML::Parser::Lite>, L<XML>.

L<Object::MultiType> - This is the module that make everything possible,
and was created specially for I<XML::Smart>. ;-P

L<XML.com|http://www.xml.com>

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

Before make this module I dislike to use XML, and made everything to avoid it.
Now I can use XML fine! ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


