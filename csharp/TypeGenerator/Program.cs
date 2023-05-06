// See https://aka.ms/new-console-template for more information

using System.Data;
using System.Text.Json;
using System.Text.Json.Serialization;
using Katatsumuri.Result;
using Microsoft.CodeAnalysis;

var jsonFile = @"./out.json";

using var fileStream = new StreamReader(jsonFile);
var package =
    JsonSerializer.Deserialize<Package>(
        fileStream.BaseStream,
        new JsonSerializerOptions
        {
            Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) }
        }
    ) ?? throw new NoNullAllowedException();

var tree = package.BuildClassSyntaxTree().GetRoot().NormalizeWhitespace();

using var textWriter = new StreamWriter("./out.cs");
tree.WriteTo(textWriter);
