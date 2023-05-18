using System.Data;
using System.Text.Json;
using Katatsumuri.CodeGeneration;
using Katatsumuri.Result;

var packageSchemaFile = new FileInfo(@"./schema.json");
var csharp = new Csharp(packageSchemaFile);
var syntaxTree = await csharp.BuildAsync();

Console.WriteLine(syntaxTree.ToString());
