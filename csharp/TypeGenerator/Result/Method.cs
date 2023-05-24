using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace Katatsumuri.Result;

public class Method
{
    public class Argument
    {
        public string Name { get; init; } = string.Empty;
        public JsonSchemaType Type { get; init; } = new();
        public bool Required { get; init; } = false;

        public string TrimmedName => Name.Trim('$', '@');

        public ParameterSyntax BuildParameterSyntax()
        {
            var syntax = SyntaxFactory.Parameter(SyntaxFactory.Identifier(TrimmedName));

            var typeSyntax = Type.BuildTypeSyntax();

            syntax = syntax.WithType(
                this is { Required: false, Type.Type: JsonSchemaPrimitiveType.Object }
                    ? SyntaxFactory.NullableType(typeSyntax)
                    : typeSyntax
            );

            if (Type.Default is not null)
            {
                // デフォルト値の設定。わからないときは default(T) になるようにしておく。
                // でもnullなほうがいいかもしれない？
                // コンパイルできることが目標じゃないので、まあいいかとなってる
                syntax = syntax.WithDefault(
                    SyntaxFactory.EqualsValueClause(
                        SyntaxFactory.LiteralExpression(
                            SyntaxKind.DefaultLiteralExpression,
                            Type.Type switch
                            {
                                // Primitive型はJsonElementから値がそのまま取り出せるので、それを使う感じ。
                                JsonSchemaPrimitiveType.Integer
                                    => SyntaxFactory.Literal(Type.Default?.GetInt32() ?? 0),
                                JsonSchemaPrimitiveType.Number
                                    => SyntaxFactory.Literal(Type.Default?.GetDecimal() ?? 0M),
                                JsonSchemaPrimitiveType.Boolean
                                    //なんかこの式つらくない？
                                    => Type.Default?.GetBoolean() ?? false
                                        ? SyntaxFactory.Token(SyntaxKind.TrueLiteralExpression)
                                        : SyntaxFactory.Token(SyntaxKind.FalseLiteralExpression),
                                JsonSchemaPrimitiveType.String
                                    => SyntaxFactory.Literal(Type.Default?.GetString() ?? ""),
                                // プリミティブ型じゃない場合は = defaultになる
                                _ => SyntaxFactory.Token(SyntaxKind.DefaultExpression)
                            }
                        )
                    )
                );
            }
            return syntax;
        }

        /// <summary>
        /// この引数に対応するXMLのparamタグを作って返す
        /// </summary>
        /// <returns></returns>
        public XmlElementSyntax BuildParamCommentSyntax()
        {
            var xmlCommentSyntax = SyntaxFactory.XmlParamElement(
                TrimmedName,
                new SyntaxList<XmlNodeSyntax>(
                    SyntaxFactory
                        .XmlText()
                        .WithTextTokens(
                            SyntaxFactory.TokenList(
                                SyntaxFactory.XmlTextLiteral(
                                    SyntaxFactory.TriviaList(),
                                    Type.Description ?? "",
                                    Type.Description ?? "",
                                    SyntaxFactory.TriviaList()
                                )
                            )
                        )
                )
            );

            return xmlCommentSyntax;
        }
    }

    public enum MethodDeclareType
    {
        Sub,
        Fun,
        Method,
        Override,
        Around,
        Before,
        After,
        Unknown
    }

    public IEnumerable<Argument> Arguments { get; init; } = Enumerable.Empty<Argument>();
    public JsonSchemaType? Returns { get; init; } = null;
    public MethodDeclareType DeclareType { get; init; } = MethodDeclareType.Unknown;
    public string Name { get; init; } = string.Empty;

    /// <summary>
    /// 引数部分の構文木を作って返す
    /// </summary>
    /// <returns></returns>
    private ParameterListSyntax BuildParameterListSyntax()
    {
        return SyntaxFactory.ParameterList(
            SyntaxFactory.SeparatedList(
                Arguments.Select(argument => argument.BuildParameterSyntax())
            )
        );
    }

    /// <summary>
    /// このメソッドの構文木を作って返す
    /// </summary>
    /// <returns></returns>
    public MethodDeclarationSyntax BuildMethodDeclarationSyntax()
    {
        var method = SyntaxFactory
            .MethodDeclaration(
                Returns is null
                    ? SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.VoidKeyword))
                    : Returns.BuildTypeSyntax(),
                Name
            )
            .WithParameterList(BuildParameterListSyntax())
            .WithBody(
                // 実装まではさすがに移せないので、NotImplementedExceptionを投げるだけにしている
                SyntaxFactory.Block(
                    SyntaxFactory.ThrowStatement(
                        SyntaxFactory.ObjectCreationExpression(
                            SyntaxFactory.ParseTypeName(nameof(NotImplementedException)),
                            SyntaxFactory.ArgumentList(
                                SyntaxFactory.Token(SyntaxKind.OpenParenToken),
                                new SeparatedSyntaxList<ArgumentSyntax>(),
                                SyntaxFactory.Token(SyntaxKind.CloseParenToken)
                            ),
                            null
                        )
                    )
                )
            )
            .WithModifiers(SyntaxFactory.TokenList(SyntaxFactory.Token(SyntaxKind.PublicKeyword)));

        // コメント部分ここから
        var xmlCommentTriviaList = new List<SyntaxTrivia>
        {
            // 空っぽのSummaryタグ。無くてもいい
            SyntaxFactory.Trivia(
                SyntaxFactory.DocumentationComment(
                    SyntaxFactory.XmlSummaryElement(SyntaxFactory.XmlText(""))
                )
            )
        };
        // paramタグのリスト
        xmlCommentTriviaList.AddRange(
            Arguments.Select(
                arg =>
                    SyntaxFactory.Trivia(
                        SyntaxFactory.DocumentationComment(arg.BuildParamCommentSyntax())
                    )
            )
        );

        // returnsタグ。最後の改行を含む
        xmlCommentTriviaList.Add(
            SyntaxFactory.Trivia(
                SyntaxFactory.DocumentationComment(
                    SyntaxFactory.XmlReturnsElement(
                        SyntaxFactory.XmlText(Returns?.Description ?? "")
                    ),
                    SyntaxFactory
                        .XmlText()
                        .WithTextTokens(
                            SyntaxFactory.TokenList(
                                SyntaxFactory.XmlTextNewLine(
                                    SyntaxFactory.TriviaList(),
                                    Environment.NewLine,
                                    Environment.NewLine,
                                    SyntaxFactory.TriviaList()
                                )
                            )
                        )
                )
            )
        );

        method = method.WithLeadingTrivia(xmlCommentTriviaList);

        if (
            DeclareType
            is MethodDeclareType.Override
                // After, Before, Around ってオーバーライドと言えるかは怪しいけど、他に表せそうなのもなく…。
                or MethodDeclareType.After
                or MethodDeclareType.Before
                or MethodDeclareType.Around
        )
        {
            method = method.AddModifiers(SyntaxFactory.Token(SyntaxKind.OverrideKeyword));
        }

        return method;
    }
}
