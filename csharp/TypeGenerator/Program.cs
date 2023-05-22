using System.Text.Json;
using Katatsumuri.CodeGeneration;
using Katatsumuri.Result;

var packageSchemaFile = new FileInfo(@"./schema.json");

var csharp = new CSharp(packageSchemaFile);
var syntaxTree = await csharp.BuildAsync();

Console.WriteLine(syntaxTree.ToString());
