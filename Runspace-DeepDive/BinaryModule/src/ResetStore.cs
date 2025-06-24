using System.Management.Automation;

namespace BinaryModule;

[Cmdlet(VerbsCommon.Reset, "AllStores")]
public sealed class ResetStaticStore : PSCmdlet
{
    protected override void EndProcessing()
    {
        StaticStore.StaticField = StaticStore._default;
        RunspaceStore.GetFromRunspace().RunspaceField = RunspaceStore._default;
        ThreadLocalStore.TLSField = ThreadLocalStore._default;
    }
}
