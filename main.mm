#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern "C" const char *xamarin_icu_dat_file_name;

static void xamarin_initialize_dotnet ()
{
        xamarin_icu_dat_file_name = "";
}

extern "C" void xamarin_initialize_dotnet();
// extern "C" void xamarin_create_classes_Microsoft_macOS();

static void xamarin_invoke_registration_methods ()
{
        xamarin_initialize_dotnet();
        // xamarin_create_classes_Microsoft_macOS();
}

#include "xamarin/xamarin.h"

void xamarin_register_modules_impl ()
{
}

void xamarin_register_assemblies_impl ()
{
}

static const char *xamarin_runtime_libraries_array[] = {
        // "libSystem.Globalization.Native",
        // "libSystem.IO.Compression.Native",
        // "libSystem.Native",
        // "libSystem.Net.Security.Native",
        // "libSystem.Security.Cryptography.Native.Apple",
        // "libSystem.Security.Cryptography.Native.OpenSsl",
        // "libclrgc",
        // "libclrjit",
        // "libcoreclr",
        // "libhostfxr",
        // "libhostpolicy",
        // "libmscordaccore",
        // "libmscordbi",
        NULL
};

void xamarin_setup_impl ()
{
        xamarin_invoke_registration_methods ();
        xamarin_libmono_native_link_mode = XamarinNativeLinkModeDynamicLibrary;
        xamarin_runtime_libraries = xamarin_runtime_libraries_array;
        // xamarin_gc_pump = FALSE;
        xamarin_init_mono_debug = TRUE;
        xamarin_executable_name = "second_macos_test.dll";
        xamarin_log_level = 0;
        xamarin_arch_name = "arm64";
        xamarin_marshal_objectivec_exception_mode = MarshalObjectiveCExceptionModeThrowManagedException;
        xamarin_debug_mode = TRUE;
        setenv ("MONO_GC_PARAMS", "major=marksweep", 1);
        xamarin_supports_dynamic_registration = TRUE;
        xamarin_runtime_configuration_name = "runtimeconfig.bin";
}

int main (int argc, char **argv)
{
        puts("austin's custom main");
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        int rv = xamarin_main (argc, argv, XamarinLaunchModeApp);
        [pool drain];
        return rv;
}

void xamarin_initialize_callbacks () __attribute__ ((constructor));
void xamarin_initialize_callbacks ()
{
        xamarin_setup = xamarin_setup_impl;
        xamarin_register_assemblies = xamarin_register_assemblies_impl;
        xamarin_register_modules = xamarin_register_modules_impl;
}

// ----------------------------------------- NativeAOT bootstrap


extern void * __modules_a[] __asm("section$start$__DATA$__modules");
extern void * __modules_z[] __asm("section$end$__DATA$__modules");
extern char __managedcode_a __asm("section$start$__TEXT$__managedcode");
extern char __managedcode_z __asm("section$end$__TEXT$__managedcode");
extern char __unbox_a __asm("section$start$__TEXT$__unbox");
extern char __unbox_z __asm("section$end$__TEXT$__unbox");

extern "C" bool RhInitialize();
extern "C" void RhpShutdown();
extern "C" void RhSetRuntimeInitializationCallback(int (*fPtr)());

extern "C" bool RhRegisterOSModule(void * pModule,
    void * pvManagedCodeStartRange, uint32_t cbManagedCodeRange,
    void * pvUnboxingStubsStartRange, uint32_t cbUnboxingStubsRange,
    void ** pClasslibFunctions, uint32_t nClasslibFunctions);

extern "C" void* PalGetModuleHandleFromPointer(void* pointer);

extern "C" void GetRuntimeException();
extern "C" void FailFast();
extern "C" void AppendExceptionStackFrame();
extern "C" void GetSystemArrayEEType();
extern "C" void OnFirstChanceException();
extern "C" void OnUnhandledException();
extern "C" void IDynamicCastableIsInterfaceImplemented();
extern "C" void IDynamicCastableGetInterfaceImplementation();

typedef void(*pfn)();

static const pfn c_classlibFunctions[] = {
    &GetRuntimeException,
    &FailFast,
    nullptr, // &UnhandledExceptionHandler,
    &AppendExceptionStackFrame,
    nullptr, // &CheckStaticClassConstruction,
    &GetSystemArrayEEType,
    &OnFirstChanceException,
    &OnUnhandledException,
    &IDynamicCastableIsInterfaceImplemented,
    &IDynamicCastableGetInterfaceImplementation,
};

#ifndef _countof
#define _countof(_array) (sizeof(_array)/sizeof(_array[0]))
#endif

extern "C" void InitializeModules(void* osModule, void ** modules, int count, void ** pClasslibFunctions, int nClasslibFunctions);

#define NATIVEAOT_ENTRYPOINT __managed__Main
extern "C" int __managed__Main(int argc, char* argv[]);
extern "C" void __managed__Startup();

static int InitializeRuntime()
{
    if (!RhInitialize())
        return -1;

    void * osModule = PalGetModuleHandleFromPointer((void*)&NATIVEAOT_ENTRYPOINT);

    // TODO: pass struct with parameters instead of the large signature of RhRegisterOSModule
    if (!RhRegisterOSModule(
        osModule,
        (void*)&__managedcode_a, (uint32_t)((char *)&__managedcode_z - (char*)&__managedcode_a),
        (void*)&__unbox_a, (uint32_t)((char *)&__unbox_z - (char*)&__unbox_a),
        (void **)&c_classlibFunctions, _countof(c_classlibFunctions)))
    {
        return -1;
    }

    InitializeModules(osModule, __modules_a, (int)((__modules_z - __modules_a)), (void **)&c_classlibFunctions, _countof(c_classlibFunctions));

    // Run startup method immediately for a native library
    __managed__Startup();

    return 0;
}


// ----------------------------------------- coreclr compatability APIs

// TODO: figure out where to get these macros
#define S_OK  0x0
#define E_FAIL 0x80004005

#ifdef _MSC_VER
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT __attribute__((visibility("default")))
#endif

extern "C"
DLLEXPORT
int coreclr_initialize(
            const char* exePath,
            const char* appDomainFriendlyName,
            int propertyCount,
            const char** propertyKeys,
            const char** propertyValues,
            void** hostHandle,
            unsigned int* domainId)
{
    // TODO: validate arguments
    // TODO: check that this function is called only once.
    int rc = InitializeRuntime();
    printf("InitializeRuntime called, return %d\n", rc);
    if (rc == 0)
    {
        *hostHandle = nullptr;
        *domainId = 1;
        return S_OK;
    }
    else
    {
        return E_FAIL;
    }
}

extern "C"
DLLEXPORT
int coreclr_shutdown(
            void* hostHandle,
            unsigned int domainId)
{
    // TODO: validate arguments
    // TODO: check that this function is called only once.
    RhpShutdown();
    return S_OK;
}


extern "C"
DLLEXPORT
int coreclr_execute_assembly(
            void* hostHandle,
            unsigned int domainId,
            int argc,
            const char** argv,
            const char* managedAssemblyPath,
            unsigned int* exitCode)
{
    if (exitCode == nullptr)
    {
        return E_FAIL;
    }

    // TODO: validate other arguments

    // NativeAOT does not like having argc == 0
    if (argc == 0)
    {
        argc = 1;
        const char* arg_0 = "exe";
        argv = &arg_0;
    }

    // TODO: convert to WSTR for windows
    *exitCode = __managed__Main(argc, const_cast<char**>(argv));

    return S_OK;
}


extern "C" void AustinXamarinRuntimeInitialize(void* options);

extern "C"
DLLEXPORT
int coreclr_create_delegate(
            void* hostHandle,
            unsigned int domainId,
            const char* entryPointAssemblyName,
            const char* entryPointTypeName,
            const char* entryPointMethodName,
            void** delegate)
{
    // TODO: validate args more carefully
    if (strcmp(entryPointTypeName, "ObjCRuntime.Runtime") == 0 &&
        strcmp(entryPointMethodName, "Initialize") == 0)
    {
        *delegate = (void*)AustinXamarinRuntimeInitialize;
        return S_OK;
    }
    else
    {
        printf("coreclr_create_delegate: expected request, type: %s method: %s\n", entryPointTypeName, entryPointMethodName);
    }

    return E_FAIL;
}
