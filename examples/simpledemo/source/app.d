import std.stdio;
import std.algorithm;
import std.range.primitives : empty;
import core.thread;

import dwin32midi;

private const MIDI_DEVICE_NAME = "Impact LX25+";

void main()
{
	auto all_inputs = enumerateDevices();
	foreach (input; all_inputs) {
		writefln("device %s (%s)", input.name, input.id);
	}

	auto which = find!"a.name == b"(all_inputs, MIDI_DEVICE_NAME);
	if (which.empty()) {
		writeln("couldn't find desired device :(");
		return;
	}

	auto input = new MidiInputDevice(which[0].id);
	if (input.openQueue()) {
		if (input.start()) {
			for (int i; i< 100; i++) {
				auto events = input.read();
				foreach (event; events) {
					writefln("%08X @ %4d", event.data.uint32, event.relTime);
				}
				Thread.sleep(100.msecs);
				writeln(".");
			}
			input.stop();
		}
		input.close();
	}
}
