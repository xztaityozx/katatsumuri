package Katatsumuri::Result::Package;

use strictures 2;
use Function::Parameters qw(:std :modifiers);
use Function::Return;
use Types::Standard -types;
use Katatsumuri::Result;

use Mouse;
use JSON::XS ();
extends 'Katatsumuri::Result';

has file_name    => (is => 'ro', isa => Str|ScalarRef, required => 1);

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

override TO_JSON ($class :) : Return(HashRef) {
    return +{
        Name         => $class->name,
        Namespace    => $class->namespace,
        SuperClasses => $class->super_classes,
        Properties   => $class->properties,
        Methods      => $class->methods,
    };
};

no Mouse;
__PACKAGE__->meta->make_immutable;

method full_name ($class :) : Return(Str) {
    return join('::', @{$class->namespace}, $class->name);
};

# JSON文字列を返す
method to_json_string ($class :) : Return(Str) {
    return JSON::XS->new->pretty(1)->convert_blessed(1)->canonical(1)->encode($class);
};

1;
