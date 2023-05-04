package Katatsumuri::Inspector::Methods;

use strictures 2;
use Function::Return;
use Function::Parameters;
use Types::Standard -types;
use Type::Tiny;
use Class::Load qw(load_class);

use Katatsumuri::Result::Method;
use Katatsumuri::Result::Method::Argument;
use Katatsumuri::Inspector::Methods::Returns;
use Katatsumuri::Inspector::Methods::Arguments;
use Carp qw(croak);

use PPI;

use Type::Utils -all;
use Type::Library -base, -declare => qw( PpiStatementPackage Methods PpiDocument );
type 'PpiStatementPackage', as InstanceOf ['PPI::Statement::Package'];
type 'Methods',             as ArrayRef [InstanceOf ['Katatsumuri::Result::Method']];
type 'PpiDocument',         as InstanceOf ['PPI::Document'];

use Class::Load qw(load_class);

# _inspect_function_parameters_declares は Function::Parameters を使って定義した関数・メソッドのシグネチャ情報を配列で返す
method _inspect_function_parameters_declares ($class : PpiStatementPackage $package_node, PpiDocument $ppi_document) :
  Return(Methods) {
    my $target_node = $package_node->file_scoped ? $ppi_document : $package_node;
    my $function_parameters_declares = $target_node->find(
        sub {
            my (undef, $node) = @_;

            # 定義は PPI::Statement になるのでそれ以外は除外
            # refを見てるのは isa だと子クラスも含まれてしまうから
            if (ref($node) ne 'PPI::Statement') {
                return 0;
            }
            my $first_token_word = $node->find_first('PPI::Token::Word');

            if (!$first_token_word) {
                return 0;
            }

            # $first_token_word が fun/method/override/around/after/before なものだけを抽出
            my $content = $first_token_word->content;
            my $target_keywords = ['fun', 'method', 'override', 'around', 'after', 'before'];
            if (grep { $content eq $_ } @{$target_keywords}) {
                return $node;
            }

            return 0;
        }
    );

    # $function_parameters_declares が空なら空配列を返して終了
    if (!$function_parameters_declares) {
        return [];
    }

    load_class($package_node->namespace);

    my @result;
    foreach my $declare_node (@{$function_parameters_declares}) {
        my $token_words = $declare_node->find('PPI::Token::Word');
        my $declare_type = $token_words->[0]->content;
        my $function_name = $token_words->[1]->content;
        my $function_parameters =
          Katatsumuri::Inspector::Methods::Arguments->inspect($package_node->namespace->can($function_name),
            $declare_node);
        my $return_type =
          Katatsumuri::Inspector::Methods::Returns->inspect($package_node->namespace->can($function_name),
            $declare_node);
        push @result,
          Katatsumuri::Result::Method->new(
            name         => $function_name,
            arguments    => $function_parameters,
            returns      => $return_type,
            declare_type => $declare_type,
          );
    }
    return \@result;
}

# _inspect_sub_nodes は AST から PPI::Statement::Sub なものを列挙しそのシグネチャ情報を配列で返す
method _inspect_sub_nodes ($class : PpiStatementPackage $package_node, PpiDocument $ppi_document) : Return(Methods) {
    my $target_node = $package_node->file_scoped ? $ppi_document : $package_node;
    my $sub_nodes = $target_node->find('PPI::Statement::Sub');
    if (!$sub_nodes) {
        return [];
    }

    load_class($package_node->namespace);

    my @result;
    foreach my $sub_node (@{$sub_nodes}) {
        push @result,
          Katatsumuri::Result::Method->new(
            name      => $sub_node->name,
            arguments => Katatsumuri::Inspector::Methods::Arguments->inspect(
                $package_node->namespace->can($sub_node->name), $sub_node
            ),
            returns => Katatsumuri::Inspector::Methods::Returns->inspect(
                $package_node->namespace->can($sub_node->name), $sub_node
            ),
            declare_type => 'sub',
          );
    }

    return \@result;
}

method inspect ($class : PpiStatementPackage $package_node, PpiDocument $ppi_document) : Return(Methods) {
    my @methods;

    foreach my $arguments (@{ $class->_inspect_sub_nodes($package_node, $ppi_document) }) {
        push @methods, $arguments;
    }

    foreach my $arguments (@{ $class->_inspect_function_parameters_declares($package_node, $ppi_document) }) {
        push @methods, $arguments;
    }

    return \@methods;
}

1;
