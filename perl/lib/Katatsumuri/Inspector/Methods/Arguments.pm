package Katatsumuri::Inspector::Methods::Arguments;

use strictures 2;
use Function::Return;
use Function::Parameters;
use Types::Standard -types;
use Type::Tiny;
use Type::Utils -all;
use Type::Library -base,
  -declare => qw( ArgumentsOrUndef PpiStatement PpiStructureList PpiElement PpiStatementVariable );

use Katatsumuri::Inspector::Methods::Arguments::DataValidator;

use PPI;

use List::Util qw(any);

type 'ArgumentsOrUndef',     as ArrayRef [InstanceOf ['Katatsumuri::Result::Method::Argument']] | Undef;
type 'PpiStatement',         as InstanceOf ['PPI::Statement'];
type 'PpiStructureList',     as InstanceOf ['PPI::Structure::List'];
type 'PpiElement',           as InstanceOf ['PPI::Element'];
type 'PpiStatementVariable', as InstanceOf ['PPI::Statement::Variable'];

method _inspect_from_ppi_statement_variable ($class : PpiStatementVariable $statement_variable) :
  Return(ArgumentsOrUndef) {
    my @arguments;
    my @variables = $statement_variable->variables;

    # PPI::Statement::Variable がない場合はundefを返す
    if (!@variables) {
        return undef;
    }

    # 空白を削除して検索しやすくする。
    $statement_variable->prune('PPI::Token::Whitespace');

    # 以下のようなときだけ引数の列挙をする
    # my ($a, $b, $c) = @_;
    # my ($a, $b, $c) = (shift, shift, shift);
    # my $a = shift;

    # 左辺値、右辺値のASTを取り出す。[2]は代入演算子 [0]はmyとかlocal
    my @children = $statement_variable->children;
    my $left_hand = $children[1];
    my $right_hand = $children[3];

    # 左辺値、右辺値が取り出せない場合はスキップ
    # 多くの場合は右辺値が取り出せないだけ。これは変数の定義だけの場合
    if (!$left_hand || !$right_hand) {
        return undef;
    }

    # 左辺値が単一のシンボルの場合は
    #   右辺値がshiftと@_のみのリスト: array => any
    #   右辺値がshiftか@_のみ: any
    if ($left_hand->isa('PPI::Token::Symbol')) {
        if($left_hand->symbol eq '$self' || $left_hand->symbol eq '$class') {
            return undef;
        }
        if ($right_hand->isa('PPI::Structure::List') && $class->_is_shift_only_list($right_hand)) {
            push @arguments,
              Katatsumuri::Result::Method::Argument->new(
                name     => $left_hand->symbol,
                type     => +{ array => 'any' },
                required => 1
              );
        }

        if ($class->_is_at_var($right_hand) || $class->_is_shift($right_hand)) {
            push @arguments,
              Katatsumuri::Result::Method::Argument->new(
                name     => $left_hand->symbol,
                type     => 'any',
                required => 1
              );
        }
    }

    # 左辺値がリストの場合は右辺値が@_のみか、shiftと@_のみのリストの場合のみ引数として扱う
    # 型はわからないのですべてany
    if ($left_hand->isa('PPI::Structure::List')) {
        if (   $class->_is_at_var($right_hand)
            || $class->_is_shift($right_hand)
            || $class->_is_shift_only_list($right_hand)) {
            foreach my $variable (@variables) {
                next if $variable eq '$self' || $variable eq '$class';
                push @arguments,
                  Katatsumuri::Result::Method::Argument->new(
                    name     => $variable,
                    type     => 'any',
                    required => 1
                  );
            }
        }
    }

    return \@arguments;
}

method _inspect_from_ppi ($class : PpiStatement $declare_statement) : Return(ArgumentsOrUndef) {
    my $data_validator_expression_statement = $declare_statement->find_first(
        sub {
            my (undef, $node) = @_;

            # Listが見つかったとき、そこからさかのぼって new, ->, Data::Validator の順に出てきたら
            # Data::Validatorのルールとみなす
            if ($node->isa('PPI::Structure::List')) {
                my $maybe_new_word = $node->sprevious_sibling;
                my $maybe_arrow_operator = $maybe_new_word->sprevious_sibling;
                my $maybe_data_validator_token_word = $maybe_arrow_operator->sprevious_sibling;

                if (!$maybe_new_word->isa('PPI::Token::Word') || $maybe_new_word->content ne 'new') {
                    return 0;
                }

                if (!$maybe_arrow_operator->isa('PPI::Token::Operator') || $maybe_arrow_operator->content ne '->') {
                    return 0;
                }

                if (  !$maybe_data_validator_token_word->isa('PPI::Token::Word')
                    || $maybe_data_validator_token_word->content ne 'Data::Validator') {
                    return 0;
                }

                return 1;
            }
            return 0;
        }
    );

    # Data::Varidator のルールがなかったか、ルールが変数に入ってたなどで補足できなかった場合は
    # 追跡を諦めてundefを返す
    if ($data_validator_expression_statement) {
        return Katatsumuri::Inspector::Methods::Arguments::DataValidator->inspect($data_validator_expression_statement);
    }

    my $ppi_statement_variables = $declare_statement->find(
        sub {
            my ($root, $node) = @_;
            if ($root == $node->parent) {
                return 0;
            }

            return $node->isa('PPI::Statement::Variable');
        }
    );

    if (!$ppi_statement_variables) {
        return [];
    }

    my @arguments;
    foreach my $ppi_statement_variable (@{$ppi_statement_variables}) {
        my $maybe_args = $class->_inspect_from_ppi_statement_variable($ppi_statement_variable);
        if ($maybe_args) {
            push @arguments, @{$maybe_args};
        }
    }
    return \@arguments;
}

# F::Parameters#info か F::Return#meta を使ってシグネチャを調べられるときだけ型情報を返す
method inspect ($class : CodeRef $coderef, PpiStatement $declare_statement) : Return(ArgumentsOrUndef) {
    if (my $info = Function::Parameters::info($coderef)) {

        # Function::Parameters::info が使えたときはそこからいい感じに取り出してくる
        my @arguments;
        foreach my $param ($info->positional_required) {
            push @arguments,
              Katatsumuri::Result::Method::Argument->new(Name => $param->name, Type => $param->type->name);
        }
        return \@arguments;
    }
    if (my $meta = Function::Return::meta($coderef)) {

        # Function::Return::meta が使えたときはそこからいい感じに取り出してくる
        # Function::Return を使うと Function::Parameters::info が undef を返すようになるので、
        # Function::Parameters と Function::Return を併用している場合はこちらのブロックで処理される
        my @arguments;
        foreach my $arg ($meta->all_args) {
            push @arguments,
              map { Katatsumuri::Result::Method::Argument->new(Name => $_->name, Type => $_->type->name) } @$arg;
        }
        return \@arguments;
    }

    # シグネチャ情報が得られないときはPPIでshiftや@_が代入されている変数を取り出してみる
    return $class->_inspect_from_ppi($declare_statement);
}

method _is_at_var (PpiElement $token) : Return(Bool) {
    return $token->isa('PPI::Token::Magic') && $token->content eq '@_';
}

method _is_shift (PpiElement $token) : Return(Bool) {
    return $token->isa('PPI::Token::Word') && $token->content eq 'shift';
}

method _is_shift_only_list (PpiStructureList $list) : Return(Bool) {
    my @children = $list->children;

    # 子要素が1つでないか、子要素がPPI::Statement::Expressionでない場合は不明なのでfalseを返す
    if (scalar @children != 1 || !$children[0]->isa('PPI::Statement::Expression')) {
        return 0;
    }

    my $expression = $children[0];

    # shift , @_ だけで構成されているかどうかを調べる
    foreach my $expression_child ($expression->children) {
        if ($expression_child->isa('PPI::Token::Word')) {
            if ($expression_child->content ne 'shift') {
                return 0;
            }
        }
        elsif ($expression_child->isa('PPI::Token::Magic')) {
            if ($expression_child->content ne '@_') {
                return 0;
            }
        }
        elsif ($expression_child->isa('PPI::Token::Operator')) {
            if ($expression_child->content ne ',') {
                return 0;
            }
        }
        else {
            return 0;
        }
    }
    return 1;
}

1;
