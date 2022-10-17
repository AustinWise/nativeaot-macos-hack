
This is not really usable anywhere by my computer currently. There are some hard-coded paths in the
csproj and nuget.config file.

Additionally I was not able to figure out how to override the `dotnet workload` with a custom
workload, so I overwrote files in `/usr/local/share/dotnet/packs` with my compiled
`Microsoft.macOS.dll` and `libxamarin-dotnet-coreclr.a` files.


This has to be used with the follow forks:

* https://github.com/AustinWise/runtime/tree/austin/NativeAotObjectiveCMarshal
* https://github.com/AustinWise/xamarin-macios/tree/austin/NativeAOT
