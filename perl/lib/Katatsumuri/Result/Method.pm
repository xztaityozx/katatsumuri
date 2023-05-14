package Katatsumuri::Result::Method;
use strictures 2;
use Types::Standard qw( Str HashRef ArrayRef InstanceOf Undef Enum Dict Maybe );
use Type::Utils -all;
use Type::Library -base, -declare => qw(MethodSchema DeclareType);
use Function::Return;
use Function::Parameters;

type MethodSchema,
  as Dict [
    name         => Str,
    arguments    => ArrayRef [HashRef],
    returns      => Enum ["void"] | HashRef,
    declare_type => DeclareType,
  ];
type DeclareType, as Enum ["fun", "method", "override", "around", "before", "after", "sub", "unknown"];

use Moo;

has name => (is => 'ro', isa => Str, required => 1);
has arguments => (
    is       => 'ro',
    isa      => ArrayRef [InstanceOf ['Katatsumuri::Result::Method::Argument']] | Undef,
    required => 1
);
has returns => (is => 'ro', isa => InstanceOf ['Katatsumuri::Type'] | Undef, required => 1);
has declare_type => (is => 'ro', isa => DeclareType, required => 1);

# to_schema は、このメソッドのスキーマを作って返す。
# schemaって言ってるけど独自定義。JSON Schemaではない。
# でも型を表す部分だけJSON Schemaに準拠してる。
method to_schema ($class :) : Return(MethodSchema) {
    return +{
          returns => Undef->check($class->returns) ? 'void'
        : Undef->check($class->returns->default) ? $class->returns->to_json_schema
        : +{ const => $class->returns->default },
        declare_type => $class->declare_type,
        name         => $class->name,
        arguments    => Undef->check($class->arguments) ? [] : [map { $_->to_schema() } @{ $class->arguments }]
    };
}

1;
