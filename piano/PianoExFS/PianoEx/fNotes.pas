unit fNotes;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons;

type
  TfrmNotes = class(TForm)
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButton10: TSpeedButton;
    SpeedButton11: TSpeedButton;
    SpeedButton12: TSpeedButton;
    procedure FormCreate(Sender: TObject);
  private
    function AdjustNoteLen(PPQN: Integer; var Dotted, Quantize: Boolean): Integer;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmNotes: TfrmNotes;

implementation

{$R *.dfm}

function TfrmNotes.AdjustNoteLen(PPQN: Integer; var Dotted, Quantize: Boolean): Integer;
begin
  if SpeedButton1.Down then
    PPQN := PPQN * 8
  else
    if SpeedButton2.Down then
      PPQN := PPQN * 4
    else
      if SpeedButton3.Down then
        PPQN := PPQN * 2;

  if SpeedButton9.Down then PPQN := PPQN * 3 div 2;
  if SpeedButton10.Down then PPQN := PPQN * 2 div 3;

  if SpeedButton5.Down then
    PPQN := PPQN div 2
  else
    if SpeedButton6.Down then
      PPQN := PPQN div 4
    else
      if SpeedButton7.Down then
        PPQN := PPQN div 8
      else
        if SpeedButton8.Down then
          PPQN := PPQN div 16;

  Dotted := SpeedButton11.Down;
  Quantize := SpeedButton12.Down;
  result := PPQN;
end;

procedure TfrmNotes.FormCreate(Sender: TObject);
begin
  AutoSize := True;
end;

end.

