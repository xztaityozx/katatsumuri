using System.Text.Json;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace Katatsumuri.Result;

public record Property(string Name, TypeConstraint Type, bool IsReadonly, JsonElement? Default)
{
    /// <summary>
    /// プロパティのSyntaxを作って返す
    /// </summary>
    /// <returns></returns>
    public PropertyDeclarationSyntax BuildDeclarationSyntax()
    {
        var declaration = SyntaxFactory
            .PropertyDeclaration(
                Type.GetTypeSyntax(),
                SyntaxFactory.Identifier(Name.ToUpperCamelCase())
            )
            .WithModifiers(SyntaxFactory.TokenList(SyntaxFactory.Token(SyntaxKind.PublicKeyword)))
            .WithAccessorList(
                SyntaxFactory.AccessorList(
                    // IsReadonlyがtrueならGetterだけ、falseならGetterとSetter両方
                    SyntaxFactory.List(
                        (
                            IsReadonly
                                ? new[] { SyntaxKind.GetAccessorDeclaration }
                                : new[]
                                {
                                    SyntaxKind.GetAccessorDeclaration,
                                    SyntaxKind.SetAccessorDeclaration
                                }
                        ).Select(
                            accessor =>
                                SyntaxFactory
                                    .AccessorDeclaration(accessor)
                                    .WithSemicolonToken(
                                        SyntaxFactory.Token(SyntaxKind.SemicolonToken)
                                    )
                        )
                    )
                )
            );

        if (Default.HasValue)
        {
            declaration = declaration
                .WithInitializer(
                    SyntaxFactory.EqualsValueClause(
                        Type.Type switch
                        {
                            "int"
                                => SyntaxFactory.LiteralExpression(
                                    SyntaxKind.NumericLiteralExpression,
                                    SyntaxFactory.Literal(Default.Value.GetString() ?? "0")
                                ),
                            "string"
                                => SyntaxFactory.LiteralExpression(
                                    SyntaxKind.StringLiteralExpression,
                                    SyntaxFactory.Literal(Default.Value.GetString() ?? "")
                                ),
                            "bool"
                                => SyntaxFactory.LiteralExpression(
                                    Default.Value.GetRawText() == "true"
                                        ? SyntaxKind.TrueLiteralExpression
                                        : SyntaxKind.FalseLiteralExpression
                                ),
                            "decimal"
                                => SyntaxFactory.LiteralExpression(
                                    SyntaxKind.NumericLiteralExpression,
                                    SyntaxFactory.Literal(Default.Value.GetString() ?? "0")
                                ),
                            _ => SyntaxFactory.LiteralExpression(SyntaxKind.NullKeyword)
                        }
                    )
                )
                .WithSemicolonToken(SyntaxFactory.Token(SyntaxKind.SemicolonToken));
        }

        if (Type is { IsUnion: true, Union: not null })
        {
            declaration = declaration.WithLeadingTrivia(
                SyntaxFactory.TriviaList(
                    SyntaxFactory.Comment(
                        $"// original type: Union[{string.Join("|", Type.Union.Select(t => t))}]"
                    )
                )
            );
        }

        return declaration;
    }
}
