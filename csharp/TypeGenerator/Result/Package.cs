using System.Text.Json;

namespace Katatsumuri.Result;

public class Package
{
    public string Name { get; init; } = string.Empty;
    public IEnumerable<Method> Methods { get; init; } = Enumerable.Empty<Method>();
    public IEnumerable<string> Namespace { get; init; } = Enumerable.Empty<string>();
    public JsonElement Schema { get; init; } = default;
    public IEnumerable<string> SuperClasses { get; init; } = Enumerable.Empty<string>();
}
