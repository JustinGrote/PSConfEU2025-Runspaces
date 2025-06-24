using System;
using System.Management.Automation;

namespace BinaryModule;

internal static class ThreadLocalStore
{
    internal const string _default = "ThreadLocalStoreDefault";

    // A ThreadStatic field cannot have a default value so we use a property
    // to replicate the same behaviour when the field is null/unset.
    [ThreadStatic]
    public static string? _tlsField;

    public static string TLSField
    {
        get => _tlsField ??= _default;
        set => _tlsField = value;
    }
}

[Cmdlet(VerbsCommon.Get, nameof(ThreadLocalStore))]
[OutputType(typeof(string))]
public sealed class GetThreadLocalStore : PSCmdlet
{
    protected override void EndProcessing()
    {
        WriteObject(ThreadLocalStore.TLSField);
    }
}

[Cmdlet(VerbsCommon.Set, nameof(ThreadLocalStore))]
public sealed class SetThreadLocalStore : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0)]
    public string Value { get; set; } = "";

    protected override void EndProcessing()
    {
        ThreadLocalStore.TLSField = Value;
    }
}
