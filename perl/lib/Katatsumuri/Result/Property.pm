package Katatsumuri::Result::Property;
use strictures 2;
use Mouse;
use Types::Standard qw( Str Bool Any HashRef );
use Function::Return;
use Function::Parameters qw( method );
use JSON::XS             ();

has Type       => ( is => 'ro', isa => Str,  required => 1 );
has Name       => ( is => 'ro', isa => Str,  required => 1 );
has Default    => ( is => 'rw', isa => Any,  required => 0 );
has IsReadOnly => ( is => 'ro', isa => Bool, required => 0 );

no Mouse;
__PACKAGE__->meta->make_immutable;

method TO_JSON ( $class : ) : Return(HashRef) {
  return +{
    Type => $class->Type,
    Name => $class->Name,

    # 1/0だと普通に数値が出力される。\1/\0 とすれば true/false に変換してくれる。
    IsReadOnly => $class->IsReadOnly ? \1 : \0,
    Type       => $class->Type,
    ( defined( $class->Default ) ? ( Default => $class->Default ) : () ),
  };
};

1;

