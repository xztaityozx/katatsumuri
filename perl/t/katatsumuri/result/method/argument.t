use strictures 2;

use Katatsumuri::Result::Method::Argument;

use Test2::V0;
use Test2::Tools::Spec;

describe 'Katatsumuri::Result::Method::Argument' => sub {
    describe 'new' => sub {
        it 'should return an instance of Katatsumuri::Result::Method::Argument' => sub {
            my $result = Katatsumuri::Result::Method::Argument->new(
                name     => 'foo',
                type     => 'Int',
                required => 1,
            );
            ok $result->isa('Katatsumuri::Result::Method::Argument');
        };
    };

    describe 'name' => sub {
        it 'should return the name of the argument' => sub {
            my $result = Katatsumuri::Result::Method::Argument->new(
                name     => 'foo',
                type     => 'Int',
                required => 1,
            );
            is $result->name, 'foo';
        };
    };

    describe 'type' => sub {
        it 'should return the type of the argument' => sub {
            my $result = Katatsumuri::Result::Method::Argument->new(
                name     => 'foo',
                type     => 'Int',
                required => 1,
            );
            is $result->type, 'Int';
        };

        it 'should return the type of the argument' => sub {
            my $result = Katatsumuri::Result::Method::Argument->new(
                name     => 'foo',
                type     => +{ array => 'any' },
                required => 1,
            );
            is $result->type, +{ array => 'any' };
        };
    };

    describe 'default' => sub {
        it 'should return the default value of the argument' => sub {
            my $result = Katatsumuri::Result::Method::Argument->new(
                name     => 'foo',
                type     => 'Int',
                default  => 42,
                required => 1,
            );
            is $result->default, 42;
        };
        it 'should return undef if the argument has no default value' => sub {
            my $result = Katatsumuri::Result::Method::Argument->new(
                name     => 'foo',
                type     => 'Int',
                required => 1,
            );
            ok !$result->default;
        };
    };

    describe 'TO_JSON' => sub {
        it 'should return a hashref' => sub {
            my $result = Katatsumuri::Result::Method::Argument->new(
                name     => 'foo',
                type     => 'Int',
                required => 1,
            );
            is($result->TO_JSON, +{ Name => 'foo', Type => 'integer', Required => \1 });
        };

        it 'should return a hashref with a default value' => sub {
            my $result = Katatsumuri::Result::Method::Argument->new(
                name     => 'foo',
                type     => 'Int',
                default  => 42,
                required => 1,
            );
            is($result->TO_JSON, +{ Name => 'foo', Type => 'integer', Required => \1, Default => 42 });
        };
    };
};

done_testing;
