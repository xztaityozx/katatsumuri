use strictures 2;
use Katatsumuri::Result::Property;

use Test2::Tools::Spec;
use Test2::V0;

describe 'Katatsumuri::Result::Property' => sub {
    describe '->new' => sub {
        it 'should return an instance of Katatsumuri::Result::Property' => sub {
            my $property = Katatsumuri::Result::Property->new(
                name => 'foo',
                type => 'Str',
            );
            ok($property->isa('Katatsumuri::Result::Property'));
        };
    };

    describe 'type' => sub {
        it 'should return the type name' => sub {
            my $property = Katatsumuri::Result::Property->new(
                name => 'foo',
                type => 'Str',
            );
            is($property->type, 'Str');
        };
    };

    describe 'name' => sub {
        it 'should return the name' => sub {
            my $property = Katatsumuri::Result::Property->new(
                name => 'foo',
                type => 'Str',
            );
            is($property->name, 'foo');
        };
    };

    describe 'default' => sub {
        it 'should return the default value' => sub {
            my $property = Katatsumuri::Result::Property->new(
                name => 'foo',
                type => 'Str',
                default => 'bar',
            );
            is($property->default, 'bar');
        };
    };

    describe 'is_readonly' => sub {
        it 'should return the is_readonly value' => sub {
            my $property = Katatsumuri::Result::Property->new(
                name => 'foo',
                type => 'Str',
                is_readonly => 1,
            );
            is($property->is_readonly, 1);
        };

        it 'should return the is_readonly value' => sub {
            my $property = Katatsumuri::Result::Property->new(
                name => 'foo',
                type => 'Str',
                is_readonly => 0,
            );
            is($property->is_readonly, 0);
        };
    };

    describe 'TO_JSON' => sub {
        it 'should return a hashref is_readonly = 0' => sub {
            my $property = Katatsumuri::Result::Property->new(
                name => 'foo',
                type => 'Str',
            );
            my $json = $property->TO_JSON;
            is($json, +{
                Type => 'string',
                Name => 'foo',
                IsReadOnly => \0,
            });
        };

        it 'should return a hashref is_readonly = 1' => sub {
            my $property = Katatsumuri::Result::Property->new(
                name => 'foo',
                type => 'Str',
                is_readonly => 1,
            );
            my $json = $property->TO_JSON;
            is($json, +{
                Type => 'string',
                Name => 'foo',
                IsReadOnly => \1,
            });
        };

        it 'should return a hashref with default' => sub {
            my $property = Katatsumuri::Result::Property->new(
                name => 'foo',
                type => 'Str',
                default => 'bar',
            );
            my $json = $property->TO_JSON;
            is($json, +{
                Type => 'string',
                Name => 'foo',
                Default => 'bar',
                IsReadOnly => \0,
            });
        };
    };
};

done_testing;
