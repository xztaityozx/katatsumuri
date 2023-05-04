use strictures 2;
use Katatsumuri::Result::Method::Return;

use Test2::V0;
use Test2::Tools::Spec;

describe 'Katatsumuri::Result::Method::Return' => sub {
    describe 'new' => sub {
        it 'should return Katatsumuri::Result::Method::Return object' => sub {
            my $return = Katatsumuri::Result::Method::Return->new(type => 'Str');
            ok($return->isa('Katatsumuri::Result::Method::Return'));
        };
    };

    describe 'type' => sub {
        it 'should return type' => sub {
            my $return = Katatsumuri::Result::Method::Return->new(type => 'Str');
            is($return->type, 'Str');
        };
    };

    describe 'value' => sub {
        it 'should return value' => sub {
            my $return = Katatsumuri::Result::Method::Return->new(type => 'Str', value => 'hoge');
            is($return->value, 'hoge');
        };

        it 'should return undef' => sub {
            my $return = Katatsumuri::Result::Method::Return->new(type => 'Str');
            is($return->value, undef);
        };

        it 'should return hashref' => sub {
            my $return = Katatsumuri::Result::Method::Return->new(type => 'Str', value => { hoge => 'fuga' });
            is($return->value, +{ hoge => 'fuga' });
        };
    };

    describe 'TO_JSON' => sub {
        it 'should return hashref' => sub {
            my $return = Katatsumuri::Result::Method::Return->new(type => 'Str', value => 'hoge');
            my $json = $return->TO_JSON;
            is($json->{Type},  'string');
            is($json->{Value}, 'hoge');
        };

        it 'valueがないときはキーもないべき' => sub {
            my $return = Katatsumuri::Result::Method::Return->new(type => 'Str');
            my $json = $return->TO_JSON;
            is($json->{Type},  'string');
            ok(!exists($json->{Value}));
        };
    };
};

done_testing;
