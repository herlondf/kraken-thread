unit KrakenThread;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils;

type
  TKrakenEvent = reference to procedure;

  TKrakenThreadExecute = class(TThread)
    class destructor UnInitialize;
  class var
    FEvent: TEvent;
    FDefaultJob: TKrakenThreadExecute;
  private
    fProcEvent: TKrakenEvent;
    fInterval: Integer;
  protected
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Execute; override;
  public
    class function DefaultJob: TKrakenThreadExecute;

    procedure Interval(const Value: Integer);
    procedure ProcEvent(const AProcEvent: TKrakenEvent);

    procedure Pause;
    procedure Run;
  end;

implementation

procedure TKrakenThreadExecute.AfterConstruction;
begin
  inherited;
  FEvent := TEvent.Create;
end;

procedure TKrakenThreadExecute.BeforeDestruction;
begin
  inherited;
  FEvent.Free;
end;

procedure TKrakenThreadExecute.Execute;
var
  LWaitResult: TWaitResult;
  LCriticalSection: TCriticalSection;
begin
  inherited;

  LCriticalSection := TCriticalSection.Create;
  LCriticalSection.Enter;

  if not Self.Terminated  then
  begin
    try
      if Assigned(fProcEvent) then
        fProcEvent;
    except

    end;
  end;

  while not Self.Terminated do
  begin
    LWaitResult := FEvent.WaitFor( fInterval );

    if LWaitResult <> TWaitResult.wrTimeout then
      Break;

    try
      if Assigned(fProcEvent) then
        fProcEvent;
    except
      Continue;
    end;
  end;

  LCriticalSection.Leave;
  LCriticalSection.Free;
end;

procedure TKrakenThreadExecute.Interval(const Value: Integer);
begin
  fInterval := Value;
end;

procedure TKrakenThreadExecute.Pause;
begin
  if not FDefaultJob.Suspended then
    FDefaultJob.Suspended := True;
end;

procedure TKrakenThreadExecute.ProcEvent(const AProcEvent: TKrakenEvent);
begin
  fProcEvent := AProcEvent;
end;

procedure TKrakenThreadExecute.Run;
begin
  if FDefaultJob.Suspended then
    FDefaultJob.Suspended := False;
end;

class function TKrakenThreadExecute.DefaultJob: TKrakenThreadExecute;
begin
  if FDefaultJob = nil then
  begin
    FDefaultJob := TKrakenThreadExecute.Create(True);
    FDefaultJob.FreeOnTerminate := False;
  end;

  Result := FDefaultJob;
end;

class destructor TKrakenThreadExecute.UnInitialize;
begin
  if Assigned(FDefaultJob) then
  begin
    if not FDefaultJob.Terminated then
    begin
      FDefaultJob.Terminate;
      FEvent.SetEvent;

      if not FDefaultJob.Suspended then
        FDefaultJob.WaitFor;
    end;

    FreeAndNil(FDefaultJob);
  end;
end;

end.
