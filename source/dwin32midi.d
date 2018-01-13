import std.stdio;
import std.string;
import std.conv;

import CWin32Midi;

struct MidiDeviceInfo {
	CWin32Midi_DeviceID id;
	bool isInput;
	string name;
}

MidiDeviceInfo[] enumerateDevices() {
	CWin32Midi_DeviceInfo *infos;
	int count;
	if (CWin32Midi_EnumerateInputs(&infos, &count) != 0) {
		writeln("DWin32Midi: some error enumerating devices");
	}

	MidiDeviceInfo[] ret;
	foreach (info; infos[0..count]) {
		MidiDeviceInfo mdi = {info.id, info.isInput, to!string(info.name)};
		ret ~= mdi;
	}

	return ret;
}

alias MidiInputData = CWin32Midi_MidiMsg;

interface MidiInputDelegate {
	void dataEvent(MidiInputData data);
}

class MidiInputDevice
{
	private CWin32Midi_DeviceID id;
	private CWin32Midi_Device handle;
	private bool started;

	private MidiInputDelegate inputDelegate;

	this(CWin32Midi_DeviceID id) {
		this.id = id;
	}
	~this() {
		close();
	}

	private bool openCommon(CWin32Midi_InputMode inputMode) {
		if (CWin32Midi_OpenInput(id, cast(void *)this, inputMode, &handle) != 0) {
			writeln("failed to open MIDI device");
			handle = null;
			return false;
		}
		return true;
	}

	bool openQueue() {
		return openCommon(CWin32Midi_InputMode.Queue);
	}

	bool openCallback(MidiInputDelegate inputDelegate) {
		this.inputDelegate = inputDelegate;
		return openCommon(CWin32Midi_InputMode.Callback);
	}

	void close() {
		if (handle) {
			if (started) stop();
			CWin32Midi_CloseInput(handle);
			handle = null;
		}
	}

	bool start() {
		if (handle) {
			if (CWin32Midi_Start(handle) == 0) {
				started = true;
				return true;
			}
		}
		return false;
	}

	void stop() {
		if (handle && started) {
			CWin32Midi_Stop(handle);
			started = false;
		}
	}

	const MSG_BUFFER_SIZE = 4096;
	CWin32Midi_MidiMsg[MSG_BUFFER_SIZE] msgBuffer;

	MidiInputData[] read() {
		MidiInputData[] ret;

		int readCount = 0;
		do {
			CWin32Midi_ReadInput(handle, msgBuffer.ptr, MSG_BUFFER_SIZE, &readCount);
			ret ~= msgBuffer[0..readCount];
			// have to keep looping until the below condition is false
			// that's how we know the ReadInput internal reference time has reset
		} while(readCount >= MSG_BUFFER_SIZE);

		return ret;
	}
}

extern(C) int midiCallback(CWin32Midi_Event* event, CWin32Midi_Device device, void* userData)
{
	auto mid = cast(MidiInputDevice) userData;

	event.handled = true;
	switch(event.eventType) {
		case CWin32Midi_EventType.Log:
			// mid isn't necessarily valid here
			auto msg = to!string(event.logEvent.message);
			writefln("MIDI>> %s", msg);
			break;

		case CWin32Midi_EventType.Data:
			if (mid) {
				MidiInputData d;
				d.relTime = 0;
				d.data.uint32 = event.dataEvent.uint32;
				mid.inputDelegate.dataEvent(d);
			}
			break;

		default:
			event.handled = false;
	}
	return 0;
}

static this() {
	CWin32Midi_Init(&midiCallback);
}

static ~this() {
	CWin32Midi_Shutdown();
}

