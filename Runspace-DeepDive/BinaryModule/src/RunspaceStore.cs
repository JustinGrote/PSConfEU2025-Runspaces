using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Runtime.CompilerServices;
using System.Threading;

namespace BinaryModule;

internal class RunspaceSpecificStore<T>
{
    private readonly ConditionalWeakTable<Runspace, Lazy<T>> _map = new();

    private readonly Func<T> _factory;

    private readonly LazyThreadSafetyMode _mode = LazyThreadSafetyMode.ExecutionAndPublication;

    public RunspaceSpecificStore(Func<T> factory)
    {
        _factory = factory;
    }

    public T GetFromRunspace()
        => GetForRunspace(Runspace.DefaultRunspace);

    public T GetForRunspace(Runspace runspace)
    {
        return _map.GetValue(
            runspace,
            _ => new Lazy<T>(() => _factory(), _mode))
            .Value;
    }
}

internal class RunspaceStore
{
    internal const string _default = "RunspaceStoreDefault";

    private static RunspaceSpecificStore<RunspaceStore> _registrations = new(() => new());
    public static RunspaceStore GetFromRunspace() => _registrations.GetFromRunspace();

    public string RunspaceField = _default;
}

[Cmdlet(VerbsCommon.Get, nameof(RunspaceStore))]
[OutputType(typeof(string))]
public sealed class GetRunspaceStore : PSCmdlet
{
    protected override void EndProcessing()
    {
        WriteObject(RunspaceStore.GetFromRunspace().RunspaceField);
    }
}

[Cmdlet(VerbsCommon.Set, nameof(RunspaceStore))]
public sealed class SetRunspaceStore : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0)]
    public string Value { get; set; } = "";

    protected override void EndProcessing()
    {
        RunspaceStore.GetFromRunspace().RunspaceField = Value;
    }
}
