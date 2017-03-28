# The downloadable/HD encoding script. For more information, see:
# http://tasvideos.org/EncodingGuide/PublicationManual.html
# Script updated 28.04.2017

 AviSource("movie.avi")
# AppendSegment("movie_", 1, 8, "%02.0f", 0, 0)						# multisegment import
# 	string format: "02" means pad with zeros up to 2 digits
# audio = WavSource("movie_000.wav")								# psxjin
# AudioDub(audio, last)												# psxjin

ConvertToRGB32()
trimframe = 472969		# manual, discards logo lengh automatically
handheld = false		# auto, but set it for preview
hd = false				# auto, but set it for preview
halffps = false			# for games that "lag" every other frame
stackNDSscreens = false	# stack one of NDS screens near both of them for HD
BizhawkPSX = false		# don't downscale PSX BIOS for youtube:
							# picks the first 4 avi segments as bios screen
							# use the rest as usual encode

# Subtitles contents
game = "Game Name"
branch = "'branch'" # lowercase for usual words, capital for in-game capital words. when blank, leave "''"
author = "author"
time = "00:00.0"
rerecords = "0"

# Subtitles timing and placement
subFF = 618							# first subtitles frame, set manually!
subAlign = 8						# subtitles alignment (7/8/9)
subYpos = 0							# subtitles vertical position
subLength = int(last.FrameRate * 5)	# auto

# Deblink
blend = false	# compensate for 30 fps flickering at all. always check if the run requires it!
ngdb = true		# use smart deblink for that, otherwise will tasblend (avoid tasblend!)

# StackVertical(last, Crop(0, Height-1, 0, 0))	# NTSC SMS with overscan enabled
# Crop(32,0,-32,0) 								# lowres genesis
# Crop(0,0,-0,-20)								# old mupen
# ResampleAudio(last,44100)						# old mupen
# hd ? 0 : LanczosResize(342,256)				# old mupen
# hd ? 0 : LanczosResize(256,384)				# hires desmume 
# AssumeFPS(last.FrameCount / last.AudioLengthF * last.AudioRate)	# progressing desync

# Dolphin. remove /* and */ to uncomment
# get values at http://tasvideos.org/forum/viewtopic.php?p=373299#373299
/*
 M = 486000000
 F = 60
 k = 1
 N = 525
 b = 0
 D = (k * N + b) * floor(floor(M / F) / N) # don't edit this formula
 LoadCPlugin("./programs/timecodefps.dll")
 video = last.TimecodeFPS("timecodes.txt", fpsnum=M, fpsden=D)
 audio = WavSource("dspdump0.wav")+WavSource("dspdump1.wav").ResampleAudio(32000)+WavSource("dspdump.wav")
*/

######################
# AUTOMATED SETTINGS #
######################

LoadPlugin ("./programs/ExactDedup.dll")
LoadPlugin ("./programs/mvtools2.dll")
LoadPlugin ("./programs/mt_masktools-26.dll")
LoadCPlugin("./programs/freesub.dll")

pass = 0

# VBjin-r103 special 3d methods
# http://tasvideos.org/forum/viewtopic.php?p=435440#435440
# at first HD pass, save left as 1.avi and right as 2.avi, both with a lossless codec
vb = false								# for all VBjin encodes
vbhdpass2 = false						# only for HD second pass. autoskips subs and logo
lname = vbhdpass2 ? "1.avi" : "L.avi"
rname = vbhdpass2 ? "2.avi" : "R.avi"
left = vb ? Greyscale(AVISource(lname)).Levels(0,1.82,255,0,255).trim(0,trimframe) : 0
right= vb ? Greyscale(AVISource(rname)).Levels(0,1.82,255,0,255).trim(0,trimframe) : 0
temp = left								# switch this with right for HD first pass
vb ? hd ? \
	(vbhdpass2 ? yt3d(left, right).AudioDub(left) : temp) : \
	Anaglyph(left, right, "grey").AudioDub(left) : 0
	
i444 = false
desyncfixer = false
OriginalHeight = last.height

factor = hd ? \
  (handheld == false) ? \
    (last.height >= 1080) ? 1 : \
    (last.height >= 540)  ? 2 : \
    (last.height >= 270)  ? 4 : \
    (last.height >= 180)  ? 6 : \
  8 : \
    (last.height >= 1440) ? 1 : \
    (last.height >=  720) ? 2 : \
    (last.height >=  360) ? 4 : \
  8 : 1

#file = "logo.png"
file = hd ? stackNDSscreens ? "logohdnds.png" : \
	(last.height == 384) ? "logonds.png" : "hdlogo.png" : \
	(last.height == 384) ? "logonds.png" : "logo.png" 

# This fixes length based audio/video desync,
# if it exists inside the encode (eg. Many PCEngine games).
num = last.AudioLengthF * last.FrameRateNumerator
denom = last.FrameCount * last.FrameRateDenominator
fixedaudiorate = Round(num / denom)
(desyncfixer) ? last.AssumeSampleRate(fixedaudiorate) : 0

Trim(0, trimframe - int(last.FrameRate * 2))
hd ? blend ? ngdb ? ng_deblink(0.5) : TasBlend() : 0 : 0

# Stack 3 NDS screens.
UpperScreen = last.Crop(0, 0, -0, last.height/2)
LowerScreen = last.Crop(0, last.height/2, -0, -0)
HalfScreen = UpperScreen							# set which NDS screen to place as main
stackNDSscreens ? (hd ? StackHorizontal(HalfScreen.PointResize(last.width*2, last.height), last) : 0) : 0

b = last.PointResize(last.width * factor, last.height * factor)

# Aspect ratio correction
width = (b.width > b.height * 4 / 3) ? b.width : b.height * 4 / 3
width = (width % 4 == 1) ? width + 3 : \
        (width % 4 == 2) ? width + 2 : \
        (width % 4 == 3) ? width + 1 : width
height = (b.width > b.height * 4 / 3) ? b.width * 3 / 4 : b.height
height = (height % 4 == 1) ? height + 3 : \
         (height % 4 == 2) ? height + 2 : \
         (height % 4 == 3) ? height + 1 : height

c = handheld ? b : b.LanczosResize(width, height, taps=2)
g = hd ? c : ((pass == 0) ? c : last)

PSXbios = BizhawkPSX ? AppendSegment("movie_", 0, 3, "%01.0f", g.width,g.height) \
	.ChangeFPS(g.FrameRateNumerator, g.FrameRateDenominator) : 0

# Logo.
d = ImageSource( \
    file=file, start=0, end=int((last.FrameRate * 2) - 1), fps=last.FrameRate \
).ConvertToRGB32().AssumeFPS( \
    last.FrameRateNumerator, last.FrameRateDenominator)
e = BlankClip(d, audio_rate=last.AudioRate, channels=last.AudioChannels)
f = AudioDub(d, blankclip(g)).LanczosResize(g.width, g.height, taps=2)
last = BizhawkPSX ? (f ++ PSXbios ++ g) : (f ++ g)

# Subtitles variables
subHaloSize = 2
subFont = (last.width <= 240) ? "helvR" : "helvB"
subSize = (last.width <= 240) ? 8 : 10
subFontFile = "./fonts/" + subFont + string(subSize) + ".bdf"
subSize = (last.width <= 240) ? 10 : 11
subLength = int(last.FrameRate * 5)
subFF2 = SubFF + subLength + 1
subString1 = game + "\n" \
	+ ((branch == "''") ? "" : (branch + "\n")) \
	+ "Played by " + author \
	+ "\nPlaying time: " + time \
	+ "\nRerecord count: " + rerecords	
subString2 = "This is a tool-\nassisted recording." \
	+ "\nFor details, visit\nhttp://TASVideos.org/"
	
subDividend = (last.width > last.height) ? last.height : last.width
subFactor = last.height / OriginalHeight
subColor = vb ? $009D9D9D : $00FFFFFF

# Subtitles function
vbhdpass2 ? 0 : \
hd ? ng_bighalo( \
    subString1, y=(subYpos * subFactor), \
    align=subAlign, first_frame=subFF, last_frame=(subFF + subLength), \
    size=(subSize * subFactor), text_color=subColor, halo_color=$00000000, lsp=2 \
) : FreeSub( \
    subString1, y=((subYpos + subHaloSize) * subFactor), \
    font=subFontFile, halo_width=subHaloSize, halo_height=subHaloSize, \
    align=subAlign, first_frame=subFF, last_frame=(subFF + subLength), \
    size=subFactor, text_color=subColor, halo_color=$00000000, lsp=2 \
)

vbhdpass2 ? 0 : \
hd ? ng_bighalo( \
    subString2, y=(subYpos * subFactor), \
    align=subAlign, first_frame=subff2, last_frame=(subff2 + SubLength), \
    size=(subSize * subFactor), text_color=subColor, halo_color=$00000000, lsp=2 \
) : FreeSub( \
    subString2, y=((subYpos + subHaloSize) * subFactor), \
    font=subFontFile, halo_width=subHaloSize, halo_height=subHaloSize, \
    align=subAlign, first_frame=subff2, last_frame=(subff2 + SubLength), \
    size=subFactor, text_color=subColor, halo_color=$00000000, lsp=2 \
)

halffps ? SelectOdd : 0
hd ? last.FrameRate > 60 ? ChangeFPS(60) : 0 : 0

# Downloadable encodes need a resizing filter for the colourspace reduction.
# HD encodes need to be point resized to keep the colour information faithful.
ConvertToYV24(chromaresample="point", matrix=(hd ? "Rec709" : "PC.601") )
(pass == 1) ? ExactDedup(firstpass=true, \
	dupinfo="./temp/dup.txt", \
	times="./temp/times.txt" \
) : last
(pass == 2) ? ExactDedup(firstpass=false, dupinfo="./temp/dup.txt") : last
i444 ? last : ConvertToYV12( \
	chromaresample=(hd ? "point" : "lanczos"), \
	matrix=(hd ? "Rec709" : (pass == 0 ? "Rec601" : "PC.601")) \
)

####################
# CUSTOM FUNCTIONS #
####################

# Multisegment AVI import
function AppendSegment(
\ string base,
\    int first_val,
\    int last_val,
\ string format,
\    int wide,
\    int high
\){
  AviSegment = base + string(first_val, format) + ".avi"
  result = wide > 0 \
  ? AviSource(AviSegment).LanczosResize(wide,high) \
  : AviSource(AviSegment)
  return (first_val < last_val) \
    ? result + AppendSegment(base,first_val+1,last_val,format,wide,high) \
    : result
}

# nanogyth's deblink.
function ng_deblink(clip clp,
\ float "ratio",
\ int "level",
\ clip "blinkmask"
\){
#Version 10 2012.04.22

    blink = default(blinkmask, clp.ng_blinkmask())

    ratio = default(ratio, 2.0 /3)
    assert(ratio >= 0.0 && 1.0 >= ratio,
    \      "[ng_deblink] 1.0 >= ratio >= 0.0, it was " + string(ratio))

    level = default(level, round(ratio * 257))
    assert(level >= 0 && 257 >= level,
    \      "[ng_deblink] 257 >= level >= 0, it was " + string(level))

    m01=mt_logic(blink.SelectEvery(4,0),
\                blink.SelectEvery(4,1),
\                mode="or").ConvertToRGB32()
    m23=mt_logic(blink.SelectEvery(4,2),
\                blink.SelectEvery(4,3),
\                mode="or").ConvertToRGB32()

    f0=Layer(clp.SelectEvery(4,0),
\            clp.SelectEvery(4,1).Mask(m01),
\            level=level)
    f1=Layer(clp.SelectEvery(4,1),
\            clp.SelectEvery(4,0).Mask(m01),
\            level=level)
    f2=Layer(clp.SelectEvery(4,2),
\            clp.SelectEvery(4,3).Mask(m23),
\            level=(257-level) )
    f3=Layer(clp.SelectEvery(4,3),
\            clp.SelectEvery(4,2).Mask(m23),
\            level=(257-level) )

    Interleave(f0,f1,f2,f3)
}

function ng_blinkmask(clip clp,
\ bool "TEST",
\ bool "STABILIZE",
\ bool "SHARP",
\ bool "HYSTER",
\ int "inpand",
\ int "expand",
\ int "ml"
\){
#Version 10 2012.04.22

#BLINK
# Blinking is a block that alternates on/off each frame
# SelectEven would only see either the on or the off

#FLASH
# Flashing is a block that is only on for a single frame
# SelectEven might miss the flash

#SHAKE
# Shaking is a block that moves back/forth each frame
# SelectEven would only see one position

# The goal of this function is to make a blink mask for use with
# ng_deblink. For overly complicated scenes where a clean blinkmask
# can't be found, just use TASBlend. Uniform softness looks better
# than sharp artifacts.

# This function calculates flash and shake info for the test script,
# but those effects should be handled in different ways.
# Flash - choose frames to make sure the flash is in your final clip.
# Shake - SelectEvery(4,0,2,1,3) or SelectEvery(4,1,0,2,3)
# SelectEvery doesn't generally work because it messes with the fluidity
# of motion. But that won't be noticable on a shaking screen.
# Be careful if 2 frame blinking is present, as the selectevery can turn
# it into 1 frame blinking.

    TEST      = default(     TEST, false)
    STABILIZE = default(STABILIZE, true)
    SHARP     = default(    SHARP, true)
    HYSTER    = default(   HYSTER, false)
    inpand    = default(   inpand, 1)
    expand    = default(   expand, 1)
    ml        = default(       ml, 128)

# The functions used to make the masks work in the YV12 colorspace. Once
# the masks are created they can be used in the RGB32 colorspace direcly
    src=clp.ConvertToYV12()

# Blinking is located by looking for blocks that don't exist in
# consecutive frames. The motion vector will match blocks that exist in
# both frames. The blocks that aren't in both will end up with huge
# values that are picked out by the motion mask.
    super = MSuper(src, pel=1)
    fvec  = MAnalyse(super, isb=false, blksize=4)
    bvec  = MAnalyse(super, isb=true , blksize=4)
    fmask = Mmask(src, fvec, kind=1, ml=ml).mt_binarize()
    bmask = Mmask(src, bvec, kind=1, ml=ml).mt_binarize()
    blink = mt_logic(fmask, bmask, mode="and")

# Blinking usually occurs against a stable background. This is found
# by looking at blocks 2 frames apart. This distinguishes a blink from
# blocks that are just changing every frame.
    ee_src   = src.SelectEven()
    ee_super = MSuper(ee_src, pel=1)
    ee_fvec  = MAnalyse(ee_super, isb=false, blksize=4)
    ee_bvec  = MAnalyse(ee_super, isb=true , blksize=4)
    ee_fmask = Mmask(ee_src, ee_fvec, kind=1, ml=ml).mt_binarize()
    ee_bmask = Mmask(ee_src, ee_bvec, kind=1, ml=ml).mt_binarize()

    oo_src   = src.SelectOdd()
    oo_super = MSuper(oo_src, pel=1)
    oo_fvec  = MAnalyse(oo_super, isb=false, blksize=4)
    oo_bvec  = MAnalyse(oo_super, isb=true , blksize=4)
    oo_fmask = Mmask(oo_src, oo_fvec, kind=1, ml=ml).mt_binarize()
    oo_bmask = Mmask(oo_src, oo_bvec, kind=1, ml=ml).mt_binarize()

    fmask_2   = Interleave(ee_fmask, oo_fmask)
    bmask_2   = Interleave(ee_bmask, oo_bmask)
    background = mt_logic(fmask_2.SelectEvery(1,1),
\                         bmask_2.SelectEvery(1,-1),
\                         mode="or")
    stable_blink = mt_hysteresis(background.mt_invert, blink)
    blink2 = (STABILIZE) ? stable_blink : blink

# Shrinking the blink mask can get rid of noise,
# too much will lose signal as well.
    blink3 = blink2.mt_inpand(mode=mt_diamond(inpand))
    
# Using just pixels that changed helps sharpen the mask
    diff   = ng_diff(clp.SelectEvery(1,-1), clp)
    diff_2 = mt_logic(diff, diff.SelectEvery(1,1), mode="and")

#Hysteresis
# Matches continuous blocks of pixels.
# Use with care, will match the whole screen on fades.
    hyster_blink = mt_hysteresis(blink3, diff_2)

# Expand the mask to make up for shrinking it (or just use hysteresis)
    blink4 = blink3.mt_expand(mode=mt_circle(expand))
    sharp_blink = mt_logic(blink4, diff_2, mode="and")

    blink5 = (HYSTER) ? hyster_blink :
\            (SHARP)  ? sharp_blink  : blink4

    
# A flash won't match blocks 1 or 2 frames away.
    sub_flash = mt_logic(fmask_2, bmask_2, mode="and")
    flash     = mt_logic(blink, sub_flash, mode="and")
    
# A shake changes in one frame and changes back in the next.
# This isn't detected by the motion vectors because the blocks exist in
# both frames, they are just shifting around.
    same   = ng_same(clp.SelectEvery(1,-1), clp.SelectEvery(1,1))
    shake  = mt_logic(same, diff_2, mode="and")

    (TEST) ? stackhorizontal(clp, mergeRGB(blink5, flash, shake))
\          : blink5.GreyScale()
}

function ng_diff(clip A, clip B, int "thr"){
    thr=default(thr,0)
    TAD=ng_TAD(A,B)
    return mt_binarize(TAD, threshold=thr)
}

function ng_same(clip A, clip B, int "thr"){
    thr=default(thr,0)
    TAD=ng_TAD(A,B)
    return mt_binarize(TAD, threshold=thr, upper=true)
}

function ng_TAD(clip A, clip B){
    R=ng_AD(A  .showRed("YV12"),B  .showRed("YV12"))
    G=ng_AD(A.showGreen("YV12"),B.showGreen("YV12"))
    B=ng_AD(A .showBlue("YV12"),B .showBlue("YV12"))
    return ng_plus(R, ng_plus(G, B))
}

function ng_AD(clip A, clip B){
    return mt_lutxy(A,B,"x y - abs")
}

function ng_plus(clip A, clip B){
    return mt_lutxy(A,B,"x y +")
}

# HD encodes need big subtitle fonts, but AviSynth can't enlarge the halo.
# Here's the custom subtitle function by nanogyth
# It's slow, but we have subtitles for a limited time only
function ng_bighalo(
\   clip clp,
\ string text,
\  float "x",
\  float "y",
\    int "first_frame",
\    int "last_frame",
\ string "font",
\  float "size",
\    int "text_color",
\    int "halo_color",
\    int "align",
\    int "spc",
\    int "lsp",
\  float "font_width",
\  float "font_angle",
\    int "halo_radius",
\ string "mode",
\ string "halo",
\ string "shadow"
\){

#Version 16-17 2012/12/1
# - added circle_12 as default
# - reworked math to avoid bitwise functions that are only
#   availible in experimental builds
#Version 15 2012/12/1
# - drop shadow added
# - halo_radius still works, but calculating the points of 
#   a hollow circle for halo is much faster
# - mode is depricated since memo-ing isn't as needed

    first_frame = default(first_frame, 0)
    last_frame  = default( last_frame, first_frame + 299)
    font        = default(       font, "Arial")
    size        = default(       size, 112)
    x           = default(          x, -1)
    y           = default(          y, -1)
    text_color  = default( text_color, $00DDDDDD)
    halo_color  = default( halo_color, $80000000)
    align       = default(      align, 5)
    spc         = default(        spc, 0)
    lsp         = default(        lsp, 0)
    font_width  = default( font_width, 0)
    font_angle  = default( font_angle, 0)
    shadow      = default(     shadow, "")
    w           = clp.width
    h           = clp.height
###
   ###
      ##
        #
         #
          #
          #
           #
           #
           #
            #
            #
#           #
circle_12="0 0 "+\
"12 0 0 12 -12 0 0 -12 "+\
"1 12 2 12 3 11 4 11 5 11 6 10 7 10 8 9 "+\
"12 1 12 2 11 3 11 4 11 5 10 6 10 7 9 8 "+\
"-1 12 -2 12 -3 11 -4 11 -5 11 -6 10 -7 10 -8 9 "+\
"-12 1 -12 2 -11 3 -11 4 -11 5 -10 6 -10 7 -9 8 "+\
"-1 -12 -2 -12 -3 -11 -4 -11 -5 -11 -6 -10 -7 -10 -8 -9 "+\
"-12 -1 -12 -2 -11 -3 -11 -4 -11 -5 -10 -6 -10 -7 -9 -8 "+\
"1 -12  2 -12 3 -11 4 -11 5 -11 6 -10 7 -10 8 -9 "+\
"12 -1  12 -2 11 -3 11 -4 11 -5 10 -6 10 -7 9 -8 "
    halo = (defined(halo_radius)) ? mt_circle(halo_radius) : circle_12

    invis = BlankClip(1, w, h, pixel_type="YV12")
    tm = Subtitle(invis, text, x, y, 0, 0, font, size, $00FFFFFF,\
        0, align, spc, lsp, font_width, font_angle)
    text_mask = tm.mt_expand(mode="0 0 "+shadow, chroma="-128")
    halo_mask = text_mask.mt_expand(mode=halo, chroma="-128")
    
    h0      = halo_color%$01000000
    h_color = (h0>=0) ? h0 : $01000000+h0
    t0      = text_color%$01000000
    t_color = (t0>=0) ? t0 : $01000000+t0
    h_alpha = (halo_color>=0) ? 255-(halo_color/$01000000) : (-halo_color-1)/$01000000
    t_alpha = (text_color>=0) ? 255-(text_color/$01000000) : (-text_color-1)/$01000000
    lut_str = string(h_alpha)+ " x * 255 / " +string(t_alpha)+\
              " " +string(h_alpha)+ " - y * 255 / +"

    alpha_mask = mt_lutxy(halo_mask, text_mask, lut_str)

    hc = BlankClip(1, w, h, color=h_color)
    tc = Subtitle(hc, text, x, y, 0, 0, font, size, t_color,\
        0, align, spc, lsp, font_width, font_angle)
    overlay = tc.Mask(alpha_mask.ConvertToRGB32())
    
    clp.ApplyRange(first_frame, last_frame, "Layer", overlay)
}

# TASBlend.
function TASBlend(clip c, float "ratio") {
    # reduces framerate to 1/2 but leaves flicker effects partly visible
    # blends frame pairs with alternating opacity
    # The default for this is 2/3+1/3;1/3+2/3)
    # optional "ratio" is the opacity of the first frame out of the four
    ratio = default(ratio, 2.0 / 3)
    opacity1 = round((1 - ratio) * 257)
    opacity2 = round((ratio) * 257)
    c
    Interleave( \
        Layer(SelectEvery(4, 0), SelectEvery(4, 1), level=opacity1), \
        Layer(SelectEvery(4, 2), SelectEvery(4, 3), level=opacity2) \
    )
}

# Replace for partial blending.
function Replace(clip dest, int start, int end, clip src) {
    Assert(start >= 0, "Replace: parameter 'start' is negative")
    Assert(  end >= 0, "Replace: parameter 'end' is negative")
    p1 = dest.Trim(0, -start)
    p2 =  src.Trim(start, end)
    p3 = dest.Trim(end + 1, 0)
    p1 = (start == 0) ? dest.Trim(0, -1).DeleteFrame(0) : p1
    p3 = (  end == 0) ? dest.Trim(0, -1).DeleteFrame(0) : p3
    p1 + p2 + p3
    return (dest.HasAudio) ? last.AudioDub(dest) : last
}

last
