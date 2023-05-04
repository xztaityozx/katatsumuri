use strictures 2;

use Katatsumuri::Result::Method;
use Test2::V0;
use Test2::Tools::Spec;

describe 'Katatsumuri::Result::Method' => sub {
    describe 'new' => sub {
        it 'should return Katatsumuri::Result::Method object' => sub {
            my $method = Katatsumuri::Result::Method->new(
                name         => 'foo',
                arguments    => [],
                returns      => [],
                declare_type => 'sub',
            );
            ok $method;
            isa_ok $method, 'Katatsumuri::Result::Method';
        };
    };

    describe 'name' => sub {
        it 'should return method name' => sub {
            my $method = Katatsumuri::Result::Method->new(
                name         => 'foo',
                arguments    => undef,
                returns      => undef,
                declare_type => 'sub',
            );
            is $method->name, 'foo';
        };
    };

    describe arguments => sub {
        it 'should return method arguments' => sub {
            my $method = Katatsumuri::Result::Method->new(
                name         => 'foo',
                arguments    => [],
                returns      => undef,
                declare_type => 'sub',
            );
            is $method->arguments, [];
        };

        it 'should return method arguments' => sub {
            my $method = Katatsumuri::Result::Method->new(
                name         => 'foo',
                arguments    => undef,
                returns      => undef,
                declare_type => 'sub',
            );
            ok !$method->arguments;
        };
    };
    describe returns => sub {
        it 'should return method returns' => sub {
            my $method = Katatsumuri::Result::Method->new(
                name         => 'foo',
                arguments    => undef,
                returns      => [],
                declare_type => 'sub',
            );
            is $method->returns, [];
        };

        it 'should return method returns' => sub {
            my $method = Katatsumuri::Result::Method->new(
                name         => 'foo',
                arguments    => undef,
                returns      => undef,
                declare_type => 'sub',
            );
            ok !$method->returns;
        };
    };

    describe declare_type => sub {
        it 'should return method declare_type' => sub {
            my $method = Katatsumuri::Result::Method->new(
                name         => 'foo',
                arguments    => undef,
                returns      => undef,
                declare_type => 'sub',
            );
            is $method->declare_type, 'sub';
        };
    };

    describe 'TO_JSON' => sub {
        it 'should return hashref' => sub {
            my $got = Katatsumuri::Result::Method->new(
                name         => 'foo',
                arguments    => [],
                returns      => [],
                declare_type => 'sub',
            )->TO_JSON;

            is $got,
              +{
                Name        => 'foo',
                Arguments   => [],
                Returns     => [],
                DeclareType => 'sub',
               };
        };
    };
};

done_testing;
