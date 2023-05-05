package Katatsumuri::Result::Property;
use strictures 2;
use Mouse;
use Types::Standard qw( Str Bool Any HashRef InstanceOf );
use Function::Return;
use Function::Parameters qw( method override );
use Katatsumuri::Result;
extends 'Katatsumuri::Result';

has type       => ( is => 'ro', isa => InstanceOf['Type::Tiny'],  required => 1 );
has name       => ( is => 'ro', isa => Str,  required => 1 );
has default    => ( is => 'rw', isa => Any,  required => 0 );
has is_readonly => ( is => 'ro', isa => Bool, required => 0 );

override TO_JSON ( $class : ) : Return(HashRef) {
  my $hash = +{
    Type => $class->normalize_type( $class->type ),
    Name => $class->name,

    # 1/0だと普通に数値が出力される。\1/\0 とすれば true/false に変換してくれる。
    IsReadOnly => $class->is_readonly ? \1 : \0,
  };
  if ( defined $class->default ) {
    $hash->{Default} = $class->default;
  }
  return $hash;
};

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

