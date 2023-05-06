package My::Namespace::B;
use strictures 2;
use Function::Parameters;
use Function::Return;
use Types::Standard -types;
use Data::Validator;

use Mouse;

has name => (is => 'ro', isa => Str, default => 'this is name');
has age => (is => 'ro', isa => Int, required => 1);
has union => (is => 'ro', isa => Str|Int, required => 1);

no Mouse;
__PACKAGE__->meta->make_immutable;

sub a {
    return 10;
}

fun b() :Return(Int) {
    return 10;
};

method c() :Return(Int) {
    return 10;
};

method d(Str $str, $x, Int $y //= 1) {
    return 10;
};

sub e {
    my $rule = Data::Validator->new(
        str => { isa => Str },
        x => { isa => Any },
        y => { isa => Int, default => 1 },
    );

    $rule->validate(@_);

    return 10;
}

sub f :Return(Str, Int) {
    my ($self, $str, $x, $y) = @_;

    return [$str, $x+$y];
}

1;
