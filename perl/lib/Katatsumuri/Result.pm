package Katatsumuri::Result;
use strictures 2;
use JSON::XS;
use Mouse;
use Types::Standard qw( Str ArrayRef HashRef InstanceOf );
use Katatsumuri::Result::Method;
use Katatsumuri::Result::Property;
use Function::Return;
use Function::Parameters qw/ method /;

has Name => (
  is       => 'ro',
  isa      => Str,
  required => 1
);
has Namespace => (
  is       => 'ro',
  isa      => ArrayRef [Str],
  required => 1
);
has SuperClasses => (
  is       => 'ro',
  isa      => ArrayRef [Str],
  required => 1
);
has Methods => (
  is       => 'ro',
  isa      => ArrayRef [ InstanceOf ['Katatsumuri::Result::Method'] ],
  required => 1
);
has Properties => (
  is       => 'ro',
  isa      => ArrayRef [ InstanceOf ['Katatsumuri::Result::Property'] ],
  required => 1
);

no Mouse;
__PACKAGE__->meta->make_immutable;

method TO_JSON ( $class : ) : Return(HashRef) {
  return +{
    Name         => $class->Name,
    Namespace    => $class->Namespace,
    SuperClasses => $class->SuperClasses,
    Properties   => $class->Properties,
    Methods      => $class->Methods,
  };
}

# JSON文字列を返す
method to_json_string ( $class : ) : Return(Str) {
  return JSON::XS->new->pretty(1)->convert_blessed(1)->canonical(1)->encode($class);
}

1;
