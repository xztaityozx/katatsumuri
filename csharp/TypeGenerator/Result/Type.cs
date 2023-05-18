using System.Text.Json;
using System.Text.Json.Serialization;

namespace Katatsumuri.Result;

public class JsonSchemaType
{
    public string Description { get; init; } = string.Empty;
    public JsonSchemaPrimitiveType? Type { get; init; } = null;
    public JsonElement? Const { get; init; } = null;
    public JsonElement? Default { get; init; } = null;
    public IEnumerable<JsonSchemaType>? AnyOf { get; init; } = null;
    public IEnumerable<JsonSchemaType>? AllOf { get; init; } = null;
    public IEnumerable<JsonSchemaType>? OneOf { get; init; } = null;
    public bool? Required { get; init; } = null;
}

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum JsonSchemaPrimitiveType
{
    @String,
    @Number,
    @Integer,
    @Boolean,
    @Object,
    @Array,
    @Null,
    @Any
}
