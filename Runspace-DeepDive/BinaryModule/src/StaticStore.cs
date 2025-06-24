using System.Management.Automation;

namespace BinaryModule;

internal static class StaticStore
{
    internal const string _default = "StaticStoreDefault";

    public static string StaticField = _default;
}

[Cmdlet(VerbsCommon.Get, nameof(StaticStore))]
[OutputType(typeof(string))]
public sealed class GetStaticStore : PSCmdlet
{
    protected override void EndProcessing()
    {
        WriteObject(StaticStore.StaticField);
    }
}

[Cmdlet(VerbsCommon.Set, nameof(StaticStore))]
public sealed class SetStaticStore : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0)]
    public string Value { get; set; } = "";

    protected override void EndProcessing()
    {
        StaticStore.StaticField = Value;
    }
}
