package Katatsumuri::Inspector::Methods::Returns;

use strictures 2;
use Function::Return;
use Function::Parameters;
use Types::Standard -types;
use Katatsumuri::Type;
use Type::Utils -all;
use Type::Library -base,
  -declare => qw( PpiStatementPackage Methods PpiStatement ReturnsOrUndef PpiStatementBreak PpiToken );
type 'PpiStatementPackage', as InstanceOf ['PPI::Statement::Package'];
type 'PpiStatement',        as InstanceOf ['PPI::Statement'];
type 'PpiStatementBreak',   as InstanceOf ['PPI::Statement::Break'];
type 'PpiToken',            as InstanceOf ['PPI::Element'];
type 'Methods',             as ArrayRef [InstanceOf ['Katatsumuri::Result::Method']];
type 'ReturnsOrUndef',      as InstanceOf ['Katatsumuri::Type'] | Undef;

use List::Util qw(all any uniq);

# inspect は、メソッドのコードリファレンスと、そのメソッドのPPIノードを受け取って、
# そのメソッドの返却値の型情報を返す。
# 単一の Katatsumuri::Type が返されるが void のときはUndefが返される
# @returns InstanceOf['Katatsumuri::Type'] | Undef
method inspect ($class : CodeRef $coderef, PpiStatement $statement_node) : Return(ReturnsOrUndef) {
    if (my $meta = Function::Return::meta($coderef)) {

        # Function::Return::meta が使えたときはそこからいい感じに取り出してくる
        my $returns = $meta->returns;

        # コンテキストごとに返す型が違うことがあるので、アクセサーが3つもある
        # ここでは、scalar, void, list の順に優先して型情報を取り出してるけど
        # 深く考えて決めてないので、不都合あったら並び替えてもよさそう
        return Katatsumuri::Type->new(type => $returns->scalar || $returns->void || $returns->list);
    }

    # シグネチャ情報が得られないときはPPIをたどってできるだけ返却値の型を取り出す
    my @package_children = $statement_node->children;
    my $return_statements = $statement_node->find(
        sub {
            my ($root, $node) = @_;

            # メソッドの中にメソッドがある場合や、何かの引数としての無名関数などは無視したいので、親の親を見る
            # というのも構造的には以下のようになってるから
            # PPI::Statement::Sub
            #   + PPI::Statement::Block
            #     + PPI::Statement::Break
            # Breakはreturn以外にcontinueとかnextもあるので、Breakの次の要素がreturnかどうかもみてる
            if ($root != $node->parent->parent) {
                return 0;
            }
            if ($node->isa('PPI::Statement::Break')) {
                return $node->first_element->content eq 'return';
            }
        }
    );

    # return文がない場合はvoidとして扱う
    if (!$return_statements) {
        return undef;
    }

    my @types;
    my @values;
    foreach my $return_statement (@{$return_statements}) {
        my $type_and_value = $class->_get_statement_break_type_and_value($return_statement);
        push @types,  $type_and_value->{type};
        push @values, $type_and_value->{value} if defined $type_and_value->{value};
    }

    # 型情報が一つもないなら、voidとして扱う
    if (scalar @types == 0) {
        return undef;
    }

    # 型情報が一つだけなら、それを返す
    if (scalar @types == 1) {
        return Undef->check($types[0])
          ? undef
          : Katatsumuri::Type->new(type => $types[0], default => $values[0] // undef);
    }

    # 型情報のすべてがintegerで、かつ値が0か1のみなら、booleanとして扱う
    if (all { $_->{type} == Int } @types && all { $_->{value} eq "0" || $_->{value} eq "1" } @values) {
        return Katatsumuri::Type->new(type => Bool, default => $values[0] // undef);
    }

    # 全ての型が一致してれば、それを返す
    if (scalar uniq @types == 1) {
        return Undef->check($types[0]) ? undef : Katatsumuri::Type->new(type => $types[0]);
    }

    return Katatsumuri::Type->new(type => uniq(@types));
}

method _get_token_type_and_value ($class : PpiToken $token) : Return(HashRef) {
    if ($token->isa('PPI::Token::Number::Float')) {
        return { type => Num, value => 0.0 + $token->content };
    }

    # version型はほかの言語にあんまりないし、stringとして扱う
    if ($token->isa('PPI::Token::Number::Version')) {
        return { type => Str, value => $token->content };
    }

    if ($token->isa('PPI::Token::Number')) {
        return { type => Int, value => 0 + $token->content };
    }

    if ($token->isa('PPI::Token::Quote')) {
        return { type => Str, value => $token->content };
    }

    if ($token->isa('PPI::Structure::Constructor')) {
        if ($token->first_element->content eq '{') {
            return { type => Object };
        }

        my $array_statement = $token->find_first('PPI::Statement');

        # 空の配列のときはany型の配列として扱う
        if (!$array_statement) {
            return { type => ArrayRef [Any] };
        }
        my $array_elements = $array_statement->find(
            sub {
                my (undef, $node) = @_;

                # 空白と演算子以外のトークンを取り出す(=たぶん配列を構成する要素のみになる)
                if ($node->isa('PPI::Token::Whitespace')) {
                    return 0;
                }
                if ($node->isa('PPI::Token::Operator')) {
                    return 0;
                }

                return 1;
            }
        );

        # 各要素の型を再帰で取得する
        my @sub_types = map { $class->_get_token_type_and_value($_) } @{$array_elements};

        # すべての要素が同じ型のときは単一の型の配列として扱う
        # [[1,2], [3], [4,5]] みたいなのは、type => +{ array => +{ array => 'integer' } } として扱えるといいんだけど
        # 再帰の方法を変えなきゃいけなくてめんどい
        if (scalar uniq(map { $_->{type} } @sub_types) == 1) {
            return +{
                type  => ArrayRef [$sub_types[0]->{type}],
                value => [map { $_->{value} } @sub_types]
            };
        }

        # 混ざっていたり、特定できないときはany型の配列として扱う
        return { type => ArrayRef [Any] };
    }

    return +{ type => Any };
}

method _get_statement_break_type_and_value ($class : PpiStatementBreak $ppi_element) : Return(HashRef) {
    my $first_token = $ppi_element->find_first(
        sub {
            my (undef, $node) = @_;

            # returnと空白以外に最初に出てきたトークンを返す
            if ($node->isa('PPI::Token::Whitespace')) {
                return 0;
            }
            if ($node->isa('PPI::Token::Word') && $node->content eq 'return') {
                return 0;
            }
            if ($node->isa('PPI::Token::Operator')) {
                return 0;
            }
            return 1;
        }
    );

    # return文のみの場合はvoidとして扱う
    if (!$first_token || ($first_token->isa('PPI::Token::Structure') && $first_token->content eq ';')) {
        return { type => undef };
    }

    return $class->_get_token_type_and_value($first_token);
}

1;
