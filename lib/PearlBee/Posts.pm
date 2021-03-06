package PearlBee::Posts;
# ABSTRACT: Posts-related paths

use Dancer2 appname => 'PearlBee';
use Dancer2::Plugin::DBIC;
use PearlBee::Helpers::Markdown 'markdown';

my $model = PearlBee::Model::Posts->new(
    user_rs     => resultset('User'),
    post_rs     => resultset('Post'),
    post_tag_rs => resultset('PostTag'),
    uri_for     => \&uri_for,
);

my %sort = map +($_, $_), qw( id created_at updated_at );
my %dir  = map +($_, "-$_"), qw( asc desc );

get '/posts' => sub {
    my $per_page  = int(query_parameters->{'per_page'} // 0) || 10;
    my $page      = int(query_parameters->{'page'}     // 0) || 1;
    my $sort      = $sort{ query_parameters->{'sort'}      || 'created_at' } || 'created_at';
    my $direction = $dir{  query_parameters->{'direction'} || 'desc' }       || '-desc';

    if ($per_page > 50) {
        $per_page = 50;
    }

    my ($pagination, @posts) = $model->search_posts({
        per_page        => $per_page,
        page            => $page,
        sort            => $sort,
        direction       => $direction,
        tags            => query_parameters->{'tags'},
        filter          => query_parameters->{'filter'},
        with_pagination => 1,
    });

    # TODO: feature_image, cover_image from meta
    # FIXME: this is wasteful and slow
    my $rs = resultset('User');
    for (@posts) {
        my $author = $rs->find({username => $_->{author}{username}});

        $_->{author}{email}         = $author->email;
        $_->{author}{profile_image} = $author->avatar;
        $_->{author}{url}           = '/users/' . $_->{author}{username};

        $_->{authors} = [ $_->{author} ];
    }

    template 'index' => {
        posts      => \@posts,
        context    => 'home',
        pagination => {
            page  => $pagination->current_page,
            pages => $pagination->last_page,
            total => $pagination->total_entries,
            next  => $pagination->next_page,
            prev  => $pagination->previous_page,
            limit => $pagination->entries_per_page,
        },
    };
};

get '/users/:author' => sub {
    my $author    = route_parameters->{'author'};
    my $per_page  = int(query_parameters->{'per_page'} // 0) || 10;
    my $page      = int(query_parameters->{'page'}     // 0) || 1;
    my $sort      = $sort{ query_parameters->{'sort'}      || 'created_at' } || 'created_at';
    my $direction = $dir{  query_parameters->{'direction'} || 'desc' }       || '-desc';

    if ($per_page > 50) {
        $per_page = 50;
    }

    my ($pagination, @posts) = $model->search_posts({
        author_username => $author,
        per_page        => $per_page,
        page            => $page,
        sort            => $sort,
        direction       => $direction,
        tags            => query_parameters->{'tags'},
        filter          => query_parameters->{'filter'},
        with_pagination => 1,
    });

    # TODO: feature_image, cover_image from meta
    # FIXME: this is wasteful and slow
    my $rs = resultset('User');
    for (@posts) {
        my $author = $rs->find({username => $_->{author}{username}});

        $_->{author}{email}         = $author->email;
        $_->{author}{profile_image} = $author->avatar;
        $_->{author}{url}           = '/users/' . $_->{author}{username};

        $_->{authors} = [ $_->{author} ];
    }

    my $author_obj = resultset('User')->find( { username => $author } );
    my %author = $author_obj->get_columns;
    $author{profile_image} = $author_obj->avatar;
    $author{url}           = uri_for('/users/' . $author);

    template 'author' => {
        author  => \%author,
        posts   => \@posts,
        pagination => {
            page  => $pagination->current_page,
            pages => $pagination->last_page,
            total => $pagination->total_entries,
            next  => $pagination->next_page,
            prev  => $pagination->previous_page,
            limit => $pagination->entries_per_page,
        },
        context => 'author'
    };
};

get '/:author/:slug' => sub {
    my $author = route_parameters->{'author'};
    my $slug   = route_parameters->{'slug'};

    my ($post) = $model->search_posts({
        author_username => $author,
        slug            => $slug,
    });

    if (!$post) {
        status 'not_found';
        return 'Post not found';
    }

    # TODO: feature_image, cover_image from meta
    # $post->{feature_image} = 'https://casper.ghost.org/v1.0.0/images/welcome.jpg';
    my $author_obj = resultset('User')->find({username => $author});

    $post->{author}{email}         = $author_obj->email;
    $post->{author}{profile_image} = $author_obj->avatar;
    $post->{author}{url}           = uri_for('/users/' . $author);

    $post->{authors} = [ $post->{author} ];
    $post->{content} = markdown( $post->{content} );

    $post->{comments} = [
        map {
            my %row = $_->get_columns;
            $row{author}                = { $_->author->get_columns };
            $row{author}{profile_image} = $_->author->avatar;
            $row{author}{url}           = uri_for('/users/' . $_->author->username);
            $row{created_at_time_ago}   = $_->created_at_time_ago;
            \%row;
        }
        resultset('Comment')->search(
            {
                'me.post'                  => $post->{id},
                'me.status'                => 'published',
                'author.verified_by_peers' => 1
            },
            {
                prefetch => 'author',
            }
        )->all
    ];

    template post => { post => $post, context => 'post' };
};

1;
