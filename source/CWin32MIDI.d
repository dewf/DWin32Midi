// The following ifdef block is the standard way of creating macros which make exporting 

import core.stdc.config;

extern (C):

// from a DLL simpler. All files within this DLL are compiled with the CWIN32MIDI_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// CWIN32MIDI_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.

struct _CWin32Midi_DeviceID;
alias CWin32Midi_DeviceID = _CWin32Midi_DeviceID*;
struct _CWin32Midi_Device;
alias CWin32Midi_Device = _CWin32Midi_Device*;

enum CWin32Midi_EventType
{
    Log = 0,
    Data = 1
}

struct CWin32Midi_Event
{
    CWin32Midi_EventType eventType;
    bool handled;

    struct _Anonymous_0
    {
        const(char)* message;
    }

    _Anonymous_0 logEvent;

    struct _Anonymous_1
    {
        union
        {
            ubyte[4] bytes;
            uint uint32;
        }
    }

    _Anonymous_1 dataEvent;
}

alias CWin32Midi_EventCallback = int function (CWin32Midi_Event* event, CWin32Midi_Device device, void* userData);

int CWin32Midi_Init (CWin32Midi_EventCallback callback);
int CWin32Midi_Shutdown ();

struct CWin32Midi_DeviceInfo
{
    CWin32Midi_DeviceID id;
    bool isInput; // else output
    const(char)* name;
}

int CWin32Midi_EnumerateInputs (CWin32Midi_DeviceInfo** infos, int* count);

enum CWin32Midi_InputMode
{
    Callback = 0,
    Queue = 1
}

int CWin32Midi_OpenInput (CWin32Midi_DeviceID id, void* userData, CWin32Midi_InputMode inputMode, CWin32Midi_Device* outHandle);
int CWin32Midi_CloseInput (CWin32Midi_Device handle);

int CWin32Midi_Start (CWin32Midi_Device handle);
int CWin32Midi_Stop (CWin32Midi_Device handle);

struct CWin32Midi_MidiMsg
{
    uint relTime; // from last read time (or start)
    union _Anonymous_2
    {
        ubyte[4] bytes;
        uint uint32;
    }

    _Anonymous_2 data;
}

int CWin32Midi_ReadInput (CWin32Midi_Device handle, CWin32Midi_MidiMsg* dest, int destSize, int* numRead);

