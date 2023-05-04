use strictures 2;
use Katatsumuri::Result::Package;

use Test2::V0;
use Test2::Tools::Spec;
use JSON::XS qw/decode_json/;

describe 'Katatsumuri::Result::Package' => sub {
    describe 'new' => sub {
        it 'should return instance' => sub {
            my $result = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            );
            ok $result;
            isa_ok $result, 'Katatsumuri::Result::Package';
        };
    };

    describe 'name' => sub {
        it 'should return name' => sub {
            my $result = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            );
            is $result->name, 'Name';
        };
    };

    describe 'namespace' => sub {
        it 'should return namespace' => sub {
            my $result = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            );
            is $result->namespace, ['Test', 'Namespace'];
        };
    };

    describe 'super_classes' => sub {
        it 'should return super_classes' => sub {
            my $result = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            );
            is $result->super_classes, ['Test::Super', 'Test::Super2'];
        };
    };

    describe 'methods' => sub {
        it 'should return methods' => sub {
            my $result = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            );
            is $result->methods, [];
        };
    };

    describe 'properties' => sub {
        it 'should return properties' => sub {
            my $result = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            );
            is $result->properties, [];
        };
    };

    describe 'file_name' => sub {
        it 'should return file_name' => sub {
            my $result = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            );
            is $result->file_name, 'test.pm';
        };
    };

    describe 'TO_JSON' => sub {
        it 'should return hashref' => sub {
            my $json = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            )->TO_JSON;

            is $json,
              +{
                Name         => 'Name',
                Namespace    => ['Test',        'Namespace'],
                SuperClasses => ['Test::Super', 'Test::Super2'],
                Methods      => [],
                Properties   => [],
               };
        }
    };

    describe 'full_name' => sub {
        it 'should return full name' => sub {
            my $result = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            );
            is $result->full_name, 'Test::Namespace::Name';
        };
    };

    describe 'to_json_string' => sub {
        it 'should return json string' => sub {
            my $json = Katatsumuri::Result::Package->new(
                name          => 'Name',
                namespace     => ['Test',        'Namespace'],
                super_classes => ['Test::Super', 'Test::Super2'],
                methods       => [],
                properties    => [],
                file_name     => 'test.pm',
            )->to_json_string;

            my $got = decode_json $json;
            is $got,
              +{
                Name         => 'Name',
                Namespace    => ['Test',        'Namespace'],
                SuperClasses => ['Test::Super', 'Test::Super2'],
                Methods      => [],
                Properties   => [],
               };
        }
    }
};

done_testing;
