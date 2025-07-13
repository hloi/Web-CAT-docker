#############################################################################
## Name:        Tree.pm
## Purpose:     XML::Smart::Tree
## Author:      Graciliano M. P.
## Modified by:
## Created:     10/05/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package XML::Smart::Tree ;

no warnings ;

our ($VERSION) ;
$VERSION = '1.0' ;

  my %PARSERS = (
  XML_Parser => 0 ,
  XML_Smart_Parser => 0 ,
  XML_Smart_HTMLParser => 0 ,
  ) ;
  
  my $LOADED ;

###################
# LOAD_XML_PARSER #
###################

sub load_XML_Parser {
  eval('use XML::Parser ;') ;
  if ($@) { return( undef ) ;}
  
  my $xml = XML::Parser->new(Style => 'Tree') ;
  my $tree = $xml->parse('<root><foo arg1="t1" arg2="t2" /></root>') ;
  
  if (!$tree || ref($tree) ne 'ARRAY') { return( undef ) ;}
  if ($tree->[1][2][0]{arg1} eq 't1') { return( 1 ) ;}
  return( undef ) ;
}

#########################
# LOAD_XML_SMART_PARSER #
#########################

sub load_XML_Smart_Parser {
  eval('use XML::Smart::Parser ;') ;
  if ($@) { return( undef ) ;}
  return(1) ;
}

#############################
# LOAD_XML_SMART_HTMLPARSER #
#############################

sub load_XML_Smart_HTMLParser {
  eval('use XML::Smart::HTMLParser ;') ;
  if ($@) { return( undef ) ;}
  return(1) ;
}

########
# LOAD #
########

sub load {
  my ( $parser ) = @_ ;
  my $module ;
  
  if ($parser) {
    $parser =~ s/:+/_/gs ;
    $parser =~ s/\W//g ;
    
    if    ($parser =~ /^html?$/i) { $parser = 'XML_Smart_HTMLParser' ;}
    elsif ($parser =~ /^(?:re|smart)/i) { $parser = 'XML_Smart_Parser' ;}
    
    foreach my $Key ( keys %PARSERS ) {
      if ($Key =~ /^$parser$/i) { $module = $Key ; last ;}
    }
  }
  
  if ($module eq 'XML_Parser') {
    $PARSERS{XML_Parser} = 1 if &load_XML_Parser() ;
  }
  elsif ($module eq 'XML_Smart_Parser') {
    $PARSERS{XML_Smart_Parser} = 1 if &load_XML_Smart_Parser() ;
  }
  elsif ($module eq 'XML_Smart_HTMLParser') {
    $PARSERS{XML_Smart_HTMLParser} = 1 if &load_XML_Smart_HTMLParser() ;
  }
  elsif (!$LOADED) {
    $PARSERS{XML_Parser} = 1 if &load_XML_Parser() ;
    $module = 'XML_Parser' ;
    if ( !$PARSERS{XML_Parser} ) {
      $PARSERS{XML_Smart_Parser} = 1 if &load_XML_Smart_Parser() ;  
      $module = 'XML_Smart_Parser' ;
    }
    $LOADED = 1 ;
  }
  
  return($module) ;
}

#########
# PARSE #
#########

sub parse {
  my $module = $_[1] ;
  
  my $data ;
  {
    my ($fh,$open) ;
    
    if (ref($_[0]) eq 'GLOB') { $fh = $_[0] ;}
    elsif ($_[0] =~ /^http:\/\/\w+[^\r\n]+$/s) { $data = &get_url($_[0]) ;}
    elsif ($_[0] =~ /<.*?>/s) { $data = $_[0] ;}
    else { open ($fh,$_[0]) ; binmode($fh) ; $open = 1 ;}
    
    if ($fh) {
      1 while( read($fh, $data , 1024*8 , length($data) ) ) ;
      close($fh) if $open ;
    }
  }
  
  if ($data !~ /<.*?>/s) { return( {} ) ;}
  
  if (!$module || !$PARSERS{$module}) {
    if    ($PARSERS{XML_Parser}) { $module = 'XML_Parser' ;}
    elsif ($PARSERS{XML_Smart_Parser}) { $module = 'XML_Smart_Parser' ;}
  }
  
  my $xml ;
  if ($module eq 'XML_Parser') { $xml = XML::Parser->new() ;}
  elsif ($module eq 'XML_Smart_Parser') { $xml = XML::Smart::Parser->new() ;}
  elsif ($module eq 'XML_Smart_HTMLParser') { $xml = XML::Smart::HTMLParser->new() ;}
  else { croak("Can't find a parser for XML!") ;}
  
  shift(@_) ;
  if ( $_[0] =~ /^\s*(?:XML_\w+|html?|re\w+|smart)\s*$/i) { shift(@_) ;}

  my ( %args ) = @_ ;
  
  if ( $args{lowtag} ) { $xml->{SMART}{tag} = 1 ;}
  if ( $args{upertag} ) { $xml->{SMART}{tag} = 2 ;}
  if ( $args{lowarg} ) { $xml->{SMART}{arg} = 1 ;}
  if ( $args{uperarg} ) { $xml->{SMART}{arg} = 2 ;}
  
  $xml->setHandlers(
  Init => \&_Init ,
  Start => \&_Start ,
  Char  => \&_Char ,
  End   => \&_End ,
  Final => \&_Final ,
  ) ;
  
  my $tree = $xml->parse($data);
  return( $tree ) ;
}

###########
# GET_URL #
###########

sub get_url {
  my ( $url ) = @_ ;
  my $data ;
  
  require LWP ;
  require LWP::UserAgent ;

  my $ua = LWP::UserAgent->new();
  
  my $agent = $ua->agent() ;
  $agent = "XML::Smart/$XML::Smart::VERSION $agent" ;
  $ua->agent($agent) ;

  my $req = HTTP::Request->new(GET => $url) ;
  my $res = $ua->request($req) ;

  if ($res->is_success) { return $res->content ;}
  else { return undef ;}
}

##########
# MODULE #
##########

sub module {
  foreach my $Key ( keys %PARSERS ) {
    if ($PARSERS{$Key}) {
      my $module = $Key ;
      $module =~ s/_/::/g ;
      return( $module ) ;
    }
  }
  return('') ;
}

#########
# _INIT #
#########

sub _Init {
  my $this = shift ;
  $this->{PARSING}{tree} = {} ;
  $this->{PARSING}{p} = $this->{PARSING}{tree} ;
}

##########
# _START #
##########

sub _Start { #print "START>> @_[1]\n" ;
  my $this = shift ;
  my ($tag , %args) = @_ ;
  
  if    ( $this->{SMART}{tag} == 1 ) { $tag = lc($tag) ;}
  elsif ( $this->{SMART}{tag} == 2 ) { $tag = uc($tag) ;}
  
  if ( $this->{SMART}{arg} ) {
    my $type = $this->{SMART}{arg} ;
    my %argsok ;
    foreach my $Key ( keys %args ) {
      my $k ;
      if    ($type == 1) { $k = lc($Key) ;}
      elsif ($type == 2) { $k = uc($Key) ;}
      
      if (exists $argsok{$k}) {
        if ( ref $argsok{$k} ne 'ARRAY' ) {
          my $key = $argsok{$k} ; 
          $argsok{$k} = [$key] ;
        }
        push(@{$argsok{$k}} , $args{$Key}) ;
      }
      else { $argsok{$k} = $args{$Key} ;}
    }
    
    %args = %argsok ;
  }

  $args{'/tag'} = $tag ;
  $args{'/back'} = $this->{PARSING}{p} ;

  push( @{$this->{PARSING}{p}{'/keys'}} , $tag) ;
  
  if ($this->{NOENTITY}) {
    foreach my $Key ( keys %args ) { &XML::Smart::_parse_basic_entity( $args{$Key} ) ;}
  }
  
  if ( defined $this->{PARSING}{p}{$tag} ) {
    if ( ref($this->{PARSING}{p}{$tag}) ne 'ARRAY' ) {
      my $prev = $this->{PARSING}{p}{$tag} ;
      $this->{PARSING}{p}{$tag} = [$prev] ;
    }
    push(@{$this->{PARSING}{p}{$tag}} , \%args) ;
    
    my $i = @{$this->{PARSING}{p}{$tag}} ; $i-- ;
    $args{'/i'} = $i ;
    
    $this->{PARSING}{p} = \%args ;
  }
  else {
    $this->{PARSING}{p}{$tag} = \%args ;
    $this->{PARSING}{p} = \%args ;
  }
}

#########
# _CHAR #
#########

sub _Char {
  my $this = shift ;
  #print "CONT>> ##@_##\n" ;

  my $content = $_[0] ;
  
  if (! defined $this->{PARSING}{p}{'dt:dt'} && defined $this->{PARSING}{p}{'DT:DT'}) {
    $this->{PARSING}{p}{'dt:dt'} = delete $this->{PARSING}{p}{'DT:DT'} ;
  }
  
  if ( $this->{PARSING}{p}{'dt:dt'} =~ /binary\.base64/si ) {
    require XML::Smart::Base64 ;
    $content = &XML::Smart::Base64::decode_base64($content) ;
    delete $this->{PARSING}{p}{'dt:dt'} ;
  }
  elsif ($this->{NOENTITY}) { &XML::Smart::_parse_basic_entity($content) ;}
  
  $this->{PARSING}{p}{CONTENT} .= $content ;
  push(@{$this->{content_ref}} , $this->{PARSING}{p} ) ;
}

########
# _END #
########

sub _End { #print "END>> @_[1]\n" ;
  my $this = shift ;
  my $tag = shift ;
  
  if    ( $this->{SMART}{tag} == 1 ) { $tag = lc($tag) ;}
  elsif ( $this->{SMART}{tag} == 2 ) { $tag = uc($tag) ;}

  if ( $this->{PARSING}{p}{'/tag'} ne $tag ) { return ;}

  delete $this->{PARSING}{p}{'/tag'} ;
  
  my $back  = delete $this->{PARSING}{p}{'/back'} ;
  my $i = delete $this->{PARSING}{p}{'/i'} || 0 ;
  
  my $nkeys = keys %{$this->{PARSING}{p}} ;
  
  if ( $nkeys == 1 && defined $this->{PARSING}{p}{CONTENT} ) {
    if (ref($back->{$tag}) eq 'ARRAY') { $back->{$tag}[$i] = $this->{PARSING}{p}{CONTENT} ;}
    else { $back->{$tag} = $this->{PARSING}{p}{CONTENT} ;}
  }
  
  $this->{PARSING}{p} = $back ;
}

##########
# _FINAL #
##########

sub _Final {
  my $this = shift ;
  my $tree = $this->{PARSING}{tree} ;
  
  foreach my $hash ( @{$this->{content_ref}} ) {
    if ( $$hash{CONTENT} !~ /\S/s ) { delete $$hash{CONTENT} ;}
  }
  
  delete($this->{PARSING}) ;
  return($tree) ;
}

#######
# END #
#######

1;

