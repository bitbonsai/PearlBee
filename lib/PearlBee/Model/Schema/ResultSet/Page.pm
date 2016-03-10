package  PearlBee::Model::Schema::ResultSet::Page;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

use PearlBee::Helpers::Util qw/string_to_slug generate_new_slug_name/;

use String::Util qw(trim);

=head2 Create a new page

=cut

sub can_create {
  my ($self, $params) = @_;

  my $title   = $params->{title};
  my $slug    = $params->{slug};
  my $content = $params->{content};
  my $user_id = $params->{user_id};
  my $status  = $params->{status};
  my $cover   = $params->{cover};

  my $page = $self->create({
    title   => $title,
    slug    => $slug,
    content => $content,
    user_id => $user_id,
    status  => $status,
    cover   => $cover,
  });

  return $page;
}

=item Check if the slug is already used, if so generate a new slug or return the old one

=cut

sub check_slug {
  my ($self, $slug, $page_id) = @_;
  
  my $schema = $self->result_source->schema;
  $slug      = string_to_slug( $slug );
  
  my $found_slug   = $page_id
  			? $schema->resultset('Page')->search({ id => { '!=' => $page_id }, slug => $slug })->first
  			: $schema->resultset('Page')->find({ slug => $slug });
  my $slug_changed = 0;
  
  if ( $found_slug ) {
    # Extract the pages w_ith slugs starting the same with the submited slug
    my @pages_with_same_slug = $schema->resultset('Page')->search({ slug => { like => "$slug%"}});
    my @slugs = map { $_->slug } @pages_with_same_slug;
    
    $slug         = generate_new_slug_name($slug, \@slugs);
    $slug_changed = 1;
  }
  
  return ($slug, $slug_changed);
}

sub page_slug_exists {
  my ($self, $slug, $user_id) = @_;

  my $schema = $self->result_source->schema;
  my $page   = $schema->resultset('Page')->search({ slug => $slug, user_id => $user_id })->first();

  return $page
}

=head

Get the number of comments for this page

=cut

sub nr_of_comments {
  my ($self) = @_;

  my @comments = grep { $_->status eq 'approved' } $self->comments;

  return scalar @comments;
}

=head

Get all tags as a string sepparated by a comma

=cut

sub get_string_tags {
  my ($self) = @_;

  my @page_tags   = $self->page_tags;
  my @tag_names   = map { $_->tag->name } @page_tags;
  my $joined_tags = join(', ', @tag_names);

  return $joined_tags;
}

=head

Status updates

=cut

sub publish {
  my ($self, $user) = @_;

  $self->update({ status => 'published' }) if
    $self->is_authorized( $user );
}

sub draft {
  my ($self, $user) = @_;

  $self->update({ status => 'draft' }) if
    $self->is_authorized( $user );
}


sub trash {
  my ($self, $user) = @_;

  $self->update({ status => 'trash' }) if
    $self->is_authorized( $user );
}

=haed

Check if the user has enough authorization for modifying

=cut

sub is_authorized {
  my ($self, $user) = @_;

  my $schema     = $self->result_source->schema;
  $user          = $schema->resultset('Users')->find( $user->{id} );
  my $authorized = 0;
  $authorized    = 1 if ( $user->is_admin );
  $authorized    = 1 if ( !$user->is_admin && $self->user_id == $user->id );

  return $authorized;
}

sub get_recent_pages {
  my ($self) = @_;

  return $self->search({
  	status => 'published'
  	},{
  		order_by => {
  			-desc => "created_date"
  		}, rows => 3
	});
}

sub search_published {
  my ( $self, @args ) = @_;

  $args[0]{status} = 'published';
  return $self->search( @args );
}

1;
