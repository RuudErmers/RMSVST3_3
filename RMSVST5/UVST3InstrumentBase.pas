unit UVST3InstrumentBase;

interface

uses Forms;

type TonAddParameter = procedure (id:integer;title,shorttitle,units:string;min,max,val:double;cc:integer=-1;automate:boolean=true;steps:integer=0;ProgramChange:boolean=false) of object;
     ICBController = interface
                       procedure UpdateHostParameter(id:integer;value:double);
                       procedure MidiOut(byte0, byte1, byte2: integer);
                       procedure MidiEventToProcessor(byte0, byte1, byte2: integer);
                       procedure doProgramChange(prgm:integer);
                     end;
     TVST3InstrumentBase = class
                              private
                                FICBController:ICBController;
                              protected
                                EditorForm:TForm;
                                procedure OnEditOpen;virtual;
                                procedure doProgramChange(prgm: integer);
                                procedure UpdateHostParameter(id: integer; value: double);
                                procedure MidiEventToProcessor(byte0, byte1, byte2: integer);
                                procedure MidiOut(byte0, byte1, byte2: integer);
                              public
                                procedure OpenEditor(form:TForm);
                                procedure SetCBController(cntrl:ICBController);
                           end;

implementation

{ TVST3InstrumentBase }

procedure TVST3InstrumentBase.UpdateHostParameter(id: integer; value: double);
begin
  if FICBController<>NIL then FICBController.UpdateHostParameter(id,value);
end;

procedure TVST3InstrumentBase.doProgramChange(prgm: integer);
begin
  if FICBController<>NIL then FICBController.doProgramChange(prgm);
end;

procedure TVST3InstrumentBase.MidiEventToProcessor(byte0, byte1, byte2: integer);
begin
  if FICBController<>NIL then FICBController.MidiEventToProcessor(byte0, byte1, byte2);
end;

procedure TVST3InstrumentBase.MidiOut(byte0, byte1, byte2: integer);
begin
  if FICBController<>NIL then FICBController.MidiOut(byte0, byte1, byte2);
end;


procedure TVST3InstrumentBase.SetCBController(cntrl: ICBController);
begin
  FICBController:=cntrl;
end;

procedure TVST3InstrumentBase.OnEditOpen;
begin
// virtual
end;

procedure TVST3InstrumentBase.OpenEditor(form: TForm);
begin
  EditorForm:=form;
  OnEditOpen;
end;




end.
