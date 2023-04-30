package My::Namespace::Parent {
    use Mouse;

    sub PARENT {
        return 2;
    }

    no Mouse;
    __PACKAGE__->meta->make_immutable;
};

package My::Namespace::User {
    use Mouse;
    extends 'My::Namespace::Person', 'My::Namespace::A';

    has 'id' => (is => 'rw', isa => 'Int', default => 1);

    sub hoge {
        return 1;
    }
    no Mouse;
    __PACKAGE__->meta->make_immutable;
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

    no Mouse;
    __PACKAGE__->meta->make_immutable;
};

package My::Namespace::A {
    use Mouse;

    no Mouse;
    __PACKAGE__->meta->make_immutable;
};


use strictures 2;
use JSON::XS;

use My::Namespace::User;
use My::Namespace::B;
use DDP;
use Katatsumuri;

my $katatsumuri = Katatsumuri->create('My::Namespace::User');
my $result = $katatsumuri->get_type_info();

print $result->to_json_string;

