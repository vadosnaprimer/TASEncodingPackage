:: feos, 2013-2017 (cheers to Guga, Velitha, nanogyth, Aktan and Dacicus)
:: This global batch is a part of "TAS Encoding Package":
:: http://tasvideos.org/EncodingGuide/PublicationManual.html
:: Asks for aspect ratio to use
:: Allows to select encode to make
:: Accepts command line arguments

@echo off
setlocal enableextensions

:: Restore AVS defaults ::
".\programs\replacetext" "encode.avs" "pass = 1" "pass = 0"
".\programs\replacetext" "encode.avs" "pass = 2" "pass = 0"
".\programs\replacetext" "encode.avs" "i444 = true" "i444 = false"
".\programs\replacetext" "encode.avs" "hd = true" "hd = false"
".\programs\replacetext" "encode.avs" "hq = true" "hq = false"
".\programs\replacetext" "encode.avs" "vb = true" "vb = false"

:: Uncomment for a VirtualBoy encode
:: set /a VIRTUALBOY=1

if "%VIRTUALBOY%"=="1" (".\programs\replacetext" "encode.avs" "vb = false" "vb = true")

echo -----------------------
echo  Hybrid Encoding Batch
echo -----------------------
echo.
echo Command-line arguments: global.bat ^<arc^> ^<enc_opt^>
echo   ^<arc^>       Aspect ratio?    1-3 or width:height
echo   ^<enc_opt^>   Encode option?   1-5
echo.

if [%1]==[] goto SAR_OPTIONS
if [%1]==[1] goto handHeld_SAR
if [%1]==[2] (
set ar_w=4
set ar_h=3
goto TV_SAR
)
if [%1]==[3] (
set ar_w=16
set ar_h=9
goto TV_SAR
)
set aspect_ratio=%1
goto Parse_AR

: SAR_OPTIONS
echo Aspect ratio options:
echo.
echo Press 1 for  1:1 (no change)
echo Press 2 for  4:3 (CRT TV)
echo Press 3 for 16:9 (LCD TV)
echo Press 4 to enter your own
echo.
set /p ANSWER=
if "%ANSWER%"=="1" goto handHeld_SAR
if "%ANSWER%"=="2" (
set ar_w=4
set ar_h=3
goto TV_SAR
)
if "%ANSWER%"=="3" (
set ar_w=16
set ar_h=9
goto TV_SAR
)
if "%ANSWER%"=="4" goto Get_AR
echo I'm not kidding!
goto SAR_OPTIONS

: Get_AR
set ar_w=
set ar_h=
set /p aspect_ratio=Enter aspect ratio in the format width:height 

: Parse_AR
for /f "tokens=1 delims=:" %%g in ('echo %aspect_ratio%') do (set /a "ar_w=%%g")
for /f "tokens=2 delims=:" %%g in ('echo %aspect_ratio%') do (set /a "ar_h=%%g")
if [%ar_w%]==[] goto Get_AR
if [%ar_h%]==[] goto Get_AR
if %ar_w% leq 0 goto Get_AR
if %ar_h% leq 0 goto Get_AR
goto TV Sar

: TV_SAR
for /f "tokens=2 skip=2 delims== " %%G in ('find "wAspect = " "%~dp0encode.avs"') do (set current_wAspect=%%G)
".\programs\replacetext" "encode.avs" "wAspect = %current_wAspect%" "wAspect = %ar_w%"
for /f "tokens=2 skip=2 delims== " %%G in ('find "hAspect = " "%~dp0encode.avs"') do (set current_hAspect=%%G)
".\programs\replacetext" "encode.avs" "hAspect = %current_hAspect%" "hAspect = %ar_h%"
".\programs\replacetext" "encode.avs" "handHeld = true" "handHeld = false"
".\programs\replacetext" "encode.avs" "pass = 0" "pass = 1"
".\programs\avs2pipemod" -info encode.avs > ".\temp\info.txt"
for /f "tokens=2" %%G in ('FIND "width" "%~dp0temp\info.txt"') do (set width=%%G)
for /f "tokens=2" %%G in ('FIND "height" "%~dp0temp\info.txt"') do (set height=%%G)
set /a "SAR_w=%ar_w% * %height%"
set /a "SAR_h=%ar_h% * %width%"
set VAR=%SAR_w%:%SAR_h%
".\programs\replacetext" "encode.avs" "pass = 1" "pass = 0"
goto ENCODE_OPTIONS

: handHeld_SAR
set VAR=1:1
".\programs\replacetext" "encode.avs" "handHeld = false" "handHeld = true"
goto ENCODE_OPTIONS

: ENCODE_OPTIONS
if [%2]==[1] goto 10bit444
if [%2]==[2] goto 512kb
if [%2]==[3] goto HD
if [%2]==[4] goto HD
if [%2]==[5] goto ExtraHQ

echo.
echo What encode do you want to do?
echo.
echo Press 1 for Modern HQ MKV.
echo Press 2 for Compatibility MP4.
echo Press 3 for HD Stream.
echo Press 4 for All of the above.
echo Press 5 for extra HQ encodes.
echo.

: Set_choice
set /p EncodeChoice=
if "%EncodeChoice%"=="1" goto 10bit444
if "%EncodeChoice%"=="2" goto 512kb
if "%EncodeChoice%"=="3" goto HD
if "%EncodeChoice%"=="4" goto HD
if "%EncodeChoice%"=="5" goto ExtraHQ
echo.
echo You better choose something real!
goto Set_choice

: HD
:: Audio ::
".\programs\avs2pipemod" -wav encode.avs | ".\programs\venc" -q10 - ".\temp\audio_youtube.ogg"
echo.
echo ----------------------------
echo  Encoding YouTube HD stream 
echo ----------------------------
echo.
:: Video ::
".\programs\replacetext" "encode.avs" "hd = false" "hd = true"
".\programs\avs2pipemod" -y4mp encode.avs | ".\programs\x264_x64" --qp 5 -b 0 --keyint infinite --output ".\temp\video_youtube.mkv" --demuxer y4m -
".\programs\replacetext" "encode.avs" "hd = true" "hd = false"
:: Muxing ::
".\programs\mkvmerge" -o ".\output\encode_youtube.mkv" --compression -1:none ".\temp\video_youtube.mkv" ".\temp\audio_youtube.ogg"

if "%VIRTUALBOY%"=="1" (set VBPREF="_vb_") else (set VBPREF="_")
if "%VIRTUALBOY%"=="1" (".\programs\ffmpeg" -i ".\output\encode_youtube.mkv" -c copy -metadata:s:v:0 stereo_mode=1 ".\output\encode%VBPREF%youtube.mkv")

echo.
echo -----------------------------
echo  Uploading YouTube HD stream 
echo -----------------------------
echo.
start "" cmd /c type "%~dp0programs\ytdesc.txt" ^| "%~dp0programs\tvcman.exe" "%~dp0output\encode%VBPREF%youtube.mkv" todo tasvideos
rem start "" cmd /c echo todo ^| "%~dp0programs\tvcman.exe" "%~dp0output\encode%VBPREF%youtube.mkv" todo tasvideos
if "%EncodeChoice%"=="3" goto Defaults
if [%2]==[3] goto Defaults

: 10bit444
:: Audio ::
".\programs\avs2pipemod" -wav encode.avs | ".\programs\sox" -t wav - -t wav - trim 0.0065 | ".\programs\opusenc" --bitrate 64 --padding 0 - ".\temp\audio.opus"
echo.
echo ----------------------
echo  Generating timecodes 
echo ----------------------
:: Timecodes ::
".\programs\replacetext" "encode.avs" "pass = 0" "pass = 1"
".\programs\avs2pipemod" -benchmark encode.avs
".\programs\replacetext" "encode.avs" "pass = 1" "pass = 2"
echo.
echo --------------------------------
echo  Encoding 10bit444 downloadable 
echo --------------------------------
echo.
:: Video ::
".\programs\replacetext" "encode.avs" "i444 = false" "i444 = true"
".\programs\avs2pipemod" -y4mp encode.avs | ".\programs\x264-10_x64" --threads auto --sar "%VAR%" --crf 20 --keyint 600 --ref 16 --no-fast-pskip --bframes 16 --b-adapt 2 --direct auto --me tesa --merange 64 --subme 11 --trellis 2 --partitions all --no-dct-decimate --input-range pc --range pc --tcfile-in ".\temp\times.txt" -o ".\temp\video.mkv" --colormatrix smpte170m --output-csp i444 --demuxer y4m -
:: Muxing ::
".\programs\mkvmerge" -o ".\output\encode.mkv" --timecodes -1:".\temp\times.txt" ".\temp\video.mkv" ".\temp\audio.opus"
 if "%EncodeChoice%"=="1" goto Defaults
 if [%2]==[1] goto Defaults

: 512kb
:: Audio ::
".\programs\avs2pipemod" -wav encode.avs | ".\programs\qaac64" -v 0 --he -q 2 --delay -5187s --threading --no-smart-padding - -o ".\temp\audio.mp4"
echo.
echo -------------------------------
echo  Encoding Archive 512kb stream 
echo -------------------------------
echo.
:: Video ::
".\programs\replacetext" "encode.avs" "pass = 2" "pass = 0"
".\programs\replacetext" "encode.avs" "i444 = true" "i444 = false"
".\programs\avs2pipemod" -y4mp encode.avs | ".\programs\x264_x64" --threads auto --crf 20 --keyint 600 --ref 16 --no-fast-pskip --bframes 16 --b-adapt 2 --direct auto --me tesa --merange 64 --subme 11 --trellis 2 --partitions all --no-dct-decimate --range tv --input-range tv --colormatrix smpte170m -o ".\temp\video_512kb.h264" --demuxer y4m -
:: Muxing ::
for /f "tokens=2" %%i in ('%~dp0programs\avs2pipemod -info %~dp0encode.avs ^|find "fps"') do (set fps=%%i)
for /f %%k in ('%~dp0programs\div %fps%') do (set double=%%k)
".\programs\mp4box_x64" -hint -add ".\temp\video_512kb.h264":fps=%double% -add ".\temp\audio.mp4" -new ".\output\encode_512kb.mp4"
goto Defaults

: ExtraHQ
".\programs\replacetext" "encode.avs" "hq = false" "hq = true"
:: Extra 10bit444 ::
:: Audio ::
".\programs\avs2pipemod" -wav encode.avs | ".\programs\opusenc" --bitrate 64 - ".\temp\audio_extra.opus"
echo.
echo ----------------------
echo  Generating timecodes 
echo ----------------------
echo.
:: Timecodes ::
".\programs\replacetext" "encode.avs" "pass = 0" "pass = 1"
".\programs\avs2pipemod" -benchmark encode.avs
".\programs\replacetext" "encode.avs" "pass = 1" "pass = 2"
echo.
echo --------------------------------
echo  Encoding ExtraHQ downloadable 
echo --------------------------------
echo.
:: Video ::
".\programs\replacetext" "encode.avs" "i444 = false" "i444 = true"
".\programs\avs2pipemod" -y4mp encode.avs | ".\programs\x264-10_x64" --threads auto --sar "%VAR%" --crf 20 --keyint 600 --preset veryslow --input-range pc --range pc --tcfile-in ".\temp\times.txt" -o ".\temp\video_extra.mkv" --colormatrix smpte170m --output-csp i444  --demuxer y4m -
:: Muxing ::
".\programs\mkvmerge" -o ".\output\encode_extra.mkv" --timecodes -1:".\temp\times.txt" ".\temp\video_extra.mkv" ".\temp\audio_extra.opus"

:: Extra 512kb ::
:: Audio ::
".\programs\avs2pipemod" -wav encode.avs | ".\programs\sox" -t wav - -t wav - trim 4672s | ".\programs\neroAacEnc" -q 0.25 -if - -of ".\temp\audio_extra.mp4"
echo.
echo -------------------------------
echo  Encoding ExtraHQ stream 
echo -------------------------------
echo.
:: Video ::
".\programs\replacetext" "encode.avs" "pass = 2" "pass = 0"
".\programs\replacetext" "encode.avs" "i444 = true" "i444 = false"
".\programs\avs2pipemod" -y4mp encode.avs | ".\programs\x264_x64" --threads auto --crf 20 --keyint 600 --preset veryslow --range tv --input-range tv --colormatrix smpte170m -o ".\temp\video_512kb_extra.h264" --demuxer y4m -
:: Muxing ::
for /f "tokens=2" %%i in ('%~dp0programs\avs2pipemod -info %~dp0encode.avs ^|find "fps"') do (set fps=%%i)
for /f %%k in ('%~dp0programs\div %fps%') do (set double=%%k)
".\programs\mp4box_x64" -hint -add ".\temp\video_512kb_extra.h264":fps=%double% -add ".\temp\audio_extra.mp4" -new ".\output\encode_512kb_extra.mp4"

: Defaults
".\programs\replacetext" "encode.avs" "pass = 1" "pass = 0"
".\programs\replacetext" "encode.avs" "pass = 2" "pass = 0"
".\programs\replacetext" "encode.avs" "i444 = true" "i444 = false"
".\programs\replacetext" "encode.avs" "hd = true" "hd = false"
".\programs\replacetext" "encode.avs" "hq = true" "hq = false"
".\programs\replacetext" "encode.avs" "vb = true" "vb = false"