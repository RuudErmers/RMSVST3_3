unit UVST3Instrument;

interface

uses Forms,UVSTBase,UVST3InstrumentBase;

type TVST3Instrument = class(TVST3InstrumentBase)
(* call to Host *)
//  procedure UpdateHostParameter(id:integer;value:double);
//  procedure MidiOut(byte0, byte1, byte2: integer);
//  procedure MidiEventToProcessor(byte0, byte1, byte2: integer);
//  procedure doProgramChange(prgm:integer);
(* called From Host *)
public
  procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);virtual;
  procedure UpdateProcessorParameter(id: integer; value: double);virtual;
  procedure OnInitialize;virtual;
  procedure OnMidiEvent(processor:boolean;byte0, byte1, byte2: integer);virtual;
  procedure OnEditOpen;override;
  procedure OnEditClose;virtual;
  procedure OnEditIdle;virtual;
  procedure OnProgramChange(prgm: integer);virtual;
  procedure UpdateControllerParameter(id:integer;value:double);virtual;
  procedure SetParameters(AddParameter:TonAddParameter);virtual;
end;

implementation

{ TVST3Instrument }

procedure TVST3Instrument.SetParameters(AddParameter:TonAddParameter);
begin
// virtual
end;

procedure TVST3Instrument.OnEditClose;
begin
// virtual
end;

procedure TVST3Instrument.OnEditIdle;
begin
// virtual
end;

procedure TVST3Instrument.OnEditOpen;
begin
// virtual
end;

procedure TVST3Instrument.OnInitialize;
begin
// virtual
end;

procedure TVST3Instrument.OnMidiEvent(processor:boolean;byte0, byte1, byte2: integer);
begin
// virtual
end;

procedure TVST3Instrument.OnProgramChange(prgm: integer);
begin
// virtual
end;

procedure TVST3Instrument.Process32(samples, channels: integer; inputp,
  outputp: PPSingle);
begin
// virtual
end;

procedure TVST3Instrument.UpdateControllerParameter(id: integer; value: double);
begin
// virtual
end;

procedure TVST3Instrument.UpdateProcessorParameter(id: integer; value: double);
begin
// virtual
end;

end.
