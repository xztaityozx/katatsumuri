package Katatsumuri::Result::Method;
use strictures 2;
use Mouse;
use Katatsumuri::Result;
extends 'Katatsumuri::Result';

use Types::Standard qw( Str HashRef ArrayRef InstanceOf Undef Enum );
use Function::Return;
use Function::Parameters qw( method override );
use Katatsumuri::Result::Method::Argument;
use Katatsumuri::Result::Method::Return;
use JSON::XS ();

has name => (is => 'ro', isa => Str, required => 1);
has arguments =>
  (is => 'ro', isa => ArrayRef [InstanceOf ['Katatsumuri::Result::Method::Argument']] | Undef, required => 1);
has returns =>
  (is => 'ro', isa => ArrayRef [InstanceOf ['Katatsumuri::Result::Method::Return']] | Undef, required => 1);
has declare_type => (is => 'ro', isa => Enum ["fun", "method", "override", "around", "before", "after", "sub", "unknown"], required => 1);

# JSON::XSのためのシリアライザ
override TO_JSON ($class :) : Return(HashRef) {
    return +{ 
        Name => $class->name,
        Arguments => $class->arguments,
        Returns => $class->returns,
        DeclareType => $class->declare_type
    };
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
