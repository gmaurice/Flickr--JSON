package Flickr::JSON::Bindings;

use Moose::Role;

## Here you can add any binding you want to request the Flickr API via this kind of calls :
## $api->photosets_get_list('$id', { optional_key => $optional_value };


sub photosets_get_list {
    my $self = shift;
    my $user_id = shift ;
    my $optional = shift || {} ;

    my $response = $self->method( 'flickr.photosets.getList' => 
    	{ 
    		user_id => $user_id,
    		%$optional
    	}
    );

    my $sets = [];

    if( $response->is_success ) {
        $sets = $response->content->{ photoset };
    }

    $sets;
};

sub photosets_get_photos {
    my $self = shift;
    my $photoset_id = shift ;
    my $optional = shift || {} ;

    my $response = $self->method( 'flickr.photosets.getPhotos' => 
    	{
            photoset_id => $photoset_id,
            %$optional
        }
    );

    my $photos = [];
    
    if( $response->is_success ) {
        $photos = $response->content->{ photo };
    }
    
    $photos;
};

1;