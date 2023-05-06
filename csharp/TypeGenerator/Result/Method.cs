using System.Text.Json;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace Katatsumuri.Result;

public record Method
{
    public record Argument(
        string Name,
        TypeConstraint Type,
        bool Required,
        Argument.ArgumentDefault? Default
    )
    {
        public enum ArgumentDefaultDeclarationType
        {
            // デフォルト値の定義が定数だった
            Constant,

            // デフォルト値の定義が関数の戻り値とかを使ってて実行時にしか分からないやつだった
            Sub
        }

        public record ArgumentDefault(ArgumentDefaultDeclarationType Type, JsonElement Value)
        {
            /// <summary>
            /// 型からデフォルト値のLiteralExpressionSyntaxを作って返す
            /// </summary>
            /// <param name="valuesType"></param>
            /// <returns></returns>
            public LiteralExpressionSyntax BuildLiteralExpressionSyntax(string valuesType)
            {
                return valuesType switch
                {
                    "integer"
                    or "hex"
                    or "octal"
                    or "binary"
                        => SyntaxFactory.LiteralExpression(
                            SyntaxKind.NumericLiteralExpression,
                            SyntaxFactory.Literal(Value.GetInt32())
                        ),
                    "string"
                        => SyntaxFactory.LiteralExpression(
                            SyntaxKind.StringLiteralExpression,
                            SyntaxFactory.Literal(Value.GetString() ?? "")
                        ),
                    "boolean"
                        => SyntaxFactory.LiteralExpression(
                            Value.GetBoolean()
                                ? SyntaxKind.TrueLiteralExpression
                                : SyntaxKind.FalseLiteralExpression
                        ),
                    "decimal"
                        => SyntaxFactory.LiteralExpression(
                            SyntaxKind.NumericLiteralExpression,
                            SyntaxFactory.Literal(Value.GetDecimal())
                        ),
                    _ => SyntaxFactory.LiteralExpression(SyntaxKind.NullLiteralExpression)
                };
            }
        }

        /// <summary>
        /// 引数部分のSyntaxを作って返す
        /// </summary>
        /// <returns></returns>
        public ParameterSyntax BuildParameterListSyntax()
        {
            var type = Type.GetTypeSyntax();
            var parameter = SyntaxFactory
                .Parameter(SyntaxFactory.Identifier(Name.TrimStart('$', '@').ToLowerCamelCase())) // Perlの変数は$とか@がprefixになってる。要らんので消す
                .WithType(type);

            // 定数なデフォルト値の場合だけデフォルト値を展開する
            // 他にはSubとかがあるけど、実行時にデフォルト値が決まるようなものは
            // 静的解析じゃその値がわからないので、デフォルト値はなかったことにしてる
            if (Default is not null && Default.Type == ArgumentDefaultDeclarationType.Constant)
            {
                parameter = parameter.WithDefault(
                    SyntaxFactory.EqualsValueClause(Default.BuildLiteralExpressionSyntax(Type.Type))
                );
            }

            return parameter;
        }
    }

    public record Return(TypeConstraint Type, object? Value);

    public enum MethodDeclareType
    {
        // Function::Parametersの:stdと:modifiers
        Fun,
        Method,
        Override,
        After,
        Before,
        Around,

        // Perlネイティブなサブルーチンでの定義だった
        Sub,

        // わからんかった。基本的にないけど…
        Unknown
    }

    public IEnumerable<Argument> Arguments { get; set; }
    public IEnumerable<Return> Returns { get; set; }
    public MethodDeclareType DeclareType { get; set; } = MethodDeclareType.Unknown;
    public string Name { get; set; }

    public Method(
        string name,
        IEnumerable<Argument> arguments,
        IEnumerable<Return> returns,
        MethodDeclareType declareType
    )
    {
        Name = name;
        Arguments = arguments;
        Returns = returns;
        DeclareType = declareType;
    }

    /// <summary>
    /// メソッドのSyntaxを作って返す
    /// </summary>
    /// <returns></returns>
    public MethodDeclarationSyntax BuildMethodSyntax()
    {
        // 変数名の変換。Perlは慣習的にsnake_caseだけどC#ではUpperCamelCaseなので変えてる
        // Jsonを読み取る時に変換できたらいいんだけどな～
        Name = Name.ToUpperCamelCase();
        var returnType = Returns.Count() switch
        {
            0 => SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.VoidKeyword)),
            1 => Returns.First().Type.GetTypeSyntax(),
            _
                => SyntaxFactory.TupleType(
                    SyntaxFactory.SeparatedList(
                        Returns.Select(x => SyntaxFactory.TupleElement(x.Type.GetTypeSyntax()))
                    )
                )
        };

        var parameters = SyntaxFactory.ParameterList(
            SyntaxFactory.SeparatedList(Arguments.Select(x => x.BuildParameterListSyntax()))
        );

        var method = SyntaxFactory
            .MethodDeclaration(returnType, Name)
            .WithParameterList(parameters)
            .WithModifiers(SyntaxFactory.TokenList(SyntaxFactory.Token(SyntaxKind.PublicKeyword)))
            .WithBody(
                // 実装はスキーマ情報からわからないので例外を投げるだけ
                SyntaxFactory.Block(
                    SyntaxFactory.ThrowStatement(
                        SyntaxFactory.ObjectCreationExpression(
                            SyntaxFactory.ParseTypeName(nameof(NotImplementedException)),
                            SyntaxFactory.ArgumentList(),
                            null
                        )
                    )
                )
            );

        if (Returns.Count() > 1)
        {
            // 戻り値の型が複数個あるときは、もともとどんな型で定義されていたかのヒントを書いておく
            // <returns></returns>に書いてるけど個々じゃなくてもいいかもしれない
            var comment =
                $"Return type: :Return({string.Join(",", Returns.Select(x => x.Type.Type))})";
            method = method.WithLeadingTrivia(
                SyntaxFactory.TriviaList(
                    SyntaxFactory.Trivia(
                        SyntaxFactory.DocumentationComment(
                            SyntaxFactory.XmlReturnsElement(SyntaxFactory.XmlText(comment)),
                            XmlTextSyntaxFactory.NewLine()
                        )
                    )
                )
            );
        }

        // DeclareTypeによって修飾子を変える
        method = DeclareType switch
        {
            MethodDeclareType.Fun
                => method.AddModifiers(SyntaxFactory.Token(SyntaxKind.StaticKeyword)),
            // After/Before/Aroundは厳密にいうとoverrideってわけじゃないと思うけど
            // C#の文脈でいうとoverrideぐらいしかないのでここにしてる
            MethodDeclareType.After
            or MethodDeclareType.Before
            or MethodDeclareType.Around
            or MethodDeclareType.Override
                => method.AddModifiers(SyntaxFactory.Token(SyntaxKind.OverrideKeyword)),
            _ => method
        };

        return method;
    }
}
