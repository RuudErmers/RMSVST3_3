unit UVST3Processor;

interface

uses UVSTBase, Vst3Base, UVst3Utils,Generics.Collections,SysUtils,UVST3Instrument;

type
     IVST3Processor = interface(IVSTBase)
        procedure OnSysexEvent(s:string);
        procedure MidiEvent(fromQueue:boolean;byte0,byte1,byte2:integer);
        procedure ProcessorParameterSetValue(id:integer;value:double);
        procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);
        procedure SamplerateChanged(samplerate:single);
        procedure TempoChanged(tempo:single);
        procedure PlayStateChanged(playing:boolean;ppq:integer);
        function GetMidiOutputEvents:TArray<integer>;
        function GetState:string;
        procedure SetState(state:string);
        procedure SetActive(active:boolean);
//        procedure Initialize;
        procedure ProcessorTerminate;
     end;
     TVST3ProcessorBase = class(TVSTBase,IVST3Processor)
      private
        Factive:boolean;
        Fparameters:TVST3ParameterArray;
        FMidiOutQueue:TQueue<integer>;

        function FVST3Instrument:TVST3Instrument;

        function GetState:string;
        procedure SetState(state:string);
        procedure SetActive(active:boolean);
        procedure MidiEvent(fromQueue:boolean;byte0,byte1,byte2:integer);
        procedure MidiEventToController(byte0, byte1, byte2: integer);
        procedure SendMessageToController(msg:TBytes);
      protected
        procedure Initialize;override;
        procedure ReceiveMessage(msg:TBytes);override;
        procedure MidiOut(byte0, byte1, byte2: integer);
        procedure OnInitialize;
        procedure SetParameters(params:TVST3ParameterArray);
        procedure ProcessorTerminate;virtual;
        procedure ProcessorParameterSetValue(id:integer;value:double);virtual;
        procedure OnSysexEvent(s:string);virtual;
        procedure OnMidiEvent(byte0, byte1, byte2: integer);
        function GetMidiOutputEvents:TArray<integer>;virtual;
        procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);
        procedure SamplerateChanged(samplerate:single);virtual;
        procedure PlayStateChanged(playing:boolean;ppq:integer);virtual;
        procedure TempoChanged(tempo:single);virtual;
        procedure UpdateParameter(id:integer;value:double);
        procedure InternalUpdateParameter(id:integer;value:double);

      public
   end;

     TVST3Processor = class(TVST3ProcessorBase,IComponent,IAudioProcessor,IConnectionPoint,IPluginBase)
protected
  FAudioProcessor:IAudioProcessor;
  FComponent:IComponent;
  FConnectionPoint: IConnectionPoint;
  property AudioProcessor: IAudioProcessor read FAudioProcessor implements IAudioProcessor;
  property Component: IComponent read FComponent implements IComponent,IPluginBase;
  property ConnectionPoint: IConnectionPoint read FConnectionPoint implements IConnectionPoint;
public
  constructor Create; override;
end;

implementation

uses UCodeSiteLogger,UCAudioProcessor,UCComponent,UCDataLayer,UCConnectionPoint,UVST3Controller;

procedure TVST3ProcessorBase.TempoChanged(tempo: single);
begin
// virtual
end;

procedure TVST3ProcessorBase.UpdateParameter(id: integer; value: double);
begin
  FVST3Instrument.UpdateProcessorParameter(id,value);
end;

procedure TVST3ProcessorBase.SendMessageToController(msg:TBytes);
begin
  SendMessage(msg);
end;

procedure TVST3ProcessorBase.SetActive(active: boolean);
begin
  Factive:=active;
end;

procedure TVST3ProcessorBase.ProcessorParameterSetValue(id:integer;value:double);
VAR index:integer;
const   MIDI_CC = $B0;
begin
//  WriteLog('ProcessorOnUpdateParameter: '+id.ToString+' '+value.ToString);
  if isMidiCCId(id) then
  begin
    index:=id-MIDICC_SIMULATION_START;
    MidiEvent(true,index DIV 128 + MIDI_CC,index MOD 128,round(127*value))
  end
  else
  begin // do some validation on the input..
    index:=FParameters.ParmLookup(id);
    if index=-1 then exit;
    if id<> IDPARMProgram then
      InternalUpdateParameter(id,value);
  end;
end;

procedure TVST3ProcessorBase.Process32(samples, channels: integer; inputp,  outputp: PPSingle);
begin
  FVST3Instrument.Process32(samples, channels,inputp,  outputp);
end;

procedure TVST3ProcessorBase.Initialize;
begin
  FParameters:=TVST3ParameterArray.Create;
  FMidiOutQueue:=TQueue<integer>.Create;
  SetParameters(FParameters);
  OnInitialize;
end;

procedure TVST3ProcessorBase.InternalUpdateParameter(id: integer;  value: double);
begin
  FParameters.UpdateParameter(id,value);
  UpdateParameter(id,value);
end;

procedure TVST3ProcessorBase.ProcessorTerminate;
begin
// virtual
end;

procedure TVST3ProcessorBase.ReceiveMessage(msg: TBytes);
  procedure ControllerArrived;
  VAR l:Uint64;
      i:integer;
      p:TVST3ControllerBase;
  begin
    l:=0;
    for i:=0 to 7 do
    begin
      l:=l SHL 8;
      l:=l or msg[8-i];
    end;
    p:=TVST3ControllerBase(l);
    p.SetVST3Instrument(FVST3Instrument);
  end;
begin
  case msg[0] of
    MSG_MIDIOUT: MidiOut(msg[1],msg[2],msg[3]);
    MSG_MIDIINT: MidiEvent(false,msg[1],msg[2],msg[3]);
    MSG_CONTROLLER_ATTACH: ControllerArrived;
  end;
end;

procedure TVST3ProcessorBase.SamplerateChanged(samplerate: single);
begin
// virtual;
end;

procedure TVST3ProcessorBase.OnInitialize;
begin
  FVst3Instrument.OnInitialize;
end;

procedure TVST3ProcessorBase.OnMidiEvent(byte0, byte1, byte2: integer);
begin
  FVst3Instrument.OnMidiEvent(true,byte0, byte1, byte2);
end;

procedure TVST3ProcessorBase.MidiEventToController(byte0, byte1, byte2: integer);
VAR buf:TBytes;
begin
  SetLength(buf,4);
  buf[0]:=MSG_MIDIINT;
  buf[1]:=byte0;
  buf[2]:=byte1;
  buf[3]:=byte2;
  SendMessageToController(buf);
end;

procedure TVST3ProcessorBase.MidiEvent(fromQueue:boolean;byte0, byte1, byte2: integer);
begin
  OnMidiEvent(byte0, byte1, byte2);
  if fromQueue then
  begin
    MidiEventToController(byte0,byte1,byte2);
    if GetPluginInfo.PluginDef.softMidiThru then
      MidiOut(byte0, byte1, byte2);
  end;
end;

function TVST3ProcessorBase.FVST3Instrument: TVST3Instrument;
begin
  result:=TVST3Instrument(FVST3InstrumentBase);
end;

function TVST3ProcessorBase.GetMidiOutputEvents: TArray<integer>;
VAR i,n:integer;
begin
  n:=FMidiOutQueue.Count;
  SetLength(result,n);
  for i:=0 to n-1 do
    result[i]:=FMidiOutQueue.Dequeue;
end;

procedure TVST3ProcessorBase.SetParameters(params: TVST3ParameterArray);
begin
  FVST3Instrument.SetParameters(params.AddParameter);
end;

procedure TVST3ProcessorBase.MidiOut(byte0, byte1, byte2: integer);
begin
  FMidiOutQueue.Enqueue(byte0+byte1 SHL 8 + byte2 SHL 16);
end;

function TVST3ProcessorBase.GetState:string;
VAR sl:TDataLayer;
begin
  sl:=TDataLayer.Create;
  FParameters.GetState(sl);
  result:=sl.Text;
  sl.Free;
end;

procedure TVST3ProcessorBase.SetState(state:string);
VAR i:integer;
    sl:TDataLayer;
    value:single;
begin
  sl:=TDataLayer.Create;
  sl.Text:=state;
  FParameters.SetState(sl);
  sl.free;
  for i:=0 to length(FParameters.params)-1 do
  begin
    value:=FParameters.params[i].value;
    UpdateParameter(FParameters.params[i].id,value);
  end;

end;

procedure TVST3ProcessorBase.OnSysexEvent(s: string);
begin
// virtual;
end;

procedure TVST3ProcessorBase.PlayStateChanged(playing: boolean; ppq: integer);
begin
// virtual
end;

//=========================================================

constructor TVST3Processor.Create;
begin
  WriteLog('TVST3Processor.Create');
  inherited;
  FConnectionPoint:=CConnectionPoint.Create(self);
  FAudioProcessor:=CAudioProcessor.Create(self);
  FComponent:=CComponent.Create(self);
end;

end.
