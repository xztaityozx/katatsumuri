using Katatsumuri.CodeGeneration;

var packageSchemaFile = new FileInfo(@"./schema.json");

var csharp = new CSharp(packageSchemaFile);
var syntaxTree = await csharp.BuildAsync();

await using var writer = new StreamWriter(@"./out.cs");
syntaxTree.WriteTo(writer);
