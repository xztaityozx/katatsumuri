using System.Data;
using System.Text.Json;
using Katatsumuri.Result;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using NJsonSchema;
using NJsonSchema.CodeGeneration.CSharp;

namespace Katatsumuri.CodeGeneration;

public record CSharp(FileInfo PackageSchemaFile)
{
    /// <summary>
    /// Packageのスキーマ情報を解析して、C#のコードを生成。そのシンタックスツリーを返す
    /// </summary>
    /// <returns></returns>
    public async Task<SyntaxTree> BuildAsync()
    {
        using var stream = new StreamReader(PackageSchemaFile.OpenRead());
        var package =
            JsonSerializer.Deserialize<Package>(
                await stream.ReadToEndAsync(),
                new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }
            ) ?? throw new NoNullAllowedException();

        var csharpGeneratorSetting = new CSharpGeneratorSettings
        {
            ClassStyle = CSharpClassStyle.Poco,
            GenerateDataAnnotations = false,
            GenerateJsonMethods = false,
            JsonLibrary = CSharpJsonLibrary.SystemTextJson,
            Namespace = string.Join(".", package.Namespace),
            ArrayType = "IEnumerable"
        };
        var schema = await JsonSchema.FromJsonAsync(package.Schema.GetRawText());
        var csharpGenerator = new CSharpGenerator(schema, csharpGeneratorSetting);
        var file = csharpGenerator.GenerateFile() ?? throw new FileNotFoundException();

        using var reader = new StringReader(file);
        var syntaxTree = CSharpSyntaxTree.ParseText(await reader.ReadToEndAsync());
        var root = await syntaxTree.GetRootAsync();
        var targetClassDeclarationSyntax =
            root.DescendantNodes()
                .OfType<ClassDeclarationSyntax>()
                .FirstOrDefault(syntax => syntax.Identifier.ValueText == package.Name)
            ?? throw new NoNullAllowedException($"{package.Name} が見つかりませんでした");

        var newClassDeclarationSyntax = package.Methods
            .Select(method => method.BuildMethodDeclarationSyntax())
            .Aggregate(
                targetClassDeclarationSyntax,
                (current, method) => current.AddMembers(method)
            );

        var newRoot = root.ReplaceNode(targetClassDeclarationSyntax, newClassDeclarationSyntax);
        return syntaxTree.WithRootAndOptions(newRoot, syntaxTree.Options);
    }
}
