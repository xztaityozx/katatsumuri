using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Katatsumuri.Result;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using NJsonSchema;
using NJsonSchema.CodeGeneration.CSharp;

namespace Katatsumuri.CodeGeneration
{
    public record Csharp(FileInfo PackageSchemaFile)
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
            };

            var schema = await JsonSchema.FromJsonAsync(package.Schema.GetRawText());

            var csharpGenerator = new CSharpGenerator(schema, csharpGeneratorSetting);
            var file = csharpGenerator.GenerateFile() ?? throw new FileNotFoundException();
            using var reader = new StringReader(file);
            var syntaxTree = CSharpSyntaxTree.ParseText(await reader.ReadToEndAsync());
            return syntaxTree;
        }
    }
}
