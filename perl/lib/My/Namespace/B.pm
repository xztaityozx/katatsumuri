package My::Namespace::B;
use strictures 2;
use Function::Parameters;
use Function::Return;
use Types::Standard -types;

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
}

1;
