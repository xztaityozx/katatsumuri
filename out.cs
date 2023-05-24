#pragma warning disable // Disable all warnings

[System.CodeDom.Compiler.GeneratedCode("NJsonSchema", "10.9.0.0 (Newtonsoft.Json v9.0.0.0)")]
public partial class B
{
    /// <summary>
    /// original Perl type: Int
    /// </summary>
    [System.Text.Json.Serialization.JsonPropertyName("age")]
    [System.Text.Json.Serialization.JsonIgnore(Condition = System.Text.Json.Serialization.JsonIgnoreCondition.Never)]
    public int Age { get; set; }

    /// <summary>
    /// original Perl type: Dict[age=&gt;Int,name=&gt;Str]
    /// </summary>
    [System.Text.Json.Serialization.JsonPropertyName("dict")]
    [System.Text.Json.Serialization.JsonIgnore(Condition = System.Text.Json.Serialization.JsonIgnoreCondition.Never)]
    public Dict Dict { get; set; } = new Dict();

    /// <summary>
    /// original Perl type: Str
    /// </summary>
    [System.Text.Json.Serialization.JsonPropertyName("name")]
    [System.Text.Json.Serialization.JsonIgnore(Condition = System.Text.Json.Serialization.JsonIgnoreCondition.Never)]
    public string Name { get; set; } = "this is name";

    /// <summary>
    /// original Perl type: Str|Int
    /// </summary>
    [System.Text.Json.Serialization.JsonPropertyName("union")]
    [System.Text.Json.Serialization.JsonIgnore(Condition = System.Text.Json.Serialization.JsonIgnoreCondition.Never)]
    public Union Union { get; set; }

    private System.Collections.Generic.IDictionary<string, object> _additionalProperties;
    [System.Text.Json.Serialization.JsonExtensionData]
    public System.Collections.Generic.IDictionary<string, object> AdditionalProperties
    {
        get
        {
            return _additionalProperties ?? (_additionalProperties = new System.Collections.Generic.Dictionary<string, object>());
        }

        set
        {
            _additionalProperties = value;
        }
    }

    ///<summary></summary> 
    ///<returns></returns>
    public object a()
    {
        throw new NotImplementedException;
    }

    ///<summary></summary> 
    ///<param name = "str">original Perl type: Str</param> 
    ///<param name = "x">original Perl type: Any</param> 
    ///<param name = "y">original Perl type: Int</param> 
    ///<returns></returns>
    public object e(string str, object x, int y = 1)
    {
        throw new NotImplementedException;
    }

    ///<summary></summary> 
    ///<returns>original Perl type: Str, Int</returns>
    public object f()
    {
        throw new NotImplementedException;
    }

    ///<summary></summary> 
    ///<returns></returns>
    public void g()
    {
        throw new NotImplementedException;
    }

    ///<summary></summary> 
    ///<param name = "a">original Perl type: Any</param> 
    ///<returns></returns>
    public object h(object a)
    {
        throw new NotImplementedException;
    }

    ///<summary></summary> 
    ///<returns>original Perl type: Int</returns>
    public int b()
    {
        throw new NotImplementedException;
    }

    ///<summary></summary> 
    ///<returns>original Perl type: Int</returns>
    public int c()
    {
        throw new NotImplementedException;
    }

    ///<summary></summary> 
    ///<param name = "str">original Perl type: Str</param> 
    ///<param name = "x">original Perl type: Any</param> 
    ///<param name = "y">original Perl type: Int</param> 
    ///<returns></returns>
    public object d(string str, object x, int y)
    {
        throw new NotImplementedException;
    }
}