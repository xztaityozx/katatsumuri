using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;

namespace Katatsumuri.Result;

public record Package(
    string FileName,
    string Name,
    IEnumerable<string> Namespace,
    IEnumerable<string> SuperClasses,
    IEnumerable<Method> Methods,
    IEnumerable<Property> Properties
)
{
    public string FullName =>
        string.Join(".", Namespace.Concat(new[] { Name }).Select(NameConverter.ToUpperCamelCase));

    public SyntaxTree BuildClassSyntaxTree()
    {
        var classDeclaration = SyntaxFactory
            .ClassDeclaration(Name.ToUpperCamelCase())
            .WithModifiers(SyntaxTokenList.Create(SyntaxFactory.Token(SyntaxKind.PublicKeyword)));

        classDeclaration = Methods
            .Select(method => method.BuildMethodSyntax())
            .Aggregate(
                classDeclaration,
                (current, methodSyntax) => current.AddMembers(methodSyntax)
            );

        classDeclaration = Properties
            .Select(p => p.BuildDeclarationSyntax())
            .Aggregate(
                classDeclaration,
                (current, propertySyntax) => current.AddMembers(propertySyntax)
            );

        var namespaceDeclaration = SyntaxFactory
            .NamespaceDeclaration(
                SyntaxFactory.ParseName(
                    string.Join(".", Namespace.Select(NameConverter.ToUpperCamelCase))
                )
            )
            .AddMembers(classDeclaration);

        var compilationUnit = SyntaxFactory
            .CompilationUnit()
            .AddUsings(SyntaxFactory.UsingDirective(SyntaxFactory.ParseName("System")))
            .AddMembers(namespaceDeclaration)
            .WithLeadingTrivia(
                SyntaxFactory.TriviaList(SyntaxFactory.Comment($"// generated from {FileName}"))
            );

        return compilationUnit.SyntaxTree;
    }
}
