using Katatsumuri.Result;
using Newtonsoft.Json;
using Newtonsoft.Json.Schema.Generation;
using Newtonsoft.Json.Serialization;

var generator = new JSchemaGenerator { ContractResolver = new ArgumentDefaultResolver() };

var schema = generator.Generate(typeof(Package));

using var writer = new StreamWriter("schema.json");
schema.WriteTo(new JsonTextWriter(writer));

internal class ArgumentDefaultResolver : DefaultContractResolver
{
    protected override JsonContract CreateContract(Type objectType)
    {
        var contract = base.CreateContract(objectType);

        if (contract is not JsonObjectContract objectContract)
            return contract;
        var prop = objectContract.Properties.FirstOrDefault(
            p =>
                p.PropertyName
                    is nameof(Method.Argument.ArgumentDefault.Value)
                        or nameof(Property.Default)
        );
        if (prop is not null)
            prop.PropertyType = typeof(string);

        return contract;
    }
}
