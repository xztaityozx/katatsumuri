use strictures 2;

use Katatsumuri::Inspector::Package;
use Types::Standard;
use Katatsumuri::Result::Package;

use Test2::V0;
use Test2::Tools::Spec;
use Test2::Tools::Mock;

describe 'Katatsumuri::Inspector::Package' => sub {
    describe '->inspect' => sub {
        before_all once => sub {
            mock 'Katatsumuri::Inspector::Methods' => (
                override => [
                    inspect => sub { [] },
                ]
            );

            mock 'Katatsumuri::Inspector::Properties' => (
                override => [
                    inspect => sub { [] },
                ],
            );
        };

        it 'should return Katatsumuri::Result::Package' => sub {
            my $pkg_text = 'package Foo;1;';
            my $result = Katatsumuri::Inspector::Package->inspect(\$pkg_text);

            ok $result;
            ref_ok $result, 'ARRAY';
            isa_ok $result->[0], 'Katatsumuri::Result::Package';
            is $result->[0]->name, 'Foo';
            is $result->[0]->namespace, [];
            is $result->[0]->super_classes, [];
        };
    };
};

done_testing;
