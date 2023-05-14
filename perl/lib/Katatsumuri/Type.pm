package Katatsumuri::Type;

use strictures 2;

use Function::Return;
use Function::Parameters;
use Types::Standard -types;
use Types::TypeTiny qw(TypeTiny);
use Type::Registry  qw(t);
use List::Util      qw(uniq);
use Carp            qw(croak);

use Moo;

has type => (is => 'ro', isa => Str | ArrayRef | TypeTiny, required => 1);
has default => (
    is       => 'ro',
    isa      => Str | Num | Int | Bool | ArrayRef | HashRef | Undef,
    required => 0,
    default  => sub { return undef }
);
has readonly => (is => 'ro', isa => Bool | Undef, required => 0, default => sub { return undef });

my $type_registry = Type::Registry->for_me;
$type_registry->add_types('Types::Standard');

use Feature::Compat::Try;

method _to_type_tiny (Str | ArrayRef | TypeTiny $type) : Return(TypeTiny) {
    if (Str->check($type)) {
        try {
            return $type_registry->lookup($type);
        }
        catch ($e) {
            return $type_registry->make_class_type($type);
        }
    }
    if (ArrayRef->check($type)) {
        return t->make_union(map { $self->_to_type_tiny($_) } @$type);
    }

    return $type;
}

method _convert ($class : Str | ArrayRef | TypeTiny $type) : Return(HashRef) {
    $type = $class->_to_type_tiny($type);

    if ($type == Int) {
        return +{ type => "integer" };
    }
    if ($type == Str || $type == ClassName || $type == RoleName || $type == RegexpRef) {
        return +{ type => "string" };
    }
    if ($type == Num) {
        return +{ type => "number" };
    }
    if ($type == Bool) {
        return +{ type => "boolean" };
    }
    if ($type == Any) {
        return +{ type => 'any' };
    }
    if ($type->parent == Optional || $type->parent == Maybe) {
        my $subtype = $class->_convert($type->type_parameter);
        if ($subtype->{enum}) {

            # Optional[Enum["a", "b", "c"]]みたいなやつ
            return +{ enum => [@{ $subtype->{enum} }, "null"] };
        }
        elsif ($subtype->{anyOf}) {
            return +{ anyOf => [@{ $subtype->{anyOf} }, { type => "null" }] };
        }
        elsif ($subtype->{allOf}) {

            # 交差型のオプショナル…。allOfかnullのどちらかという意味に変換してるけどあってるかなこれ
            return +{ oneOf => [{ allOf => [@{ $subtype->{allOf} }] }, { type => "null" }] };
        }
        else {
            # Optional[Int]みたいなやつ
            return +{ type => [$subtype->{type}, "null"] };
        }

    }
    if ($type->isa('Type::Tiny::Union')) {
        return +{ anyOf => [uniq map { $class->_convert($_) } @{ $type->type_constraints }] };
    }

    if ($type->isa('Type::Tiny::Intersection')) {
        return +{ allOf => [uniq map { $class->_convert($_) } @{ $type->type_constraints }] };
    }

    if ($type->isa('Type::Tiny::Enum')) {

        # すべてがIntの場合は、integerのEnumにして、そうでない場合は、stringのEnumにする
        my $is_all_int = 1;
        foreach my $value (@{ $type->values }) {
            if (!Int->check($value)) {
                $is_all_int = 0;
                last;
            }
        }
        if ($is_all_int) {
            return +{ enum => $type->unique_values };
        }
        else {
            # valuesはすべて文字列にしたいので、ダブルクォートで囲っておく。ただし、もうStrの場合はやらなくてよい
            my @values = map { Str->check($_) ? $_ : qq("$_") } @{ $type->unique_values };
            return +{ enum => \@values };
        }
    }

    if ($type->parent->strictly_equals(Tuple)) {
        return +{
            type        => "array",
            prefixItems => [map { $class->_convert($_) } @{ $type->parameters }],
        };
    }

    if ($type->parent == ArrayRef) {
        my $parameters = $type->parameters;
        my $rt = +{ type => "array" };
        if (@$parameters >= 1) {
            my $subtype = $class->_convert($parameters->[0]);
            $rt->{items} = $subtype;
        }
        if (@$parameters >= 2) {
            $rt->{minItems} = $parameters->[1];
        }

        if (@$parameters >= 3) {
            $rt->{maxItems} = $parameters->[2];
        }

        return $rt;
    }

    # Map[Key, Value]の場合はadditionalProperties, propertyNamesを使えば再現できる
    if ($type->parent->strictly_equals(Map)) {
        my $key_type = $class->_convert($type->parameters->[0]);
        my $value_type = $class->_convert($type->parameters->[1]);
        return +{
            type                 => "object",
            additionalProperties => $value_type,
            propertyNames        => $key_type,
        };
    }

    # DictはKeyの値が決まっているので、propertiesを使って再現する
    if ($type->parent->strictly_equals(Dict)) {
        my %properties = @{ $type->parameters };
        return +{
            type       => "object",
            properties => { map { $_ => $class->_convert($properties{$_}) } keys %properties },

            # OptionalかMayBeじゃないやつは必須なので、requiredに入れる
            required => [grep { $properties{$_}->parent != (Optional &Maybe) } keys %properties],
        };
    }

    if ($type->parent->strictly_equals(HashRef)) {
        my $subtype = $class->_convert($type->type_parameter);
        return +{ type => "object", additionalProperties => $subtype };
    }

    if ($type == ArrayRef) {
        return +{ type => 'array' };
    }
    if ($type == HashRef || $type == Object) {
        return +{ type => 'object' };
    }

    if ($type->parent->strictly_equals(Ref)) {
        my $parameters = $type->parameters;
        if (@$parameters == 1) {
            if ($parameters->[0] eq "HASH") {
                return +{ type => 'object' };
            }
            elsif ($parameters->[0] eq "ARRAY") {
                return +{ type => 'array' };
            }
            else {
                return +{ type => 'any' };
            }
        }
        else {
            croak('Refのパラメータが2つ以上ある場合は未対応です');
        }
    }

    if ($type->parent->strictly_equals(ScalarRef)) {
        return $class->_convert($type->type_parameter);
    }

    if ($type->isa('Type::Tiny::Class')) {
        my $subtype = $type->class;

        # クラス名のときはそのクラスについてのJSON Schemaがあるはずなので、それを参照する。無かったらしらん
        if (ClassName->check($subtype) || Str->check($subtype)) {
            return +{
                type   => 'object',
                '$ref' => "./" . $class->_to_upper_camel_case_string($subtype) . '.json'
            };
        }
        else {
            return $class->_convert($subtype);
        }
    }

    return +{ type => 'any' };
}

# ClassNameを受け取ってUpperCamelCaseな文字列に変換して返す
method _to_upper_camel_case_string (ClassName | Str $class_name) : Return(Str) {
    my $str = $class_name;
    $str =~ s/:://gx;
    $str =~ s/^_//x;
    return $str;
}

# to_json_schema はType::Tinyを表すJSON Schemaを作って返す
method to_json_schema ($class :) : Return(HashRef) {
    my $t = $class->_convert($class->type);
    $t->{description} = "original Perl type: "
      . (
          Str->check($class->type)      ? $class->type
        : ArrayRef->check($class->type) ? join(", ", @{ $class->type })
        :                                 $class->type->display_name
      );

    if (!Undef->check($class->default)) {
        $t->{default} = $class->default;
    }
    if (!Undef->check($class->readonly)) {
        $t->{readOnly} = $class->readonly ? \1 : \0;
    }
    return $t;
}

1;
