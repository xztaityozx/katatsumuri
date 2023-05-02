package Katatsumuri::Result::Package;

use strictures 2;
use Function::Parameters;
use Function::Return;
use Types::Standard -types;
use Mouse;
use PPI::Statement::Package;

has file_name    => (is => 'ro', isa => Str, required => 1);
has package_ast  => (is => 'ro', isa => InstanceOf ['PPI::Statement::Package'], required => 1);

has name => (
    is => 'ro',
    isa => Str,
    required => 1
);

has namespace => (
    is       => 'ro',
    isa      => ArrayRef [Str],
    required => 1
);

has super_classes => (
    is       => 'ro',
    isa      => ArrayRef [Str],
    required => 1
);
has methods => (
    is       => 'ro',
    isa      => ArrayRef [InstanceOf ['Katatsumuri::Result::Method']],
    required => 1
);
has properties => (
    is       => 'ro',
    isa      => ArrayRef [InstanceOf ['Katatsumuri::Result::Property']],
    required => 1
);

no Mouse;
__PACKAGE__->meta->make_immutable;

method TO_JSON ($class :) : Return(HashRef) {
    return +{
        Name         => $class->Name,
        Namespace    => $class->Namespace,
        SuperClasses => $class->SuperClasses,
        Properties   => $class->Properties,
        Methods      => $class->Methods,
    };
};

# JSON文字列を返す
method to_json_string ($class :) : Return(Str) {
    return JSON::XS->new->pretty(1)->convert_blessed(1)->canonical(1)->encode($class);
};

1;
