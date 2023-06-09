package Katatsumuri::Inspector::Properties;

use strictures 2;
use Function::Parameters qw(:std);
use Function::Return;
use Types::Standard -types;
use Type::Utils -all;
use Type::Library -base, -declare => qw( PpiStatementPackage Methods PpiDocument );
type 'PpiStatementPackage', as InstanceOf ['PPI::Statement::Package'];
type 'PpiDocument',         as InstanceOf ['PPI::Document'];

use PPI;

use Katatsumuri::Result::Property;
use Katatsumuri::Type;
use Mouse::Util;

method inspect ($class : PpiStatementPackage $package_statement, PpiDocument $ppi_document) :
  Return(ArrayRef[InstanceOf['Katatsumuri::Result::Property']]) {

    my $target_node = $package_statement->file_scoped ? $ppi_document : $package_statement;

    my $mouse_on = 0;
    my $has_statements = $ppi_document->find(
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
        my $attr = $meta->get_attribute(
              $maybe_property_name->isa('PPI::Token::Quote')
            ? $maybe_property_name->string
            : $maybe_property_name->content
        );
        push @properties,
          Katatsumuri::Result::Property->new(
            name => $attr->name,
            type => Katatsumuri::Type->new(
                type     => $attr->type_constraint,
                default  => $attr->default,
                readonly => $attr->{is} eq 'ro' ? 1 : 0
            )
          );
    }

    return \@properties;
}

1;

