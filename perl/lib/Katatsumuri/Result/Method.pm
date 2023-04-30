package Katatsumuri::Result::Method;
use strictures 2;
use Mouse;
use Types::Standard qw( Str HashRef );
use Function::Return;
use Function::Parameters qw( method );
use JSON::XS             ();

has Name => ( is => 'ro', isa => Str, required => 1 );

no Mouse;
__PACKAGE__->meta->make_immutable;

method TO_JSON ( $class : ) : Return(HashRef) {
  return +{ Name => $class->Name };
}

1;
