package Katatsumuri::Result::Property;
use strictures 2;
use Types::Standard qw( Str Bool Any HashRef InstanceOf );
use Function::Return;
use Function::Parameters qw( method override );
use Moo;

has type => (is => 'ro', isa => InstanceOf ['Katatsumuri::Type'], required => 1);
has name => (is => 'ro', isa => Str, required => 1);
has required => (is => 'ro', isa => Bool, required => 1, default => sub { return 1 });

1;

