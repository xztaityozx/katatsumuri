package Katatsumuri::Inspector::Properties;

use strictures 2;
use Function::Parameters qw(:std);
use Function::Return;
use Types::Standard -types;
use Type::Utils -all;
use Type::Library -base, -declare => qw( PpiStatementPackage Methods );
type 'PpiStatementPackage', as InstanceOf ['PPI::Statement::Package'];

use PPI;
use DDP;
use PPI::Dumper;

use Katatsumuri::Result::Property;
use Mouse::Util;

method inspect ($class : PpiStatementPackage $package_statement) :
  Return(ArrayRef[InstanceOf['Katatsumuri::Result::Property']]) {

    #PPI::Dumper->new($package_statement)->print if $package_statement->namespace eq 'My::Namespace::Person';

    my $mouse_on = 0;
    my $has_statements = $package_statement->find(
        sub {
            my ($root, $node) = @_;
            if ($node->isa('PPI::Statement::Include')) {
                if ($node->module eq 'Mouse') {
                    $mouse_on = $node->type eq 'use';
                }
            }

            if ($node->isa('PPI::Token::Word') && $node->content eq 'has' && $mouse_on) {
                return 1;
            }
            return 0;
        }
    );

    if (!$has_statements) {
        return [];
    }

    my $meta = Mouse::Util::get_metaclass_by_name($package_statement->namespace);

    if (!$meta) {
        return [];
    }

    my @properties;
    foreach my $has_statement (@{$has_statements}) {
        my $maybe_property_name = $has_statement->snext_sibling;
        my $attr =
          $meta->get_attribute($maybe_property_name->isa('PPI::Token::Quote')
            ? $maybe_property_name->string
            : $maybe_property_name->content);
        push @properties,
          Katatsumuri::Result::Property->new(
            name       => $attr->name,
            type       => $attr->type_constraint->name,
            default    => $attr->default,
            is_readonly => $attr->{is} eq 'ro' ? 1 : 0,
          );
    }

    return \@properties;
}

1;

