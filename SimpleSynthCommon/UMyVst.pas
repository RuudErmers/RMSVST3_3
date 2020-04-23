unit UMyVst;

interface

uses Forms, Classes,UVSTBase,UMyVSTDSP,UVST3Instrument,UVST3InstrumentBase;

const ID_CUTOFF = 17;
const ID_RESONANCE = 18;
const ID_PULSEWIDTH = 19;

type TMyVSTPlugin = class (TVST3Instrument)
private
  FSimpleSynth:TSimpleSynth;
  procedure DoUpdateHostParameter(id: integer; value: double);   // called from UI
  procedure doKeyEvent(key: integer; _on: boolean);              // called from UI
public
  procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);override;
  procedure UpdateProcessorParameter(id:integer;value:double);override;
  procedure OnInitialize;override;
  procedure OnMidiEvent(processor:boolean;byte0, byte1, byte2: integer);override;
  procedure SetParameters(AddParameter:TonAddParameter);override;
  procedure UpdateControllerParameter(id:integer;value:double);override;
  procedure OnEditOpen;override;
  procedure OnProgramChange(prgm:integer);override;
public
end;

function GetVSTInstrumentInfo:TVSTInstrumentInfo;
implementation

{ TmyVST }

uses UMyVSTForm,SysUtils,Windows,UCodeSiteLogger;

const MIDI_NOTE_ON = $90;
      MIDI_NOTE_OFF = $80;
      MIDI_CC = $B0;

{$POINTERMATH ON}
{$define DebugLog}

procedure TMyVSTPlugin.UpdateProcessorParameter(id:integer;value:double);
begin
  FSimpleSynth.UpdateParameter(id,value);
end;

procedure TMyVSTPlugin.Process32(samples, channels: integer; inputp, outputp: PPSingle);
VAR i,channel:integer;
    sample:single;
begin
  for i:=0 to samples-1 do
  begin
    sample:=FSimpleSynth.process;
    for channel:=0 to 1 do
      outputp[channel][i]:=sample;
  end;
end;

procedure TMyVSTPlugin.SetParameters(AddParameter:TonAddParameter);
begin
  AddParameter(ID_CUTOFF,'Cutoff','Cutoff','Hz',20,20000,10000,74);
  AddParameter(ID_RESONANCE,'Resonance','Resonance','',0,1,0);
  AddParameter(ID_PULSEWIDTH,'Pulse Width','PWM','%',0,100,50);
end;

procedure TMyVSTPlugin.OnInitialize;
begin
  FSimpleSynth:=TSimpleSynth.Create(44100);
end;


procedure TMyVSTPlugin.OnMidiEvent(processor:boolean;byte0, byte1, byte2: integer);
VAR status:integer;
begin
//  WriteLog('TMyVSTPlugin.OnMidiEvent:'+byte0.ToString+' '+byte1.ToString+' '+byte2.ToString);
  status:=byte0 and $F0;
  if processor then
  begin
    if status=MIDI_NOTE_ON then FSimpleSynth.OnKeyEvent(byte1,byte2>0)
    else if status=MIDI_NOTE_OFF then FSimpleSynth.OnKeyEvent(byte1,false)
  end
  else
  begin
    if status=MIDI_NOTE_ON then TFormMyVST(EditorForm).SetKey(byte1,byte2>0)
    else if status=MIDI_NOTE_OFF then TFormMyVST(EditorForm).SetKey(byte1,false)
  end;
end;
//////////////////////////////////////////////////////////////////////////////////////

procedure TMyVSTPlugin.OnProgramChange(prgm: integer);
begin
  if EditorForm<>NIL then
    TFormMyVST(EditorForm).SetProgram(prgm);
end;

procedure TMyVSTPlugin.OnEditOpen;
begin
  TFormMyVST(EditorForm).HostUpdateParameter:=DoUpdateHostParameter;
  TFormMyVST(EditorForm).HostKeyEvent:=DoKeyEvent;
  TFormMyVST(EditorForm).HostPrgmChange:=DoProgramChange;
end;

procedure TMyVSTPlugin.doKeyEvent(key:integer;_on:boolean); // from UI
begin
  MidiEventToProcessor(MIDI_NOTE_ON,key,127*ord(_on));
end;

procedure TMyVSTPlugin.DoUpdateHostParameter(id: integer; value: double); // from UI
const MIDI_CC = $B0;
begin
  UpdateHostParameter(id,value);
  MidiOut(MIDI_CC,id,round(127*value));   // just a test
end;

procedure TMyVSTPlugin.UpdateControllerParameter(id: integer;  value: double);
begin
  TFormMyVST(EditorForm).UpdateParameter(id,value);
end;

const UID_CProcessorMyVSTPlugin: TGUID =  '{2408CBE0-9085-4BE6-8EAB-9D6750713886}';
const UID_CControllerMyVSTPlugin: TGUID = '{6A539E2E-192E-4CD2-8698-05949855ABC7}';
function GetVSTInstrumentInfo:TVSTInstrumentInfo;
begin
  with result do
  begin
    with PluginDef do
    begin
      vst3processorid    := UID_CProcessorMyVSTPlugin;
      vst3controllerid   := UID_CControllerMyVSTPlugin;
      vst3instrumentclass:= TMyVSTPlugin;
      name               := 'SimpleSynth5';
      vst3editorclass    := TFormMyVST;
      isSynth:=true;
    end;
    with factoryDef do
    begin
      vendor:='Ermers Consultancy';
      url:='www.ermers.org';
      email:='ruud@ermers.org';
    end;
  end;
end;

end.
