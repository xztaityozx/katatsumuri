package Katatsumuri::Result;

use strictures 2;
use Function::Return;
use Function::Parameters;
use Types::Standard -types;
use Carp qw(croak);

use List::Util qw(uniq);

use Type::Utils -all;
use Type::Library -base, -declare => qw( TypeTiny Parameters );
type 'TypeTiny',   as InstanceOf ['Type::Tiny'];
type 'Parameters', as ArrayRef [InstanceOf [TypeTiny]];

method TO_JSON ($class :) : Return(HashRef) {
    croak('Not implemented');
}

my $integer_synonym = ['Int', 'integer'];
my $string_synonym = ['Str', 'string'];
my $object_synonym = ['Object', 'object', 'HashRef', 'Hash', 'HASH'];
my $array_synonym = ['ArrayRef', 'array', 'Array', 'ARRAY'];
my $void_synonym = ['Void', 'void'];
my $any_synonym = ['Any', 'any'];
my $bool_synonym = ['Bool', 'bool', 'boolean'];

method _convert_type_tiny ($class : TypeTiny $type_tiny) : Return(HashRef) {
    if ($type_tiny->is_anon) {
        if ($type_tiny->is_parameterized) {
            my $parent_type = $type_tiny->parent;
            if (!$parent_type) {
                return +{ Type => 'any' };
            }

            if ($parent_type->name eq 'HashRef') {
                return +{ Type => 'object', };
            }

            my $type =+{};
            if ($parent_type->name eq 'ArrayRef') {
                $type = +{ Type => 'array' };
            }

            if ($parent_type->name eq 'Maybe') {
                $type = +{ Type => 'maybe' };
            }

            my $subtype = $class->_get_subtype($type_tiny->parameters);

            return +{ %{$type}, %{$subtype} };
        }
        else {
            return +{ Type => 'any' };
        }
    }

    return +{ Type => $class->_convert($type_tiny->name) };
}

method _get_subtype ($class : Parameters $parameters) : Return(HashRef) {
    if (scalar(@$parameters) == 1) {
        my $param = $parameters->[0];
        return +{ SubType => $param->name ? $class->_convert($param->name) : 'any' };
    }
    else {
        return +{ Union => [uniq(map { $_->name ? $class->_convert($_->name) : 'any' } @{$parameters})] };
    }
}

method _convert (Str $type_name) : Return(Str) {
    if (grep { $type_name eq $_ } @{$integer_synonym}) {
        return 'integer';
    }
    if (grep { $type_name eq $_ } @{$string_synonym}) {
        return 'string';
    }
    if (grep { $type_name eq $_ } @{$object_synonym}) {
        return 'object';
    }
    if (grep { $type_name eq $_ } @{$array_synonym}) {
        return 'array';
    }
    if (grep { $type_name eq $_ } @{$void_synonym}) {
        return 'void';
    }
    if (grep { $type_name eq $_ } @{$any_synonym}) {
        return 'any';
    }
    if (grep { $type_name eq $_ } @{$bool_synonym}) {
        return 'boolean';
    }
    return $type_name;
}

# normalize_type は型の表記ゆれをなおして返す
method normalize_type (Str | HashRef | TypeTiny $type_name) : Return(HashRef) {
    if(ref($type_name) eq 'HASH') {
        if(exists($type_name->{type})) {
            return +{Type =>  $self->_convert($type_name->{type})};
        } elsif(exists($type_name->{array})) {
            return +{
                Type => 'array',
                SubType => $self->_convert($type_name->{array})
            };
        }
    } elsif (ref($type_name) eq 'Type::Tiny') {
        return $self->_convert_type_tiny($type_name);
    } else {
        return +{ Type => $self->_convert($type_name) };
    }
}

1;
