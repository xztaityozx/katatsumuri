package Katatsumuri::Result::Method::Argument;
use strictures 2;
use Types::Standard qw( Str HashRef Any Undef Bool InstanceOf );
use Moo;
use Function::Parameters;
use Function::Return;

has name     => (is => 'ro', isa => Str, required => 1);
has type     => (is => 'ro', isa => InstanceOf['Katatsumuri::Type'], required => 1);
has required => (is => 'ro', isa => Bool, required => 1);

method to_schema ($class :) : Return(HashRef) {
    return +{
        name     => $class->name,
        type     => $class->type->to_json_schema(),
        required => $class->required
    };
}

1;
