package Katatsumuri::Result::Method::Return;

use strictures 2;
use Types::Standard -types;

use Moo;

has type => (is => 'ro', isa => InstanceOf ['Katatsumuri::Type'], required => 1);

1;
