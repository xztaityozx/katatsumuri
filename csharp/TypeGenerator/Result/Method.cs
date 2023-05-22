using System.Text.Json;
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

        public ParameterSyntax BuildParameterSyntax()
        {
            return SyntaxFactory
                .Parameter(SyntaxFactory.Identifier(Name))
                .WithType(
                    Required
                        ? SyntaxFactory.NullableType(Type.BuildTypeSyntax())
                        : Type.BuildTypeSyntax()
                );
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
    public JsonElement Returns { get; init; } = default;
    public MethodDeclareType DeclareType { get; init; } = MethodDeclareType.Unknown;
    public string Name { get; init; } = string.Empty;

    /// <summary>
    /// 戻り値の型を得る。nullならvoid
    /// </summary>
    public JsonSchemaType? ReturnsJsonSchemaType =>
        Returns.GetRawText() == "void"
            ? null
            : JsonSerializer.Deserialize<JsonSchemaType>(
                Returns.GetRawText(),
                new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }
            );

    private ParameterListSyntax BuildParameterListSyntax()
    {
        return SyntaxFactory.ParameterList(
            SyntaxFactory.SeparatedList(
                Arguments.Select(x =>
                {
                    var syntax = x.BuildParameterSyntax();
                    if (x.Required)
                        return syntax;
                    return syntax.WithDefault(
                        SyntaxFactory.EqualsValueClause(
                            SyntaxFactory.LiteralExpression(SyntaxKind.NullLiteralExpression)
                        )
                    );
                })
            )
        );
    }

    public TypeSyntax BuildReturnTypeSyntax()
    {
        var rawText = Returns.GetRawText();
        if (rawText == "void")
            return SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.VoidKeyword));

        var jsonSchemaType = JsonSerializer.Deserialize<JsonSchemaType>(
            rawText,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }
        );

        return jsonSchemaType?.BuildTypeSyntax()
            ?? SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.VoidKeyword));
    }

    public MethodDeclarationSyntax BuildMethodSyntaxDeclarationSyntax()
    {
        var method = SyntaxFactory
            .MethodDeclaration(BuildReturnTypeSyntax(), Name)
            .WithParameterList(BuildParameterListSyntax())
            .WithBody(
                SyntaxFactory.Block(
                    SyntaxFactory.ThrowStatement(
                        SyntaxFactory.ObjectCreationExpression(
                            SyntaxFactory.IdentifierName(nameof(NotImplementedException))
                        )
                    )
                )
            )
            .WithModifiers(SyntaxFactory.TokenList(SyntaxFactory.Token(SyntaxKind.PublicKeyword)));

        if (
            DeclareType
            is MethodDeclareType.Override
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
