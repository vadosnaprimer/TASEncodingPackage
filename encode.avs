#	The downloadable/HD encoding script
#	http://tasvideos.org/EncodingGuide/PublicationManual.html

AviSource("movie.avi")

#	Dolphin (set fps properly, remove /* and */ to uncomment)
/*
V = FFVideoSource("movie.avi", fpsnum=60)
A = FFAudioSource("movie.wav")
AudioDub(V, A)
*/

trimFrame = 654321	# manual, discards logo lengh automatically
handHeld = false	# auto, but set it for preview
hd = false			# auto, but set it for preview
halfFPS = false		# for games that "lag" every other frame
stackNDS = false	# stack one of NDS screens near both of them for HD
vb = false			# for Virtual Boy encodes

#	Subtitles contents
game = "Game Name"
branch = "'branch'"	# lowercase for usual words, capital for in-game capital words. when blank, leave "''"
author = "author"
time = "00:00.0"
rerecords = "0"

#	Subtitles timing and placement
subFF = 600			# first subtitles frame, set manually!
subAlign = 8		# subtitles alignment (7/8/9)
subYpos = 0			# subtitles vertical position
subFont = "helv"	# see "fonts" folder for available types
bighaloCutoff = 384	# width and height above this will use bighalo instead of freesub

#	Multisegment import (upscales hires segments straight to HD when needed)
#	requires normally importing a sample whose attributes it will use for all segments
ms = false			# enable multisegment import
ms_base = "movie_"	# common string for all segment names
ms_start = 0		# number of the first segment
ms_end = 15			# number of the first segment
ms_format = "%1.0f"	# string format: http://avisynth.nl/index.php/Internal_functions#String

#	Extra HQ (upscaled downloadable encodes)
hq = false			# auto
hq_scale = 2		# manual for now
hq_hiResSrc = false	# we downscale hires 3D source, and upscale lowres pixelated source
hq_baseWidth = 320	# aspect-corrected 1x width (only for hires source)
hq_baseHeight = 240	# aspect-corrected 1x height (only for hires source)

#	Aspect ratio correction
wAspect = 4
hAspect = 3

#	Subtitles text
subString1	= game + "\n" \
			+ (branch == "''" ? "" : branch + "\n") \
			+ "Played by " + author \
			+ "\nPlaying time:\n " + time \
			+ "\nRerecord count:\n " + rerecords	
subString2	= "This is a tool-\nassisted recording." \
			+ "\nFor details, visit\nhttp://TASVideos.org/"

################
# LEGACY STUFF #
################

#	Famtasia
# ConvertAudioTo16bit()

#	Mupen64
# ResampleAudio(last, 44100)
# Crop(0,0,-0,-20)	# when old Glide64 is used

#	PSXjin
# audio = WavSource("movie_000.wav")
# AudioDub(audio, last)

#	Lowres Gens
# Crop(32,0,-32,0)

#	Old Dolphin (remove /* and */ to uncomment)
#	get values at http://tasvideos.org/forum/viewtopic.php?p=373299#373299
/*
M = 486000000
F = 60
k = 1
N = 525
b = 0
D = (k * N + b) * floor(floor(M / F) / N) # don't edit this formula
LoadCPlugin("./programs/timecodefps.dll")
video = last.TimecodeFPS("timecodes.txt", fpsnum=M, fpsden=D)
audio = \
	WavSource("dspdump0.wav") + \
	WavSource("dspdump1.wav").ResampleAudio(32000) + \
	WavSource("dspdump.wav")
*/

#	Fix progressing (not floating) desync
# AssumeFPS(last.FrameCount / last.AudioLengthF * last.AudioRate)

#	Deblink (not needed since youtuube went 60fps)
# blend = false	# compensate for 30 fps flickering at all. check if the run requires it!
# ngdb = true	# use smart deblink for that, otherwise will tasblend (avoid tasblend!)

######################
# AUTOMATED SETTINGS #
######################

ConvertToRGB32()

#	Add 1 scanline if height is uneven (ntsc sms, pal c64)
last.height % 2 > 0 ? StackVertical(last, Crop(0, Height-1, 0, 0)) : 0

pass = 0
i444 = false
originalWidth = last.width
originalHeight = last.height

root = ScriptDir()
Import     (root + "programs\functions.avsi")
LoadPlugin (root + "programs\ExactDedup.dll")
LoadPlugin (root + "programs\mvtools2.dll")
LoadPlugin (root + "programs\mt_masktools-26.dll")
LoadCPlugin(root + "programs\freesub.dll")

#	Deblink (uncomment corresponding variables above)
# hd && blend ? ngdb ? ng_deblink(0.5) : TasBlend() : 0

#	VirtualBoy (bizhawk only!)
#	http://tasvideos.org/forum/viewtopic.php?p=435440#435440
left  = vb ? Crop(  0, 0, 384, 224).Levels(0, 1, 255, 0, 157) : 0
right = vb ? Crop(384, 0, 384, 224).Levels(0, 1, 255, 0, 157) : 0
vb ? hd ? 0 : Anaglyph(left, right, "grey").AudioDub(left) : 0

#	Pick logo file
file = hd || hq \
	? vb \
		? "logoGrey.png" \
		: stackNDS \
			? "logohdnds.png" \
			: last.height == 384 \
				? "logonds.png" \
				: "hdlogo.png" \
	: last.height == 384 \
		? "logonds.png" \
		: "logo.png"

#	Stack 3 NDS screens
upperScreen = last.Crop(0, 0, -0, last.height/2)
lowerScreen = last.Crop(0, last.height/2, -0, -0)
halfScreen = upperScreen	# set which NDS screen to put as main
stackNDS && hd ? StackHorizontal(halfScreen.PointResize(last.width*2, last.height), last) : 0

#	Aspect ratio correction
height = hd \
	? 2160 \
	: last.width > last.height * wAspect / hAspect \
		? last.width * hAspect / wAspect \
		: last.height
width = handHeld \
	? height * last.width / last.height \
	: height * wAspect / hAspect
width  = width  % 4 == 1 ? width  + 3 : \
		 width  % 4 == 2 ? width  + 2 : \
		 width  % 4 == 3 ? width  + 1 : width
height = height % 4 == 1 ? height + 3 : \
		 height % 4 == 2 ? height + 2 : \
		 height % 4 == 3 ? height + 1 : height

#	Rescaling
#	hd: pointresize to 4K, then just subsample with lanczos in the end
#	handheld and primary (dedupped): do nothing
#	512kb: do ARC with lanczos
#	extra HQ:
#		hires source: downscale straight to aspect-corrected res with lanczos
#		lowres source: upscalse by our factor with point, then do ARC with lanczos for 512kb
g = hq && !hd \
	? hq_hiResSrc \
		? Lanczos4Resize(hq_baseWidth * hq_scale, hq_baseHeight * hq_scale) \
		: handHeld || pass != 0 \
			? PointResize(last.width * hq_scale, last.height * hq_scale) \
			: PointResize(last.width * hq_scale, last.height * hq_scale) \
				.Lanczos4Resize(width * hq_scale, height * hq_scale) \
	: hd \
		? PointResize(width, height) \
		: handHeld || pass != 0 \
			? last \
			: Lanczos4Resize(width, height)

#	If ms enabled, we use parameters of "g" to apply to all segments
g = ms ? g.AppendSegment(ms_base, ms_start, ms_end, ms_format, hd) : g

#	Logo
d = ImageSource(file=file, start=0, end=int((g.FrameRate * 2) - 1), fps=g.FrameRate) \
	.ConvertToRGB32().AssumeFPS(g.FrameRateNumerator, g.FrameRateDenominator)
e = BlankClip(d, audio_rate=g.AudioRate, channels=g.AudioChannels)
f = AudioDub(d, e).Lanczos4Resize(g.width, g.height)
f ++ g

#	Additional subtitle magic
#	figure out how much our font will be stretched after x264 ARC
wFactor  	= hd || hq ? float(last.width)  / originalWidth  : 1
hFactor		= hd || hq ? float(last.height) / originalHeight : 1
wStretch	= handHeld || pass == 0 ? 1 \
			: (float(last.width) / last.height) / (float(wAspect) / hAspect)
smallerSide = last.height < last.width ? last.height : last.width
biggerSide  = last.height > last.width ? last.height : last.width

#	use bighalo if we're relatively hires
#	or if font stretch on some side is too heavy (ARCed primary)
useBighalo  = biggerSide > bighaloCutoff \
			|| ((wStretch < 0.8 || wStretch > 1.3) \
			&& !handHeld && pass != 0 \
			&& smallerSide >= 224)

#	Subtitles variables
subRatio	= float(last.height) / 21
subXpos 	= subAlign == 7 ? 2 * wFactor : \
			  subAlign == 8 ? last.width / 2 : \
			  last.width - 2 * wFactor
subXpos 	= hd && vb ? subXpos / 2 : subXpos
subYpos		= int(float(subYpos) / (wStretch > 1 ? wStretch : 1) * hFactor)
subSize 	= useBighalo ? subRatio \
			: subRatio < 10 ?  8 \
			: subRatio < 12 ? 10 \
			: subRatio < 14 ? 12 \
			: subRatio < 18 ? 14 \
			: subRatio < 24 ? 18 : 24
subWidth	= useBighalo && !hd ? float(subSize) / 2.323 * wStretch : 0
subHaloSize = useBighalo ? floor(subSize / 7) : floor(subSize / 4.5)
subHaloSize = subHaloSize < 2 ? 2 : subHaloSize
subFontName = subFont + (smallerSide < 224 ? "R" : "B")
subFontFile = "./fonts/" + subFontName + string(subSize) + ".bdf"
subLength	= int(last.FrameRate * 5)
subFF		= vb && hd ? subFF - int(last.FrameRate * 2) : subFF
subFF2		= SubFF + subLength + 1
subColor	= vb ? $009D9D9D : $00FFFFFF
subRadius	= hd ? 0 : subHaloSize

#	Virtual Boy hacks
left = hd && vb ? \
	   f.PointResize(last.width / 2, last.height) ++ \
	left.PointResize(last.width / 2, last.height).ng_bighalo( \
		subString1, x=subXpos, y=subYpos, align=subAlign, \
		first_frame=subFF, last_frame=(subFF+subLength), \
		size=subSize, text_color=subColor, halo_color=$00000000, lsp=2 \
	).ng_bighalo( \
		subString2, x=subXpos, y=subYpos, align=subAlign, \
		first_frame=subff2, last_frame=(subff2+SubLength), \
		size=subSize, text_color=subColor, halo_color=$00000000, lsp=2 \
	) : 0

right = hd && vb ? \
	    f.PointResize(last.width / 2, last.height) ++ \
	right.PointResize(last.width / 2, last.height).ng_bighalo( \
		subString1, x=subXpos, y=subYpos, \
		align=subAlign, first_frame=subFF, last_frame=subFF+subLength, \
		size=subSize, text_color=subColor, halo_color=$00000000, lsp=2 \
	).ng_bighalo( \
		subString2, x=subXpos, y=subYpos, \
		align=subAlign, first_frame=subff2, last_frame=subff2+SubLength, \
		size=subSize, text_color=subColor, halo_color=$00000000, lsp=2 \
	) : 0

hd && vb ? yt3d(left, right).AudioDub(left) : 0

#	Subtitles functions
useBighalo ? vb ? 0 : ng_bighalo( \
	subString1, x=subXpos, y=subYpos, align=subAlign, first_frame=subFF, \
	last_frame=subFF+subLength, size=subSize, font_width=subWidth, \
	text_color=subColor, halo_color=$00000000, lsp=2, halo_radius=subRadius \
) : FreeSub( \
	subString1, x=subXpos, y=subYpos+subHaloSize, \
	font=subFontFile, halo_width=subHaloSize, halo_height=subHaloSize, \
	align=subAlign, first_frame=subFF, last_frame=subFF+subLength, \
	text_color=subColor, halo_color=$00000000, lsp=2 \
)

useBighalo ? vb ? 0 : ng_bighalo( \
	subString2, x=subXpos, y=subYpos, align=subAlign, first_frame=subff2, \
	last_frame=subff2+subLength, size=subSize, font_width=subWidth, \
	text_color=subColor, halo_color=$00000000, lsp=2, halo_radius=subRadius \
) : FreeSub( \
	subString2, x=subXpos, y=subYpos+subHaloSize, \
	font=subFontFile, halo_width=subHaloSize, halo_height=subHaloSize, \
	align=subAlign, first_frame=subff2, last_frame=subff2+SubLength, \
	text_color=subColor, halo_color=$00000000, lsp=2 \
)

Trim(0, trimFrame)
halfFPS ? SelectOdd : 0

#	Youtube can't hanble fps above 60
hd && last.FrameRate > 60 ? ChangeFPS(60) : 0

#	YV24 conversion doesn't reduce chroma, so "point" is fine
ConvertToYV24(chromaresample="point", matrix=(hd ? "Rec709" : "PC.601"))

#	Remove duplicate frames for primary
pass == 1 ? ExactDedup(firstpass=true, dupinfo="./temp/dup.txt",times="./temp/times.txt") : 0
pass == 2 ? ExactDedup(firstpass=false,dupinfo="./temp/dup.txt"                         ) : 0

#	YV12 reduces chroma, so we use "lanczos" even for HD
#	http://tasvideos.org/forum/viewtopic.php?t=19426
i444 ? last : ConvertToYV12(chromaresample="lanczos", matrix=(hd \
	? "Rec709" \
	: (pass == 0 \
		? "Rec601" \
		: "PC.601")))
