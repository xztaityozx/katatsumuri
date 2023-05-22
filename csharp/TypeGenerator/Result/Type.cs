using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Operations;
using Katatsumuri.Result;

namespace Katatsumuri.Result;

public class JsonSchemaType
{
    public string? Description { get; init; } = string.Empty;
    public JsonSchemaPrimitiveType? Type { get; init; } = null;
    public JsonElement? Const { get; init; } = null;
    public JsonElement? Default { get; init; } = null;
    public IEnumerable<JsonSchemaType>? AnyOf { get; init; } = null;
    public IEnumerable<JsonSchemaType>? AllOf { get; init; } = null;
    public IEnumerable<JsonSchemaType>? OneOf { get; init; } = null;
    public bool? Required { get; init; } = null;
    public IEnumerable<JsonSchemaType>? Items { get; init; } = null;
    public JsonElement? Ref { get; init; } = null;

    public TypeSyntax BuildTypeSyntax()
    {
        if (Const is not null)
        {
            return Type?.ToTypeSyntax()
                ?? SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.ObjectKeyword));
        }

        if (Type == JsonSchemaPrimitiveType.Array)
        {
            if (Items is null || !Items.Any())
                return SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.ObjectKeyword));
            if (Items.Count() == 1)
                return SyntaxFactory.ArrayType(Items.First().BuildTypeSyntax());
            return SyntaxFactory.TupleType(
                SyntaxFactory.SeparatedList(
                    Items.Select(x => SyntaxFactory.TupleElement(x.BuildTypeSyntax()))
                )
            );
        }

        if (
            Type == JsonSchemaPrimitiveType.Object
            || AnyOf is not null
            || AllOf is not null
            || OneOf is not null
        )
            return SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.ObjectKeyword));

        return Type?.ToTypeSyntax()
            ?? SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.ObjectKeyword));
    }
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum JsonSchemaPrimitiveType
{
    String,
    Number,
    Integer,
    Boolean,
    Object,
    Array,
    Null,
    Any,
}

public static class JsonSchemaPrimitiveTypeExtension
{
    /// <summary>
    ///
    /// </summary>
    /// <param name="type"></param>
    /// <returns></returns>
    /// <exception cref="ArgumentOutOfRangeException"></exception>
    public static TypeSyntax ToTypeSyntax(this JsonSchemaPrimitiveType type) =>
        SyntaxFactory.PredefinedType(
            SyntaxFactory.Token(
                type switch
                {
                    JsonSchemaPrimitiveType.String => SyntaxKind.StringKeyword,
                    JsonSchemaPrimitiveType.Number => SyntaxKind.DecimalKeyword,
                    JsonSchemaPrimitiveType.Integer => SyntaxKind.IntKeyword,
                    JsonSchemaPrimitiveType.Boolean => SyntaxKind.BoolKeyword,
                    JsonSchemaPrimitiveType.Object
                    or JsonSchemaPrimitiveType.Any
                        => SyntaxKind.ObjectKeyword,
                    JsonSchemaPrimitiveType.Null => SyntaxKind.NullKeyword,
                    _ => throw new ArgumentOutOfRangeException(nameof(type), type, null)
                }
            )
        );
}
