use utf8;
package PearlBee::Model::Schema::Result::RegistrationToken;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PearlBee::Model::Schema::Result::RegistrationToken

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::EncodedColumn>

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("EncodedColumn", "InflateColumn::DateTime");

=head1 TABLE: C<registration_token>

=cut

__PACKAGE__->table("registration_token");

=head1 ACCESSORS

=head2 token

  data_type: 'text'
  is_nullable: 0

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0

=head2 voided_at

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 reason

  data_type: 'enum'
  default_value: 'verify-email-address'
  extra: {custom_type_name => "registration_token_reason",list => ["verify-email-address","reset-password"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "token",
  { data_type => "text", is_nullable => 0 },
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "voided_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "reason",
  {
    data_type => "enum",
    default_value => "verify-email-address",
    extra => {
      custom_type_name => "registration_token_reason",
      list => ["verify-email-address", "reset-password"],
    },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</token>

=back

=cut

__PACKAGE__->set_primary_key("token");

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<PearlBee::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "PearlBee::Model::Schema::Result::User",
  { id => "user" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-01-02 14:28:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hM2xEgFgssZ03TIGBz4p/w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
