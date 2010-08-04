package Flickr::JSON::Response;

use Moose;
use YAML::Syck;
has 'content' => (
	is	=> "rw",
	isa => "HashRef|Undef",
	lazy => 1,
	default => sub {},
	trigger => \&prepare_content
);

has 'error_code' => (
	is => "rw",
	isa => "Int|Undef",
	lazy => 1,
	default => undef,
);

has 'error_message' => (
	is	=> "rw",
	isa => "Str|Undef",
	lazy => 1,
	default => undef,
);

has 'code' => (
	is => "rw",
	isa => "Int|Undef",
	lazy => 1,
	default => undef,
);

has 'message' => (
	is	=> "rw",
	isa => "Str|Undef",
	lazy => 1,
	default => undef,
);


has 'success' => (
	is => "rw",
	isa => "Bool",
	lazy => 1,
	default => 0,
	predicate => "is_success",
);

has 'raw_json' => (
	is	=> "rw",
	isa => "Str|Undef",
	lazy => 1,
	default => undef,
);

sub prepare_content {
	my $self = shift;
	$self->{content} =  $self->{content}->{ (keys %{$self->content})[0]  };
};

no Moose;
1;
