package Katatsumuri::Result::Method::Return;

use strictures 2;
use Function::Return;
use Function::Parameters qw(method override);
use Types::Standard -types;

use Mouse;
use Katatsumuri::Result;
extends 'Katatsumuri::Result';

has type => (
    is       => 'ro',
    isa      => Str | HashRef,
    required => 1
);
has value => (is => 'ro', isa => Any | HashRef | Undef, default => sub { return undef });

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
        Type => $type
    };

    if(defined($class->value)) {
        $hash->{Value} = $class->value;
    }

    return $hash;
};

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
