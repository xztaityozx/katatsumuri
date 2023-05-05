package Katatsumuri::Inspector::Methods::Arguments::DataValidator;

use strictures 2;
use Function::Return;
use Function::Parameters;
use Types::Standard -types;
use Type::Tiny;
use Type::Utils -all;
use Type::Library -base,
  -declare =>
  qw( ArgumentsOrUndef PpiStructureList PpiElement PpiStructureConstructor );

use PPI;

type 'ArgumentsOrUndef',        as ArrayRef [InstanceOf ['Katatsumuri::Result::Method::Argument']] | Undef;
type 'PpiStructureList',        as InstanceOf ['PPI::Structure::List'];
type 'PpiElement',              as InstanceOf ['PPI::Element'];
type 'PpiStructureConstructor', as InstanceOf ['PPI::Structure::Constructor'];

method inspect ($class : PpiStructureList $data_validator_expression_statement) : Return(ArgumentsOrUndef) {
    my $first_expression = $data_validator_expression_statement->find_first('PPI::Statement::Expression');
    $first_expression->prune('PPI::Token::Whitespace');

    # HashRefであることを明示的にするための+を削除しておく
    # 後のwhileで順番に取り出すときに邪魔なため
    $first_expression->prune(
        sub {
            my (undef, $node) = @_;
            if ($node->isa('PPI::Token::Operator') && $node->content eq '+') {
                return $node->snext_sibling->isa('PPI::Structure::Constructor')
                  && $node->snext_sibling->content =~ /^{/x;
            }
        }
    );

    my @children = $first_expression->children;
    my @arguments;
    while (@children) {

        # 型名(key)とそのisa(value)を取り出す
        # 間にはカンマが入るけど、カンマじゃない可能性があり、カンマじゃない場合は解析をギブアップしたい。
        my $key = shift @children;
        my $maybe_middle_comma = shift @children;
        my $value = shift @children;

        # 足りない場合は解析を諦める
        if (!$key || !$maybe_middle_comma || !$value) {
            return undef;
        }

        # カンマが来てない場合は解析を諦める
        if (!$class->_is_comma($maybe_middle_comma)) {
            return undef;
        }

        # keyがSymbolだった場合、引数の名前が特定できないのでどうしようって感じ
        # Symbolのsymbolから `$` や `@` をはがした値を採用してもいいけど
        # 動的に決定されたルールではそうならないし困った。
        # 今回はSymbolの場合は解析を諦める
        if ($key->isa('PPI::Token::Symbol')) {
            return undef;
        }

        # valueがSymbolだった場合は型が特定できないのでanyで良い
        if ($value->isa('PPI::Token::Symbol')) {
            push @arguments,
              Katatsumuri::Result::Method::Argument->new(
                name => $key->content,
                type => Any,
                required => 1,
              );
        }
        elsif ($value->isa('PPI::Structure::Constructor')) {

            # valueがHashRefだった場合は、その中を解析して型を特定する
            # isa: 型名
            # default: デフォルト値
            # optional: 任意かどうか

            # ここの段階ではHashRefかListかわからん
            my $content = $value->content;
            if ($content =~ /^\{/x) {
                my $hash_ref = $class->_parse_hash_ref($value);
                my $type = $hash_ref->{isa} || Any;
                push @arguments,
                  Katatsumuri::Result::Method::Argument->new(
                    name => $key->content,
                    type => $type,
                    required => !$hash_ref->{optional},
                    ( $hash_ref->{default} ? ( default => $hash_ref->{default} ) : () ),
                  );
            }
            else {
                # Listだった場合はanyでお茶を濁す
                push @arguments,
                  Katatsumuri::Result::Method::Argument->new(
                    name => $key->content,
                    type => 'any'
                  );
            }
        } elsif($value->isa('PPI::Token::Quote')) {
            push @arguments,
              Katatsumuri::Result::Method::Argument->new(
                name => $key->content,
                type => $value->string,
                required => 1,
              );
        } else {
            # それ以外の場合は、そのまま型として採用する
            push @arguments,
              Katatsumuri::Result::Method::Argument->new(
                name => $key->content,
                type => $value->content,
                required => 1,
              );
        }

        # valueの後にもカンマが来るはずだけど、valueがSymbolだったりすると
        # そこから->が出てきてなんかの関数を呼び出したりする可能性がある。
        # 型としてはanyになるんだけど、後続の解析を続けられるように、カンマが出てくるまで消費すべき
        # 消費しきってもカンマが出てこない場合は、そこまでが引数であるとして解析を終了する
        while (@children) {
            my $maybe_last_comma = shift @children;
            if ($class->_is_comma($maybe_last_comma)) {
                last;
            }
        }
    }

    return \@arguments;
}

method _parse_hash_ref ($class : PpiStructureConstructor $ppi_structure_constructor) : Return(HashRef|Undef) {
    my @children = $ppi_structure_constructor->children;
    if (@children != 1) {
        print "children is not 1\n";
        return undef;
    }

    if (!$children[0]->isa('PPI::Statement::Expression')) {
        print "children[0] is not PPI::Statement::Expression\n";
        return undef;
    }

    my %result;
    my @ppi_statement_expression_children = $children[0]->children;
    while (@ppi_statement_expression_children) {
        my $key = shift @ppi_statement_expression_children;
        my $maybe_middle_comma = shift @ppi_statement_expression_children;
        my $value = shift @ppi_statement_expression_children;

        # 足りなかったり、カンマがなかったり、キーがシンボルだったりしたら解析を諦める
        if (!$key || !$maybe_middle_comma || !$value) {
            return undef;
        }

        if (!$class->_is_comma($maybe_middle_comma)) {
            return undef;
        }

        if ($key->isa('PPI::Token::Symbol')) {
            return undef;
        }

        my $key_content = $key->isa('PPI::Token::Quote') ? $key->string : $key->content;
        my $built_value = $class->_parse_data_validator_right_hand_hash_ref($key_content, $value);

        if ($key_content eq 'optional') { 
            if ($built_value && $built_value eq '1') {
                $result{optional} = 1;
            } elsif ($built_value && $built_value eq '0') {
                $result{optional} = 0;
            } 
        }
        else {
            $result{$key_content} = $built_value;
        }

        while (@ppi_statement_expression_children) {
            my $maybe_last_comma = shift @ppi_statement_expression_children;
            if ($class->_is_comma($maybe_last_comma)) {
                last;
            }
        }
    }

    return \%result;
}

method _parse_data_validator_right_hand_hash_ref (Str $key, PpiElement $value) : Return(HashRef|Str|Bool|Undef) {
    if ($key eq 'isa') {
        if ($value->isa('PPI::Token::Quote')) {
            return $value->string;
        }
        elsif ($value->isa('PPI::Token::Word')) {
            return $value->content;
        }
        else {
            return 'any';
        }
    }

    if ($key eq 'default') {
        if ($value->isa('PPI::Token::Quote')) {
            return +{ Type => 'constant', Value => $value->string };
        }
        elsif ($value->isa('PPI::Token::Number')) {
            return +{ Type => 'constant', Value => 0+$value->content };
        }
        elsif ($value->isa('PPI::Stetement::Sub')) {
            return +{ type => 'sub' };
        }
    }

    # optionalは1か0のみだけ許容。それ以外の時は解析できなかったことにして格納すらしない
    if ($key eq 'optional') {
        if ($value->isa('PPI::Token::Number' && ($value->content eq '1' || $value->content eq '0'))) {
            return $value->content;
        }
        else {
            return undef;
        }
    }

    return undef;
}

method _is_comma ($class : PpiElement $element) {
    return $element->isa('PPI::Token::Operator') && ($element->content eq ',' || $element->content eq '=>');
}

1;
