package Katatsumuri::Result::Method::Argument;
use strictures 2;
use Types::Standard      qw( Str HashRef Any Undef Bool );
use Function::Return;
use Function::Parameters qw(method override);

use Mouse;
use Katatsumuri::Result;
extends 'Katatsumuri::Result';

has name => (is => 'ro', isa => Str, required => 1);
has type => (is => 'ro', isa => Str|HashRef, required => 1);
has default => (is => 'ro', isa => Any|Undef );
has required => (is => 'ro', isa => Bool, required => 1 );

override TO_JSON ($class :) : Return(HashRef) {
    my $type = $class->type;
    if(ref($type) eq 'HASH') {
        if(exists($type->{type})) {
            $type->{type} = $class->normalize_type_name($type->{type});
        }
    } else {
        $type = $class->normalize_type_name($type);
    }

    my $hash = +{
        Name => $class->name,
        Type => $type,
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
