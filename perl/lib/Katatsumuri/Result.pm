package Katatsumuri::Result;

use strictures 2;
use Function::Return;
use Function::Parameters;
use Types::Standard -types;
use Carp qw(croak);

method TO_JSON ($class :) : Return(HashRef) {
    croak('Not implemented');
}

my $integer_synonym = ['Int', 'integer'];
my $string_synonym = ['Str', 'string'];
my $object_synonym = ['Object', 'object'];
my $array_synonym = ['ArrayRef', 'array', 'Array'];
my $void_synonym = ['Void', 'void'];

# normalize_type_name は型の表記ゆれをなおして返す
method normalize_type_name (Str | ClassName $type_name) : Return(Str) {
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
    return $type_name;
}

1;