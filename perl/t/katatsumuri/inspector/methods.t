use strictures 2;

use Test2::V0;
use Test2::Tools::Spec;
use Test2::Tools::Mock;
use Katatsumuri::Inspector::Methods;

use PPI;

describe 'Katatsumuri::Inspector::Methods' => sub {
    before_all once => sub {
        mock 'Katatsumuri::Inspector::Methods::Arguments' => (
            override => [
                inspect => sub { [] }
            ]
        );

        mock 'Katatsumuri::Inspector::Methods::Returns' => (
            override => [
                inspect => sub { [] }
            ]
        );
    };

    describe '->inspect' => sub {
        it 'should return a arrayref' => sub {
        }
    };
};

done_testing;
