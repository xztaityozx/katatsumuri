# katatsumuri

Perlのパッケージを別の言語の型に変換する実験

Perlのコードから型情報、型に定義されてるメソッド情報をJSONに書き出します。
関数・メソッドの情報は`Function::Parameters`や`Function::Return`のメタ情報だけじゃなく、`Data::Validator`やASTから引数名や型などをできるだけ取り出しています。

# 元のPerlコード
[My::Namespace::B](./perl/lib/My/Namespace/B.pm)

```perl
package My::Namespace::B;
use strictures 2;
use Function::Parameters;
use Function::Return;
use Types::Standard -types;
use Data::Validator;

use Mouse;

has name => (is => 'ro', isa => Str, default => 'this is name');
has age => (is => 'ro', isa => Int, required => 1);
has union => (is => 'ro', isa => Str|Int, required => 1);

no Mouse;
__PACKAGE__->meta->make_immutable;

sub a {
    return 10;
}

fun b() :Return(Int) {
    return 10;
};

method c() :Return(Int) {
    return 10;
};

method d(Str $str, $x, Int $y //= 1) {
    return 10;
};

sub e {
    my $rule = Data::Validator->new(
        str => { isa => Str },
        x => { isa => Any },
        y => { isa => Int, default => 1 },
    );

    $rule->validate(@_);

    return 10;
}

sub f :Return(Str, Int) {
    my ($self, $str, $x, $y) = @_;

    return [$str, $x+$y];
}

1;
```

# C#での例
生成されたJSONからC#のASTを構築してC#のソースコードを出力してます。

[生成のためのコード](./csharp/TypeGenerator/Program.cs)

```cs
// generated from ./lib/My/Namespace/B.pm
using System;

namespace My.Namespace
{
    public class B
    {
        public int A()
        {
            throw new NotImplementedException;
        }

        public int E(string str, object x, int y = 1)
        {
            throw new NotImplementedException;
        }

        ///<returns>Return type: :Return(string,integer)</returns>
        public (string, int) F()
        {
            throw new NotImplementedException;
        }

        public static int B()
        {
            throw new NotImplementedException;
        }

        public int C()
        {
            throw new NotImplementedException;
        }

        public int D(string str, object x, int y)
        {
            throw new NotImplementedException;
        }

        public string Name { get; set; } = "this is name";
        public int Age { get; set; }

        // original type: Union[string|integer]
        public object Union { get; set; }
    }
}
```

# これから
1. メソッド情報以外の情報はJSON Schemaから得ることにして、メソッド情報はASTやメタ情報からとるようにする
2. 型のひな型はJSON Schemaから生成して、メソッドはそこに追加するように書き換える


# わからんこと
PerlのパッケージってJSON Schema生成できるんですか？

