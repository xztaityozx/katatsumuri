using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace Katatsumuri;

internal static class XmlTextSyntaxFactory
{
    // 改行を足すだけなのになんでこんなに書かなあかんねん...
    public static XmlTextSyntax NewLine() =>
        SyntaxFactory
            .XmlText()
            .WithTextTokens(
                SyntaxFactory.TokenList(
                    SyntaxFactory.XmlTextNewLine(
                        SyntaxFactory.TriviaList(),
                        Environment.NewLine,
                        Environment.NewLine,
                        SyntaxFactory.TriviaList()
                    )
                )
            );
}
