package Katatsumuri::Result::Method;
use strictures 2;
use Mouse;
use Types::Standard qw( Str HashRef ArrayRef InstanceOf Undef );
use Function::Return;
use Function::Parameters qw( method );
use Katatsumuri::Result::Method::Argument;
use JSON::XS ();

has name => (is => 'ro', isa => Str, required => 1);
has arguments => (is => 'ro', isa => ArrayRef [InstanceOf ['Katatsumuri::Result::Method::Argument']] | Undef, required => 1);

no Mouse;
__PACKAGE__->meta->make_immutable;

# JSON::XSのためのシリアライザ
method TO_JSON ($class :) : Return(HashRef) {
    return +{ Name => $class->name, Arguments => $class->arguments };
}

1;
