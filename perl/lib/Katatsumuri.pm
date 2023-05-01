package Katatsumuri;

use strictures 2;
use Function::Return;
use Function::Parameters;
use Types::Standard -base;
use Katatsumuri::Result;
use Katatsumuri::Result::Property;
use Katatsumuri::Result::Method;
use Mouse::Util;
use Carp;
use Mouse;

has class_name => ( is => 'ro', isa => Str, required => 1 );

no Mouse;
__PACKAGE__->meta->make_immutable;

method _get_superclasses ( $class : ) : Return(ArrayRef[Str]) {
  no strict 'refs';
  my @superclasses = @{ $class->class_name . '::ISA' };
  use strict 'refs';
  return \@superclasses;
}

method _get_properties ( $class : ) : Return(ArrayRef[InstanceOf['Katatsumuri::Result::Property']]) {
  my $meta = Mouse::Util::get_metaclass_by_name( $class->class_name );
  if ( defined($meta) && $meta->isa('Mouse::Meta::Class') ) {

    # MouseからMouse::Meta::Classがえられたっぽいのでそこから必要な情報をぶっこぬく
    my @result;
    for my $attr ( $meta->get_all_attributes ) {
      next if not $attr->associated_class->name eq $meta->name;
      push @result, Katatsumuri::Result::Property->new(
        Type => $attr->type_constraint->name,
        Name => $attr->name,
        ( $attr->has_default ? ( Default => $attr->default ) : () ),

        # is_readonlyみたいなアクセサーがあればよかったけどないので直接値を見ている
        IsReadOnly => $attr->{is} eq 'ro' ? 1 : 0
      );
    }

    return \@result;
  }
  else {
    # こっちはMouseじゃなかったとき。まだ実装してない
    carp('Property information enumeration is not supported for non-Mouse types');
    return [];
  }
}

method _get_methods ( $class : ) : Return(ArrayRef[InstanceOf['Katatsumuri::Result::Method']]) {
  my $meta = Mouse::Util::get_metaclass_by_name( $class->class_name );
  if ( defined($meta) && $meta->isa('Mouse::Meta::Class') ) {
    my @result;
    for my $method_name ( $meta->get_method_list ) {
      push @result, Katatsumuri::Result::Method->new( Name => $method_name );
    }

    return \@result;
  }
  else {
    # こっちはMouseじゃなかったとき。まだ実装してない
    carp('Property information enumeration is not supported for non-Mouse types');
    return [];
  }
}

method get_type_info ( $class : ) : Return(InstanceOf['Katatsumuri::Result']) {
  my @array_of_type_name = split( /::/x, $class->class_name );
  my $type_name = pop @array_of_type_name;
  return Katatsumuri::Result->new(
    Name         => $type_name,
    Namespace    => \@array_of_type_name,
    SuperClasses => $class->_get_superclasses(),
    Methods      => $class->_get_methods(),
    Properties   => $class->_get_properties()
  );
}

method create ( $class : ClassName | Str $class_name) : Return(InstanceOf['Katatsumuri']) {
  return $class->new( class_name => $class_name );
}

1;