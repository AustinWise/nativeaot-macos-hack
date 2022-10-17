using ObjCRuntime;

namespace test_mac_dotnet;

public partial class ViewController : NSViewController
{
    protected ViewController(NativeHandle handle) : base(handle)
    {
    }

    public override void ViewDidLoad()
    {
        base.ViewDidLoad();

        // Do any additional setup after loading the view.
    }

    public override void ViewWillAppear()
    {
        base.ViewWillAppear();
		this.View.Window.Title = "Hello from NativeAOT";
    }

    public override NSObject RepresentedObject
    {
        get => base.RepresentedObject;
        set
        {
            base.RepresentedObject = value;

            // Update the view, if already loaded.
        }
    }
}
