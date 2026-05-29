program FaceFinder;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ocv.core_c,
  ocv.core.types_c,
  ocv.highgui_c,
  ocv.imgproc_c,
  ocv.imgproc.types_c,
  ocv.objdetect_c;

var
  photoPath, videoPath, cascadePath: AnsiString;
  cascade: pCvHaarClassifierCascade;
  storage: pCvMemStorage;
  photo, ref_face, frame, gray_frame, candidate_face, match_result: pIplImage;
  capture: pCvCapture;
  ref_faces, faces: pCvSeq;
  largest_rect: TCvRect;
  r: pCvRect;
  i: Integer;
  font: TCvFont;
  score: Double;
  pt1, pt2: TCvPoint;
  colorGreen, colorRed: TCvScalar;
begin
  // 1. Проверка аргументов командной строки
  if ParamCount < 2 then
  begin
    Writeln('Использование: FaceFinder.exe <путь_к_фото> <путь_к_видео>');
    Exit;
  end;

  // Конвертируем параметры в AnsiString, так как OpenCV C-API требует PAnsiChar
  photoPath := AnsiString(ParamStr(1));
  videoPath := AnsiString(ParamStr(2));
  cascadePath := 'haarcascade_frontalface_default.xml';

  // 2. Загрузка каскада Хаара
  cascade := pCvHaarClassifierCascade(cvLoad(PAnsiChar(cascadePath), nil, nil, nil));
  if not Assigned(cascade) then
  begin
    Writeln('Ошибка: не удалось загрузить ', cascadePath);
    Exit;
  end;

  storage := cvCreateMemStorage(0);

  // 3. Обработка эталонного фото
  photo := cvLoadImage(PAnsiChar(photoPath), CV_LOAD_IMAGE_GRAYSCALE);
  if not Assigned(photo) then
  begin
    Writeln('Ошибка: не удалось загрузить фото ', photoPath);
    Exit;
  end;

  // Поиск лиц на эталонном фото
  ref_faces := cvHaarDetectObjects(photo, cascade, storage, 1.1, 3, 0, cvSize(30, 30), cvSize(0, 0));

  if (not Assigned(ref_faces)) or (ref_faces^.total = 0) then
  begin
    Writeln('Ошибка: на эталонном фото не найдено лиц!');
    cvReleaseImage(photo);
    Exit;
  end;

  // Ищем самое крупное лицо на фото
  largest_rect := pCvRect(cvGetSeqElem(ref_faces, 0))^;
  for i := 1 to ref_faces^.total - 1 do
  begin
    r := pCvRect(cvGetSeqElem(ref_faces, i));
    if (r^.width * r^.height) > (largest_rect.width * largest_rect.height) then
      largest_rect := r^;
  end;

  // Вырезаем и приводим эталонное лицо к размеру 100x100
  ref_face := cvCreateImage(cvSize(100, 100), IPL_DEPTH_8U, 1);
  cvSetImageROI(photo, largest_rect);            // Устанавливаем маску
  cvResize(photo, ref_face, CV_INTER_LINEAR);    // Копируем с ресайзом
  cvResetImageROI(photo);                        // Сбрасываем маску
  cvReleaseImage(photo);                        // Удаляем исходное фото из памяти

  // 4. Открытие видео
  capture := cvCreateFileCapture(PAnsiChar(videoPath));
  if not Assigned(capture) then
  begin
    Writeln('Ошибка: не удалось открыть видео ', videoPath);
    Exit;
  end;

  candidate_face := cvCreateImage(cvSize(100, 100), IPL_DEPTH_8U, 1);
  match_result   := cvCreateImage(cvSize(1, 1), IPL_DEPTH_32F, 1);
  gray_frame     := nil;

  cvNamedWindow('Face Tracker', CV_WINDOW_AUTOSIZE);
  
  // Инициализация шрифта (масштаб 0.8)
  cvInitFont(@font, CV_FONT_HERSHEY_SIMPLEX, 0.8, 0.8, 0, 2, 8);

  // В OpenCV используется формат BGR, поэтому (Blue, Green, Red, 0)
  colorGreen := cvScalar(0, 255, 0, 0); 
  colorRed   := cvScalar(0, 0, 255, 0);

  // Главный цикл обработки видео
  while True do
  begin
    frame := cvQueryFrame(capture);
    if not Assigned(frame) then Break; // Конец видео

    if not Assigned(gray_frame) then
      gray_frame := cvCreateImage(cvGetSize(frame), IPL_DEPTH_8U, 1);

    cvCvtColor(frame, gray_frame, CV_BGR2GRAY);

    // Обязательная очистка памяти в цикле
    cvClearMemStorage(storage); 

    faces := cvHaarDetectObjects(gray_frame, cascade, storage, 1.1, 3, 0, cvSize(30, 30), cvSize(0, 0));

    if Assigned(faces) then
    begin
      // 5. Поиск и сравнение лиц на текущем кадре
      for i := 0 to faces^.total - 1 do
      begin
        r := pCvRect(cvGetSeqElem(faces, i));

        // Вырезаем и приводим к 100x100
        cvSetImageROI(gray_frame, r^);
        cvResize(gray_frame, candidate_face, CV_INTER_LINEAR);
        cvResetImageROI(gray_frame);

        // Сравниваем с эталоном
        cvMatchTemplate(candidate_face, ref_face, match_result, CV_TM_CCOEFF_NORMED);
        score := cvGetReal2D(match_result, 0, 0);

        pt1 := cvPoint(r^.x, r^.y);
        pt2 := cvPoint(r^.x + r^.width, r^.y + r^.height);

        // Порог совпадения > 0.55
        if score > 0.55 then
        begin
          cvRectangle(frame, pt1, pt2, colorGreen, 2, 8, 0);
          cvPutText(frame, 'Target!', cvPoint(r^.x, r^.y - 10), @font, colorGreen);
        end
        else
        begin
          cvRectangle(frame, pt1, pt2, colorRed, 2, 8, 0);
        end;
      end;
    end;

    cvShowImage('Face Tracker', frame);

    // Выход по клавише ESC (код 27)
    if cvWaitKey(30) = 27 then Break;
  end;

  // 6. Освобождение ресурсов памяти
  cvReleaseImage(ref_face);
  cvReleaseImage(candidate_face);
  cvReleaseImage(match_result);
  
  if Assigned(gray_frame) then 
    cvReleaseImage(gray_frame);

  cvReleaseCapture(capture);
  cvReleaseMemStorage(storage);
  cvRelease(pointer(cascade)); // Удаление каскада
  cvDestroyAllWindows();

end.