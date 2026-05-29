unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, libavcodec, ocv.comp.FFMSource,
  ocv.comp.Types, ocv.comp.Source, ocv.comp.View, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TSampleCameraStruct = record
    Alias: String;
    IP: String;
    Port: Word;
    Protocol: TocvIPProtocol;
    URI: String;
    ReconnectDelay: Integer;
    UserName: String;
    Password: String;
  end;

  PSampleCameraStruct = ^TSampleCameraStruct;

  TForm1 = class(TForm)
    ocvFFMpegIPCamSource1: TocvFFMpegIPCamSource;
    ocvView1: TocvView;
    Panel1: TPanel;
    CBCameraSampleList: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CBCameraSampleListChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ocvFFMpegIPCamSource1IPCamEvent(Sender: TObject; const Event: TocvFFMpegIPCamEvent);
  private
    LCCount: Integer;
    FList: TList;
    procedure DrawText(Value: String);
  public
  end;

var
  Form1: TForm1;

const
  // Данные взяты с сайта http://myttk.ru/media/webcam/ с помощью Wireshark
  // Проверены с помощью rtmpdump - http://all-streaming-media.com/record-video-stream/rtmpdump-freeware-console-RTMP-downloading-application.htm
  // Дополнительные публичные RTSP-потоки: wowza.com/developer/rtsp-stream-test, stream.strba.sk,
  // axis-media (github.com/irtaza9/93c0d56afd0b01c8f62e5970807eea20), ipvm.com/discussions/need-rtsp-url-to-test-with
  // protocol: 0 - http, 1 - https, 2 - rtsp
  SampleCameraList: Array [0 .. 4] of String = (
    'alias=Wowza RTSP Test Stream|' + 'ip=9627b0bf2a7b.entrypoint.cloud.wowza.com|' + 'port=1935|' + 'protocol=2|' +
    'uri=/app-p5260J38/66abe4b9_stream1|' + 'reconnectdelay=1500|' + 'username=|' + 'password=',

    'alias=Strba, Slovakia - Lake View|' + 'ip=stream.strba.sk|' + 'port=1935|' + 'protocol=2|' +
    'uri=/strba/VYHLAD_JAZERO.stream|' + 'reconnectdelay=1500|' + 'username=|' + 'password=',

    'alias=Western Cape, South Africa|' + 'ip=196.21.92.82|' + 'port=554|' + 'protocol=2|' +
    'uri=/axis-media/media.amp|' + 'reconnectdelay=1500|' + 'username=|' + 'password=',

    'alias=Vaison-La-Romaine, France|' + 'ip=176.139.87.16|' + 'port=554|' + 'protocol=2|' +
    'uri=/axis-media/media.amp|' + 'reconnectdelay=1500|' + 'username=|' + 'password=',

    'alias=IPVM Demo Camera (Axis)|' + 'ip=ipvmdemo.dyndns.org|' + 'port=5541|' + 'protocol=2|' +
    'uri=/onvif-media/media.amp?profile=profile_1_h264&sessiontimeout=60&streamtype=unicast|' +
    'reconnectdelay=1500|' + 'username=demo|' + 'password=demo');

implementation

{$R *.dfm}

function GetValue(Value: String): String;
var
  P: Integer;
begin
  P := Pos('=', Value);
  Result := Trim(Copy(Value, P + 1, Length(Value)));
end;

function GetParam(var Value: String): String;
var
  P: Integer;
begin
  P := Pos('|', Value);
  if P > 0 then
    Result := Trim(Copy(Value, 1, P - 1))
  else
    Result := Trim(Copy(Value, 1, Length(Value)));
  Delete(Value, 1, P);
end;

function GetProto(Value: Integer): TocvIPProtocol;
begin
  case Value of
    0:
      Result := ippHTTP;
    1:
      Result := ippHTTPS;
    2:
      Result := ippRTSP;
  else
    Result := ippRTSP;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Cnt: Integer;
  Cam: PSampleCameraStruct;
  Str: String;
begin
  FList := TList.Create;
  FList.Clear;
  for Cnt := 0 to Length(SampleCameraList) - 1 do
  begin
    New(Cam);
    Str := SampleCameraList[Cnt];
    Cam^.Alias := GetValue(GetParam(Str));
    Cam^.IP := GetValue(GetParam(Str));
    Cam^.Port := StrToIntDef(GetValue(GetParam(Str)), 0);
    Cam^.Protocol := GetProto(StrToIntDef(GetValue(GetParam(Str)), 0));
    Cam^.URI := GetValue(GetParam(Str));
    Cam^.ReconnectDelay := StrToIntDef(GetValue(GetParam(Str)), 0);
    Cam^.UserName := GetValue(GetParam(Str));
    Cam^.Password := GetValue(GetParam(Str));
    FList.Add(Cam);
  end;
  if FList.Count > 0 then
  begin
    CBCameraSampleList.Clear;
    CBCameraSampleList.Items.BeginUpdate;
    try
      for Cnt := 0 to FList.Count - 1 do
        CBCameraSampleList.Items.Add(TSampleCameraStruct(FList[Cnt]^).Alias);
    finally
      CBCameraSampleList.Items.EndUpdate;
    end;
    CBCameraSampleList.ItemIndex := -1;
  end
  else
  begin
    CBCameraSampleList.ItemIndex := -1;
    CBCameraSampleList.Enabled := False;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FList.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  DrawText('Please select the camera.')
end;

procedure TForm1.CBCameraSampleListChange(Sender: TObject);
var
  Cam: TSampleCameraStruct;
begin
  // DrawText('Getting data, please wait...');
  ocvFFMpegIPCamSource1.Enabled := False;
  Cam := TSampleCameraStruct(FList[(Sender as TComboBox).ItemIndex]^);
  ocvFFMpegIPCamSource1.IP := Cam.IP;
  ocvFFMpegIPCamSource1.Port := Cam.Port;
  ocvFFMpegIPCamSource1.Protocol := Cam.Protocol;
  ocvFFMpegIPCamSource1.URI := Cam.URI;
  ocvFFMpegIPCamSource1.ReconnectDelay := Cam.ReconnectDelay;
  ocvFFMpegIPCamSource1.UserName := Cam.UserName;
  ocvFFMpegIPCamSource1.Password := Cam.Password;
  ocvFFMpegIPCamSource1.Enabled := True;
end;

procedure TForm1.ocvFFMpegIPCamSource1IPCamEvent(Sender: TObject; const Event: TocvFFMpegIPCamEvent);
begin
  case Event of
    ffocvTryConnect:
      DrawText('Try connect');
    ffocvConnected:
      DrawText('Connected');
    ffocvLostConnection:
      DrawText('Lost connection');
    ffocvReconnect:
      DrawText('Reconnect');
    ffocvErrorGetStream:
      DrawText('Error get stream');
  end;
end;

procedure TForm1.DrawText(Value: String);
var
  Bmp: TBitmap;
  TW: Integer;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(ocvView1.Width, ocvView1.Height);
    Bmp.PixelFormat := pf24bit;
    TW := Bmp.Canvas.TextWidth(Value);
    Bmp.Canvas.TextOut((ocvView1.Width - TW) div 2, ocvView1.Height div 2, Value);
    ocvView1.DrawImage(TocvImage.Create(Bmp));
  finally
    Bmp.Free;
  end;
end;

end.
