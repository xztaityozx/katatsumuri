package Katatsumuri::Result::Package;

use strictures 2;
use Function::Parameters;
use Function::Return;
use Types::Standard -types;
use Type::Utils -all;
use Type::Library -base, -declare => qw(ObjectSchemaType);

type ObjectSchemaType,
  as Dict [
    name          => Str,
    namespace     => ArrayRef [Str],
    super_classes => ArrayRef [Str],
    methods       => ArrayRef [HashRef],
    schema        => Dict [
        '$schema'  => Str,
        type       => Enum["object"],
        properties => Maybe [Map [Str, HashRef]],
        required   => ArrayRef [Str],
    ]
  ];

use Moo;
use JSON::XS ();

has file_name => (is => 'ro', isa => Str | ScalarRef, required => 1);

has name => (
    is       => 'ro',
    isa      => Str,
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

method full_name ($class :) : Return(Str) {
    return join('::', @{ $class->namespace }, $class->name);
}

method to_json_schema ($class :) : Return(ObjectSchemaType) {

    my %properties = map { $_->name => $_->type->to_json_schema } @{$class->properties};

    return +{
        name          => $class->name,
        namespace     => $class->namespace,
        super_classes => $class->super_classes,
        schema        => +{
            '$schema'  => 'https://json-schema.org/draft/2020-12/schema',
            type       => 'object',
            required   => [map { $_->name } grep { $_->required } @{ $class->properties }],
            properties => \%properties,
        },
        methods => [map{ $_->to_schema } @{$class->methods}],
    };
}

1;
