using System.Text.Json;

namespace Katatsumuri.Result;

public class Method
{
    public class Argument
    {
        public string Name { get; init; } = string.Empty;
        public JsonSchemaType Type { get; init; } = new();
        public bool Required { get; init; } = false;
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
        Returns.GetString() == "void"
            ? null
            : JsonSerializer.Deserialize<JsonSchemaType>(Returns.GetRawText());
}
