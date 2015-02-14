program PianoEx;

uses
  Forms,
  fMain in 'fMain.pas' {frmMain},
  fNotes in 'fNotes.pas' {frmNotes},
  fInfo in 'fInfo.pas' {frmInfo};

{$R *.RES}

begin
//  mmPopupMsgDlg := True;
//  mmShowObjectInfo := True;
//  mmUseObjectList := True;
//  mmSaveToLogFile := True;

  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

