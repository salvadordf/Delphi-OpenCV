(*
  **************************************************************************************************
  Project Delphi-OpenCV
  **************************************************************************************************
  Contributor:
  Laentir Valetov
  email:laex@bk.ru
  **************************************************************************************************
  Original file:
  opencv\modules\contrib\include\opencv2\contrib\contrib.hpp
  opencv\modules\contrib\src\adaptiveskindetector.cpp
  *************************************************************************************************
*)

{$I OpenCV.inc}

unit ocv.contrib;

interface

uses
  System.SysUtils,
  System.Math,
  ocv.core.types_c,
  ocv.core_c,
  ocv.imgproc_c,
  ocv.imgproc.types_c;

type
  TCvAdaptiveSkinDetector = class
  public
    const
      MORPHING_METHOD_NONE = 0;
      MORPHING_METHOD_ERODE = 1;
      MORPHING_METHOD_ERODE_ERODE = 2;
      MORPHING_METHOD_ERODE_DILATE = 3;
    constructor Create(samplingDivider: Integer = 1; morphingMethod: Integer = MORPHING_METHOD_NONE);
    destructor Destroy; override;
    procedure process(inputBGRImage: pIplImage; outputHueMask: pIplImage);
  private
    const
      GSD_HUE_LT = 3;
      GSD_HUE_UT = 33;
      GSD_INTENSITY_LT = 15;
      GSD_INTENSITY_UT = 250;
      cHistogramSize = GSD_HUE_UT - GSD_HUE_LT + 1;
    type
      THistogram = class
      public
        fHistogram: pCvHistogram;
        constructor Create;
        destructor Destroy; override;
        procedure findCurveThresholds(var x1, x2: Integer; percent: Double = 0.05);
        procedure mergeWith(source: THistogram; weight: Double);
      private
        function findCoverageIndex(surfaceToCover: Double; defaultValue: Integer): Integer;
      end;
    var
      nStartCounter, nFrameCount, nSkinHueLowerBound, nSkinHueUpperBound: Integer;
      nMorphingMethod, nSamplingDivider: Integer;
      fHistogramMergeFactor, fHuePercentCovered: Double;
      histogramHueMotion, skinHueHistogram: THistogram;
      imgHueFrame, imgSaturationFrame, imgLastGrayFrame, imgMotionFrame: pIplImage;
      imgFilteredFrame, imgShrinked, imgTemp, imgGrayFrame, imgHSVFrame: pIplImage;
    procedure initData(src: pIplImage; widthDivider, heightDivider: Integer);
  end;

implementation

{ THistogram }

constructor TCvAdaptiveSkinDetector.THistogram.Create;
var
  histogramSize: array [0 .. 0] of Integer;
  range: array [0 .. 1] of Single;
  ranges: array [0 .. 0] of Pointer;
begin
  histogramSize[0] := cHistogramSize;
  range[0] := GSD_HUE_LT;
  range[1] := GSD_HUE_UT;
  ranges[0] := @range[0];
  fHistogram := cvCreateHist(1, @histogramSize[0], CV_HIST_ARRAY, @ranges[0], 1);
  cvClearHist(fHistogram);
end;

destructor TCvAdaptiveSkinDetector.THistogram.Destroy;
begin
  cvReleaseHist(fHistogram);
  inherited;
end;

function TCvAdaptiveSkinDetector.THistogram.findCoverageIndex(surfaceToCover: Double; defaultValue: Integer): Integer;
var
  i: Integer;
  s: Double;
begin
  s := 0;
  for i := 0 to cHistogramSize - 1 do
  begin
    s := s + cvGetReal1D(fHistogram^.bins, i);
    if s >= surfaceToCover then
      Exit(i);
  end;
  Result := defaultValue;
end;

procedure TCvAdaptiveSkinDetector.THistogram.findCurveThresholds(var x1, x2: Integer; percent: Double);
var
  i: Integer;
  sum: Double;
begin
  sum := 0;
  for i := 0 to cHistogramSize - 1 do
    sum := sum + cvGetReal1D(fHistogram^.bins, i);

  x1 := findCoverageIndex(sum * percent, -1);
  x2 := findCoverageIndex(sum * (1 - percent), -1);

  if x1 = -1 then
    x1 := GSD_HUE_LT
  else
    x1 := x1 + GSD_HUE_LT;

  if x2 = -1 then
    x2 := GSD_HUE_UT
  else
    x2 := x2 + GSD_HUE_UT;
end;

procedure TCvAdaptiveSkinDetector.THistogram.mergeWith(source: THistogram; weight: Double);
var
  i: Integer;
  myweight, maxVal1, maxVal2, ff1, ff2: Single;
  f1, f2: PSingle;
begin
  cvGetMinMaxHistValue(source.fHistogram, nil, @maxVal2);
  if maxVal2 <= 0 then
    Exit;

  cvGetMinMaxHistValue(fHistogram, nil, @maxVal1);
  myweight := 1 - weight;

  if maxVal1 <= 0 then
  begin
    for i := 0 to cHistogramSize - 1 do
    begin
      f1 := PSingle(cvPtr1D(fHistogram^.bins, i));
      f2 := PSingle(cvPtr1D(source.fHistogram^.bins, i));
      f1^ := f2^;
    end;
  end
  else
  begin
    for i := 0 to cHistogramSize - 1 do
    begin
      f1 := PSingle(cvPtr1D(fHistogram^.bins, i));
      f2 := PSingle(cvPtr1D(source.fHistogram^.bins, i));

      ff1 := (f1^ / maxVal1) * myweight;
      if ff1 < 0 then
        ff1 := -ff1;

      ff2 := (f2^ / maxVal2) * weight;
      if ff2 < 0 then
        ff2 := -ff2;

      f1^ := ff1 + ff2;
    end;
  end;
end;

{ TCvAdaptiveSkinDetector }

constructor TCvAdaptiveSkinDetector.Create(samplingDivider, morphingMethod: Integer);
begin
  inherited Create;
  nSkinHueLowerBound := GSD_HUE_LT;
  nSkinHueUpperBound := GSD_HUE_UT;
  fHistogramMergeFactor := 0.05;
  fHuePercentCovered := 0.95;
  nMorphingMethod := morphingMethod;
  nSamplingDivider := samplingDivider;
  nFrameCount := 0;
  nStartCounter := 0;
  imgHueFrame := nil;
  imgMotionFrame := nil;
  imgTemp := nil;
  imgFilteredFrame := nil;
  imgShrinked := nil;
  imgGrayFrame := nil;
  imgLastGrayFrame := nil;
  imgSaturationFrame := nil;
  imgHSVFrame := nil;
  histogramHueMotion := THistogram.Create;
  skinHueHistogram := THistogram.Create;
end;

destructor TCvAdaptiveSkinDetector.Destroy;
begin
  cvReleaseImage(imgHueFrame);
  cvReleaseImage(imgSaturationFrame);
  cvReleaseImage(imgMotionFrame);
  cvReleaseImage(imgTemp);
  cvReleaseImage(imgFilteredFrame);
  cvReleaseImage(imgShrinked);
  cvReleaseImage(imgGrayFrame);
  cvReleaseImage(imgLastGrayFrame);
  cvReleaseImage(imgHSVFrame);
  histogramHueMotion.Free;
  skinHueHistogram.Free;
  inherited;
end;

procedure TCvAdaptiveSkinDetector.initData(src: pIplImage; widthDivider, heightDivider: Integer);
var
  imageSize: TCvSize;
begin
  imageSize := cvSize(src^.width div widthDivider, src^.height div heightDivider);
  imgHueFrame := cvCreateImage(imageSize, IPL_DEPTH_8U, 1);
  imgShrinked := cvCreateImage(imageSize, IPL_DEPTH_8U, src^.nChannels);
  imgSaturationFrame := cvCreateImage(imageSize, IPL_DEPTH_8U, 1);
  imgMotionFrame := cvCreateImage(imageSize, IPL_DEPTH_8U, 1);
  imgTemp := cvCreateImage(imageSize, IPL_DEPTH_8U, 1);
  imgFilteredFrame := cvCreateImage(imageSize, IPL_DEPTH_8U, 1);
  imgGrayFrame := cvCreateImage(imageSize, IPL_DEPTH_8U, 1);
  imgLastGrayFrame := cvCreateImage(imageSize, IPL_DEPTH_8U, 1);
  imgHSVFrame := cvCreateImage(imageSize, IPL_DEPTH_8U, 3);
end;

procedure TCvAdaptiveSkinDetector.process(inputBGRImage, outputHueMask: pIplImage);
var
  src: pIplImage;
  h, v, i, l: Integer;
  isInit: Boolean;
  pShrinked, pHueFrame, pMotionFrame, pLastGrayFrame, pFilteredFrame, pGrayFrame: PByte;
begin
  src := inputBGRImage;
  isInit := False;
  Inc(nFrameCount);

  if imgHueFrame = nil then
  begin
    isInit := True;
    initData(src, nSamplingDivider, nSamplingDivider);
  end;

  pShrinked := PByte(imgShrinked^.imageData);
  pHueFrame := PByte(imgHueFrame^.imageData);
  pMotionFrame := PByte(imgMotionFrame^.imageData);
  pLastGrayFrame := PByte(imgLastGrayFrame^.imageData);
  pFilteredFrame := PByte(imgFilteredFrame^.imageData);
  pGrayFrame := PByte(imgGrayFrame^.imageData);

  if (src^.width <> imgHueFrame^.width) or (src^.height <> imgHueFrame^.height) then
  begin
    cvResize(src, imgShrinked);
    cvCvtColor(imgShrinked, imgHSVFrame, CV_BGR2HSV);
  end
  else
    cvCvtColor(src, imgHSVFrame, CV_BGR2HSV);

  cvSplit(imgHSVFrame, imgHueFrame, imgSaturationFrame, imgGrayFrame);
  cvSetZero(imgMotionFrame);
  cvSetZero(imgFilteredFrame);

  l := imgHueFrame^.height * imgHueFrame^.width;
  for i := 0 to l - 1 do
  begin
    v := pGrayFrame^;
    if (v >= GSD_INTENSITY_LT) and (v <= GSD_INTENSITY_UT) then
    begin
      h := pHueFrame^;
      if (h >= GSD_HUE_LT) and (h <= GSD_HUE_UT) then
      begin
        if (h >= nSkinHueLowerBound) and (h <= nSkinHueUpperBound) then
          pFilteredFrame^ := h;

        if Abs(pLastGrayFrame^ - v) > 7 then
          pMotionFrame^ := h;
      end;
    end;
    Inc(pShrinked, 3);
    Inc(pGrayFrame);
    Inc(pLastGrayFrame);
    Inc(pMotionFrame);
    Inc(pHueFrame);
    Inc(pFilteredFrame);
  end;

  if isInit then
    cvCalcHist(imgHueFrame, skinHueHistogram.fHistogram);

  cvCopy(imgGrayFrame, imgLastGrayFrame);

  cvErode(imgMotionFrame, imgTemp);
  cvDilate(imgTemp, imgMotionFrame);

  cvCalcHist(imgMotionFrame, histogramHueMotion.fHistogram);
  skinHueHistogram.mergeWith(histogramHueMotion, fHistogramMergeFactor);
  skinHueHistogram.findCurveThresholds(nSkinHueLowerBound, nSkinHueUpperBound, 1 - fHuePercentCovered);

  case nMorphingMethod of
    MORPHING_METHOD_ERODE:
      begin
        cvErode(imgFilteredFrame, imgTemp);
        cvCopy(imgTemp, imgFilteredFrame);
      end;
    MORPHING_METHOD_ERODE_ERODE:
      begin
        cvErode(imgFilteredFrame, imgTemp);
        cvErode(imgTemp, imgFilteredFrame);
      end;
    MORPHING_METHOD_ERODE_DILATE:
      begin
        cvErode(imgFilteredFrame, imgTemp);
        cvDilate(imgTemp, imgFilteredFrame);
      end;
  end;

  if outputHueMask <> nil then
    cvCopy(imgFilteredFrame, outputHueMask);
end;

end.
