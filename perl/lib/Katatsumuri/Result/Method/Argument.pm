package Katatsumuri::Result::Method::Argument;
use strictures 2;
use Types::Standard      qw( Str HashRef Any Undef Bool InstanceOf );
use Function::Return;
use Function::Parameters qw(method override);

use Mouse;
use Katatsumuri::Result;
extends 'Katatsumuri::Result';

has name => (is => 'ro', isa => Str, required => 1);
has type => (is => 'ro', isa => Str|HashRef|InstanceOf['Type::Tiny'], required => 1);
has default => (is => 'ro', isa => Any|Undef );
has required => (is => 'ro', isa => Bool, required => 1 );

override TO_JSON ($class :) : Return(HashRef) {
    my $hash = +{
        Name => $class->name,
        Type => $class->normalize_type($class->type),
        Required => $class->required ? \1 : \0,
    };
    if(defined($class->default)) {
        $hash->{Default} = $class->default;
    }

    return $hash;
};

no Mouse;
__PACKAGE__->meta->make_immutable;


1;
