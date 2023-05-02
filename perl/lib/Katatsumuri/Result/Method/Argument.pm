package Katatsumuri::Result::Method::Argument;
use Mouse;
use Types::Standard      qw( Str HashRef );
use Function::Parameters qw(method);
use Function::Return;

has Name => (is => 'ro', isa => Str, required => 1);
has Type => (is => 'ro', isa => Str, required => 1);

no Mouse;
__PACKAGE__->meta->make_immutable;

method TO_JSON ($class :) : Return(HashRef) {
    return +{
        Name => $class->Name,
        Type => $class->Type,
    };
}

1;
