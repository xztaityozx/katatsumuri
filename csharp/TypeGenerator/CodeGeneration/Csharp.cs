using System.Data;
using System.Text.Json;
using Katatsumuri.Result;
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
    public async Task<ClassDeclarationSyntax> BuildAsync()
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
        };

        var schema = await JsonSchema.FromJsonAsync(package.Schema.GetRawText());

        var csharpGenerator = new CSharpGenerator(schema, csharpGeneratorSetting);
        var file = csharpGenerator.GenerateFile() ?? throw new FileNotFoundException();
        using var reader = new StringReader(file);
        var syntaxTree = CSharpSyntaxTree.ParseText(await reader.ReadToEndAsync());
        var classWalker = new ClassWalker(package.Name);
        classWalker.Visit(await syntaxTree.GetRootAsync());

        var classDeclarationSyntax =
            classWalker.ClassDeclarationSyntax ?? throw new NoNullAllowedException();

        return package.Methods
            .Select(x => x.BuildMethodSyntaxDeclarationSyntax())
            .Aggregate(classDeclarationSyntax, (current, method) => current.AddMembers(method));
    }

    private sealed class ClassWalker : CSharpSyntaxWalker
    {
        private string ClassName { get; }
        public ClassDeclarationSyntax? ClassDeclarationSyntax { get; private set; }

        public ClassWalker(string className)
        {
            ClassName = className;
        }

        public override void VisitClassDeclaration(ClassDeclarationSyntax node)
        {
            if (node.Identifier.ValueText == ClassName)
            {
                ClassDeclarationSyntax = node;
            }
            base.VisitClassDeclaration(node);
        }
    }
}
