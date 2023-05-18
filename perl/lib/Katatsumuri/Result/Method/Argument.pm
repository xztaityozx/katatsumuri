package Katatsumuri::Result::Method::Argument;
use strictures 2;
use Types::Standard qw( Str HashRef Any Undef Bool InstanceOf Dict ScalarRef );
use Moo;
use Function::Parameters;
use Function::Return;

has name     => (is => 'ro', isa => Str, required => 1);
has type     => (is => 'ro', isa => InstanceOf['Katatsumuri::Type'], required => 1);
has required => (is => 'ro', isa => Bool, required => 1);

method to_schema ($class :) : Return(Dict[name => Str, type => HashRef, required => ScalarRef]) {
    return +{
        name     => $class->name,
        type     => $class->type->to_json_schema(),
        required => $class->required ? \1 : \0
    };
}

1;
