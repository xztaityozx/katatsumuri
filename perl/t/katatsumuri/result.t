use strictures 2;

use Katatsumuri::Result;

use Test2::V0;
use Test2::Tools::Spec;

describe 'Katatsumuri::Result' => sub {

    describe 'normalize_type_name' => sub {
        it 'Int to integer' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('Int');
            is $got, 'integer';
        };
        it 'Str to string' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('Str');
            is $got, 'string';
        };
        it 'ArrayRef to array' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('ArrayRef');
            is $got, 'array';
        };
        it 'Object to object' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('Object');
            is $got, 'object';
        };
        it 'HashRef to object' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('HashRef');
            is $got, 'object';
        };
        it 'Any to any' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('Any');
            is $got, 'any';
        };
        it 'Bool to boolean' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('Bool');
            is $got, 'boolean';
        };
        it 'Hash to object' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('Hash');
            is $got, 'object';
        };
        it 'HASH to object' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('HASH');
            is $got, 'object';
        };
        it 'ARRAY to array' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('ARRAY');
            is $got, 'array';
        };
        it 'Array to array' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('Array');
            is $got, 'array';
        };
        it 'Void to void' => sub {
            my $got = Katatsumuri::Result->normalize_type_name('Void');
            is $got, 'void';
        };
    }
};

done_testing;
