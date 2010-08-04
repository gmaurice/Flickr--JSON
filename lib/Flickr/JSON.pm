package Flickr::JSON;

our $VERSION = '0.1.0';

use Moose;

use Text::Trim;
use JSON;
use Digest::MD5 qw(md5_hex);
use Flickr::JSON::Response;
use LWP::UserAgent;
use YAML::Syck;

has timeout => (
	is	=> 'rw',
	isa	=> 'Int',
	lazy	=> 1,
	default => 60,
	trigger => \&set_api_timeout
);

has 'useragent' => (
    isa      => 'LWP::UserAgent',
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub { LWP::UserAgent->new; },
);

has 'api_key' => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
);

has 'api_secret' => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
);

has 'base_url' => (
    isa      => 'Str',
    is       => 'rw',
    lazy     => 1,
    default  => "http://api.flickr.com/services/rest/",
);

has 'auth_url' => (
    isa      => 'Str',
    is       => 'rw',
    lazy     => 1,
    default  => "http://api.flickr.com/services/auth/",
);

has 'response' => (
    isa      => 'Flickr::JSON::Response',
    is       => 'rw',
    lazy     => 1,
    default  => sub {
    	Flickr::JSON::Response->new;
    },
);

has 'with_bindings' => (
	isa		=> 'Bool',
	is	=> 'rw',
	trigger => \&load_bindings
);

sub BUILD {

	my $self = shift;
	my $args = shift;

	if (! exists $args->{with_bindings}){
		Moose::Util::apply_all_roles( $self, 'Flickr::JSON::Bindings' );
		$self->{with_bindings} = 1;
	}
	
	$self;
}

## ATTRIBUTE TRIGGERS

sub set_api_timeout {
	my $self = shift;
	my $timeout = shift;
	$self->useragent->timeout($timeout);
};

sub load_bindings{
		my $self = shift;
		my $with_bindings = shift;
		
		if ( not defined $with_bindings ){
			$with_bindings = 1;
		}
		
		if ( $with_bindings ){
			Moose::Util::apply_all_roles( $self, 'Flickr::JSON::Bindings' );
		}
};

## METHODS

sub sign_args {
	my $self = shift;
	my $args = shift;

	my $sig  = $self->api_secret;

	foreach my $key (sort {$a cmp $b} keys %{$args}) {

		my $value = (defined($args->{$key})) ? $args->{$key} : "";
		$sig .= $key . $value;
	}

	return md5_hex($sig);
};


sub method {
    my ( $self, $method, $args ) = @_;

    my $url = $self->url( $method ,  $args );
    my $request = HTTP::Request->new( GET => $url );
    my $response = $self->useragent->request( $request );

    my $result   = undef;
    
    if( $response->is_success ) {
        my $content = $response->decoded_content;
        $content = trim $content;
        $content =~ s/^jsonFlickrApi\((.+)\)$/$1/;
		
        #print $content;
	#$content =~ s/\{"_content":(["']?[^"]*["']?)\}/$1/g;
	$content =~ s/\{"_content":(["']{1}[^}]*["']{1})\}/$1/g;
        #print $content;
	$self->response( Flickr::JSON::Response->new );

        $result = decode_json $content;
        if ( $result->{stat} eq 'fail' ){
		$self->response->success(0);
 		$self->response->error_code(delete $result->{code});
		$self->response->error_message(delete $result->{message});
	}else{
		$self->response->success(1);
	}
    	delete $result->{stat};
		$self->response->code($response->code);
		$self->response->message($response->message);
		$self->response->content($result);
		$self->response->raw_json($content);
    } else {
    	$self->response(
    		Flickr::JSON::Response->new ( 
        		success => 0,
        		code => $response->code,
        		message => $response->message,
        		content => undef
        	)
        );
    }
    $self->response;
};

sub execute_request {
    my ( $self, $request ) = @_;

    $self->method( $request->{method} , $request->{args} );
};

sub url {
    my ( $self, $method, $args ) = @_;

    my %params = (
        method  => $method,
        api_key => $self->api_key,
        api_secret=> $self->api_secret,
        format  => 'json',
        %$args,
    );

    $params{api_sig} = $self->sign_args(\%params);

    $self->base_url . ( ( $self->base_url !~ /\/$/ ) ? '/' : '' )
        . '?' . join( '&', map { $_ . '=' . $params{ $_ } } keys %params );    
};


1;
__END__

=head1 NAME

Flickr::JSON -

=head1 SYNOPSIS

  use Flickr::JSON;

=head1 DESCRIPTION

Flickr::JSON provides an easy access to Flickr API with JSON format.

=head1 AUTHOR

Camille Maussang E<lt>camille.maussang@rtgi.frE<gt>
Germain Maurice E<lt>germain.maurice@linkfluence.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
