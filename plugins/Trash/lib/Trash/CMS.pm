package Trash::CMS;
use strict;
use warnings;

sub trash {
    my $app = shift;

    require MT::Entry;
    my $save = \&MT::Entry::save;
    local *MT::Entry::save = sub {
        my $entry = shift;
        $entry->trash(1);
        $save->($entry);
    };

    require MT::CMS::Entry;
    MT::CMS::Entry::update_entry_status( $app, MT::Entry::HOLD(),
        scalar $app->param('id') );
}

sub restore_entry {
    my $app = shift;
    return unless $app->validate_magic;

    $app->setup_filtered_ids
        if $app->param('all_selected');

    my @ids    = $app->param('id');
    my $author = $app->user;
    require MT::Entry;
    my $iter = MT::Entry->load_iter( { id => \@ids } );
    while ( my $entry = $iter->() ) {

        return $app->permission_denied()
            unless $author->is_superuser
            || ( ( $entry->class eq 'entry' )
            && $author->permissions( $entry->blog_id )
            ->can_edit_entry( $entry, $author, 1 ) )
            || ( ( $entry->class eq 'page' )
            && $author->permissions( $entry->blog_id )->can_manage_pages );

        $entry->trash(undef);
        $entry->update();
    }

    $app->redirect(
        $app->uri(
            mode => 'list_trash',
            args => {
                _type    => $app->param('_type') || 'entry',
                blog_id  => $app->blog ? $app->blog->id : 0,
                restored => 1,
            }
        )
    );
}

sub list_trash {
    my $app = shift;
    $app->forward(
        'list',
        {   _type   => scalar $app->param('_type'),
            blog_id => $app->blog ? $app->blog->id : 0
        }
    );
}

sub filtered_list_trash {
    my $app   = shift;
    my $param = $app->param()->{param};
    delete $param->{__mode};
    $app->forward( 'filtered_list', $param );
}

1;
