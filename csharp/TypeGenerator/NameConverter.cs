using System;
using System.Collections.Generic;
using System.Linq;

namespace Katatsumuri;

public static class NameConverter
{
    /// <summary>
    /// snake_caseをlowerCamelCaseにして返す
    /// </summary>
    /// <param name="snakeCaseString"></param>
    /// <returns></returns>
    public static string ToLowerCamelCase(this string snakeCaseString)
    {
        if (string.IsNullOrEmpty(snakeCaseString))
            return snakeCaseString;

        var words = snakeCaseString.Split('_', StringSplitOptions.RemoveEmptyEntries);
        return words[1..].Aggregate(
            char.ToLower(words[0][0]) + words[0][1..],
            (current, t) => current + char.ToUpper(t[0]) + t[1..]
        );
    }

    /// <summary>
    /// snake_caseをUpperCamelCaseにして返す
    /// </summary>
    /// <param name="snakeCaseString"></param>
    /// <returns></returns>
    public static string ToUpperCamelCase(this string snakeCaseString)
    {
        if (string.IsNullOrEmpty(snakeCaseString))
            return snakeCaseString;

        var words = snakeCaseString.Split('_', StringSplitOptions.RemoveEmptyEntries);
        return words.Aggregate("", (current, t) => current + char.ToUpper(t[0]) + t[1..]);
    }
}
