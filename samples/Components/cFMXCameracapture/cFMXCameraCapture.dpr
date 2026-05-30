 program cFMXCameraCapture;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  ocv.utils in '..\..\..\source\ocv.utils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
