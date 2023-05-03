package My::Namespace::User {
    use strictures 2;
    use Mouse;
    use Function::Parameters qw(:std :modifiers);
    use Function::Return;
    use Types::Standard qw( Str Int ArrayRef);
    extends 'My::Namespace::Person', 'My::Namespace::A';

    has 'id' => (is => 'rw', isa => 'Int', default => 1);

    sub hoge {
        return;
    }

    around t() {
        return;
    }

    no Mouse;
    __PACKAGE__->meta->make_immutable;

    sub full_name {
        return "ABC";
    }

    fun static_function(Str $str, Int $int) :Return(Str) {
        return "this is function";
    };

    method user_method(Str $str, Int $int) {
        return;
    };

    sub a() :Return(Str, Int) {
        return "abc", 123;
    }

    sub add {
        my ($self, $a, $b) = @_;
        return $a + $b;
    }

    sub minus {
        my ($self, $a, $b, $c) = (shift, shift, shift, 1);
        return $a - $b;
    }

    sub multi {
        my $self = shift;
        my $a = shift;
        my $b = shift;
        my $c = 1;
        return $a * $b;
    }

    sub array {
        my @this = shift;
        return "a";
    }

    sub z {
        my @this = (shift, shift, shift);
        return "a";
    }
    
    sub x1 {
        my @this = (shift, shift, 1);
        return "a";
    }
    
    sub x2 {
        my $this = (shift, shift, 1);
        return "a";
    }

    #classmethod user_classmethod() :Return(ArrayRef[Int]) {
        #return [1];
    #};

    #around user_around() :Return() {
        #return;
    #};
};

package My::Namespace::Person {
    use strictures 2;
    use Mouse;
    use Mouse::Util::TypeConstraints;

    has 'first_name' => (
        is      => 'rw',
        isa     => 'Str',
        default => 'Alice',
    );

    has 'last_name' => (
        is  => 'rw',
        isa => 'Str',
    );

    has 'age' => (
        is      => 'ro',
        isa     => 'Int',
        default => 18,
    );

    sub full_name {
        my $self = shift;
        return $self->first_name . ' ' . $self->last_name;
    }

    sub hash_ref {
        return +{ a => 'b' };
    }

    sub list {
        return [ 1, 2, 3 ];
    }

    sub k {
        return ['a', 'b', 'c'];
    }

    sub no_semicolon {
        return "a"
    }

    sub no_a {
        return 
    }

    sub c {
        return -1;
    }

    sub d {
        return +1;
    }

    sub e {
        return [];
    }

    sub f {
        return [[1,2], [3], [4,5,6]];
    }

    no Mouse;
    __PACKAGE__->meta->make_immutable;
};

package My::Namespace::A {
    use Mouse;
    use Data::Validator;
    use Types::Standard qw(Int);

    sub t {
        return;
    }

    sub data_validator {
        my $type = 'Int';
        my $v; $v //= Data::Validator->new(
            str => { isa => 'Str' },
            int => { isa => 'Int', default => 1 },
            int2 => { isa => 'Int', optional => 1 },
            int3 => { isa => 'Int', optional => 1, default => 3 },
            int4 => { isa => 'Int', optional => 0 },
            k => 'Int',
            unknown => { isa => $type },
            type_tiny_int => Int,
            symbol => $type,
            expression => $type->type,
            sub_given_for_default => +{isa => Int, default => sub { return 1 }},
        )->with(qw/Method/);

        return;
    }

    no Mouse;
    __PACKAGE__->meta->make_immutable;
};

use strictures 2;
use Function::Parameters;
use My::Namespace::User;
use Katatsumuri::Inspector::Package;

use DDP;

my $result = Katatsumuri::Inspector::Package->inspect('./main.pl');

foreach my $package (@$result) {
    print $package->to_json_string;
}
