using System.Collections;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace Katatsumuri.Result;

public record TypeConstraint(string Type, string? SubType = null, IEnumerable<string>? Union = null)
{
    /// <summary>
    /// UnionからTypeSyntaxをつくる。でもUnion型なんてないから、Unionのメンバーが2個以上ならobjectを返す
    /// 一つしかないならその型を返す。
    /// Unionがnullならobjectを返す
    /// </summary>
    /// <returns></returns>
    private TypeSyntax BuildUnionTypeSyntax()
    {
        if (Union is null)
            return new TypeConstraint("object").GetTypeSyntax();

        return Union.Distinct().Count() == 1
            ? new TypeConstraint(Union.First()).GetTypeSyntax()
            : new TypeConstraint("object").GetTypeSyntax();
    }

    /// <summary>
    /// Typeがarrayの時に型パラメーターを決定してそのTypeSyntaxを返す
    /// </summary>
    /// <returns></returns>
    private TypeSyntax BuildIEnumerableTypeSyntax()
    {
        var subType = SyntaxFactory.TypeArgumentList();
        if (SubType is null && Union is null)
        {
            subType = subType.AddArguments(new TypeConstraint("object").GetTypeSyntax());
        }
        else if (SubType is not null)
        {
            subType = subType.AddArguments(new TypeConstraint(SubType).GetTypeSyntax());
        }
        else if (Union is not null)
        {
            subType = subType.AddArguments(BuildUnionTypeSyntax());
        }

        return SyntaxFactory.GenericName(SyntaxFactory.Identifier(nameof(IEnumerable)), subType);
    }

    public TypeSyntax GetTypeSyntax()
    {
        return Type switch
        {
            "integer"
            or "hex"
            or "octal"
            or "exp"
            or "binary"
                => SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.IntKeyword)),
            "string" => SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.StringKeyword)),
            "decimal"
                => SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.DecimalKeyword)),
            "array" => BuildIEnumerableTypeSyntax(),
            "object"
            or "any"
                => SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.ObjectKeyword)),
            "bool" => SyntaxFactory.PredefinedType(SyntaxFactory.Token(SyntaxKind.BoolKeyword)),
            "union" => BuildUnionTypeSyntax(),
            // 上のどれにも当てはまらないときは独自の型
            // Perlは::でネームスペースを区切るのでC#流に書き換えてからパースさせる
            _ => SyntaxFactory.ParseTypeName(Type.Replace("::", ".")),
        };
    }

    public bool IsUnion => Type == "union";
}
