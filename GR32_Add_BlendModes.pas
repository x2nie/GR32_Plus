{
 This unit adds most popular blendmodes + some new ones to GR32.
 Some are already available in other GR32 units, but are for the
 completeness listed here.

 Some blendmodes have been created from the descriptions Adobe Photoshop
 gives in the help file.
 Others come from Jens Gruschel & Francesco Savastano(and others) from
 various newsgroup discussions...

 I provide the Reflection, Custom & Bright Light modes.
 The custom mode is a 0..255,0..255 LUT where you can load your
 own blendmaps to - The bad thing in this implementation is that
 if several layers uses custom mode with different LUTs, you
 have to take care of the temporary loading yourself.

 For descriptions and other stuff see Jens Gruschels page at:

 http://www.pegtop.net/delphi/blendmodes/

 If you have coded some interesting modes & want them added to this unit,
 pls send me the code along with a description of purpose and use
 (i.e. "Good for adding bright objects" or so).

 If you find any lines or structures that may be optimized or if
 you're an shark with asm and want to rewrite the procs - please
 contact me - lots of the rewritting is just copy/paste stuff so ... :)


 Michael Hansen.
}

unit GR32_Add_BlendModes;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{ For the blending algorithm, you could find it at:
  http://en.wikipedia.org/wiki/Alpha_compositing
  http://www.answers.com/topic/alpha-compositing

  Quote to Michael Hansen:
  ------------------------
  A correct alpha compositing solution should use the merge formula to blend
  the RGB result of the blendmode with the background ARGB, using foreground
  alpha (eventually multiplied with masteralpha variable):

  F: Foreground
  B: Background
  C: Combined
  O: Output

  Crgb = blendmode(Frgb, Brgb)

  optional master alpha:
  Fa = Fa * Ma

  Oa = Fa + Ba * (1 - Fa)
  Orgb = (Crgb * Fa + (Brgb * Ba) * (1 - Fa)) / Oa
  ------------------------------------------------

  So, according to the above formula, the blending code should be:

  rA := fA + bA - bA * fA div 255;
  rR := ( BlendR * fA + bR * bA - bR * bA * fA div 255 ) div rA;
  rG := ( BlendG * fA + bG * bA - bG * bA * fA div 255 ) div rA;
  rB := ( BlendB * fA + bB * bA - bB * bA * fA div 255 ) div rA;



  Quote to Anders Melander:
  ------------------------
  The compositing formula used by PhotoShop is [drumroll]:

  rAlpa := fAlpha + bAlpha * (1 - fAlpha);

  rColor := (1 - fAlpha / rAlpha) * bColor +
  (fAlpha / rAlpha) * ((1 - bAlpha) * fColor + bAlpha * Blend(fColor, bColor));
  ------------------------------------------------------------------------------

  So, according to the above formula, the blending code should be:

  rA := fA + bA - ba * fa div 255;
  rR := bR - bR * fA div rA + (fR - fR * bA div 255 + BlendR * bA div 255) * fA div rA;
  rG := bG - bG * fA div rA + (fG - fG * bA div 255 + BlendG * bA div 255) * fA div rA;
  rB := bB - bB * fA div rA + (fB - fB * bA div 255 + BlendB * bA div 255) * fA div rA;

  After Optimization:
  rA := fA + bA - ba * fa div 255;
  rR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  rG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  rB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  We apply the Photoshop's formula to all the code of blending methods.


  NOTE:

  Michael Hansen has correct the first formula to:

  Oa = Fa + Ba * (1 - Fa)
  Crgb = Frgb + (blendmode(Frgb, Brgb) - Frgb) * Ba
  Orgb = (Crgb * Fa + (Brgb * Ba) * (1 - Fa)) / Oa

  This formula has the same result as Anders Melander's formula, proven by
  Anders Melander.

  Quote to Anders Melander
  ------------------------

  As far as I can tell the foreground & blend terms are exactly the same (once
  expanded), but at first look the background term appears different:

  1) Foreground/blend term

  1.1) Mine:

    (fAlpha/rAlpha)(fColor*(1 - bAlpha) + bAlpha*Blend)		[1a]


  1.2) Yours:

    Fa*(Frgb + Ba*(Blend - Frgb))/Oa =				[2a]

    (Fa/Oa)(Frgb + Ba*Blend - Ba*Frgb) =				[2b]

    (Fa/Oa)(Frgb*(1 - Ba) + Ba*Blend) =				[2c]

    (fAlpha/rAlpha)(fColor*(1 - bAlpha) + bAlpha*Blend)		[2d]

  [1a] = [2d] => Our foreground and blend terms are identical.


  2) Background term

  2.1) Mine:

    bColor*(1 - fAlpha/rAlpha)					[3a]

  Expanding rAlpha we get:

    bColor*(1 - fAlpha/(fAlpha + bAlpha*(1 - fAlpha))) =		[3b]

  (handwave)

    bColor*bAlpha*(fAlpha-1)/(bAlpha*(fAlpha-1)-fAlpha)		[3c]

  2.2) Yours:

    (Brgb*Ba)(1 - Fa)/Oa =					[4a]

    Brgb*(1 - Fa)(Ba/Oa) =					[4b]

    bColor*(1 - fAlpha)(bAlpha/rAlpha)				[4c]

  Expanding rAlpha we get:

    bColor*(1 - fAlpha)(bAlpha/(fAlpha + bAlpha*(1 - fAlpha))) =	[4d]

  (handwave)

    bColor*bAlpha*(fAlpha-1)/(bAlpha*(fAlpha-1)-fAlpha))		[4e]

  [3c] = [4e] => Our background terms are identical.

  So both our compositing formulas are in fact identical.


  3) Isolating the terms we can verify that the composition formula is correct:

  Alpha:
    rAlpha := fAlpha + bAlpha*(1 - fAlpha)			[5a]
  Foreground term:
    nS := (fAlpha/rAlpha)(fColor*(1 - bAlpha))			[5b]
  Background term:
    nD := bColor*(1 - fAlpha/rAlpha)				[5c]
  Blend term:
    nB := (fAlpha/rAlpha)(bAlpha*Blend)				[5d]
  Result:
    rColor := nS + nD + nB;					[5e]

  3.1) For Normal blend mode, Blend(fColor, bColor) = fColor, the blend term
  reduces to:

    nB := (fAlpha/rAlpha)(bAlpha*fColor)				[5f]

  3.1a) Solving for (fAlpha = bAlpha = 1) we get:

    rAlpha = 1 + 1*(1-1) = 1
    nS = (1/1)(fColor*(1-1)) = 0
    nD = bColor*(1-1/1) = 0
    nB = (1/1)(1*fColor) = fColor
    rColor = 0+0+fColor = fColor

  	Correct.

  3.1b) Solving for (fAlpha = 1, bAlpha = 0) we get:

    rAlpha = 1 + 0*(1-1) = 1
    nS = (1/1)(fColor*(1-0)) = fColor
    nD = bColor*(1-1/1) = 0
    nB = (1/1)(0*fColor) = 0
    rColor = 0+fColor+0 = fColor

	  Correct.

  3.1c) Solving for (fAlpha = 0, bAlpha = 1) we get:

    rAlpha = 0 + 1*(1-0) = 1
    nS = (0/1)(fColor*(1-1)) = 0
    nD = bColor*(1-0/1) = bColor
    nB = (0/1)(1*fColor) = 0
    rColor = 0+bColor+0 = 0

	  Correct.

  3.1d) Solving for (fAlpha = 0.5, bAlpha = 0.5) we get:

    rAlpha = 0.5 + 0.5*(1-0.5) = 0.75
    nS = (0.5/0.75)(fColor*(1-0.5)) = fColor/3
    nD = bColor*(1-0.5/0.75) = bColor/3
    nB = (0.5/0.75)(0.5*fColor) = fColor/3
    rColor = fColor/3+bColor/3+fColor/3 = 2/3*fColor + 1/3*bColor

	  Correct.

  3.1e) Solving for (fAlpha = 0.5, bAlpha = 1) we get:

    rAlpha = 0.5 + 1*(1-0.5) = 1
    nS = (0.5/1)(fColor*(1-1)) = 0
    nD = bColor*(1-0.5/1) = bColor/2
    nB = (0.5/1)(1*fColor) = fColor/2
    rColor = 0+bColor/2+fColor/2 = 1/2*fColor + 1/2*bColor

	  Correct.

  3.2) For other blend modes, substitute Blend in [5d] with the blend result,
  rinse and repeat.


  I have already verified that the output of my implementation of the above
  matches that of PhotoShop.

  -----------------------------

  Commented by: Ma Xiaoguang and Ma Xiaoming
}

{ Updates:

  2013-06-06
     Added Dissolve blend mode by Ma Xiaoguang and Ma Xiaoming.
}

interface

uses
  Sysutils, Classes, GR32;

type
  TBlendMode32 = (bbmNormal32,
                  bbmMultiply32,
                  bbmScreen32,
                  bbmOverlay32,
                  bbmBrightLight32,
                  bbmSoftLightXF32,
                  bbmHardLight32,
                  bbmColorDodge32,
                  bbmColorBurn32,
                  bbmDarken32,
                  bbmLighten32,
                  bbmDifference32,
                  bbmNegation32,
                  bbmExclusion32,
                  bbmHue32,
                  bbmSaturation32,
                  bbmColor32,
                  bbmLuminosity32,
                  bbmAverage32,
                  bbmInverseColorDodge32,
                  bbmInverseColorBurn32,
                  bbmSoftColorDodge32,
                  bbmSoftColorBurn32,
                  bbmReflect32,
                  bbmGlow32,
                  bbmFreeze32,
                  bbmHeat32,
                  bbmAdditive32,
                  bbmSubtractive32,
                  bbmInterpolation32,
                  bbmStamp32,
                  bbmXOR32,
                  bbmAND32,
                  bbmOR32,
                  bbmRed32,
                  bbmGreen32,
                  bbmBlue32,
                  bbmDissolve32);

  {Blendmap - lookup table for Custom}
  TBlendmap = array [0..65535] of TColor32;

  {Just a wrapper to make procedures compatible - creation of object
   not neccessary, access via blendmode variable}
  TBlendMode = class
    procedure NormalBlend           (F: TColor32; var B: TColor32; M: TColor32);
    procedure MultiplyBlend         (F: TColor32; var B: TColor32; M: TColor32);
    procedure ScreenBlend           (F: TColor32; var B: TColor32; M: TColor32);
    procedure OverlayBlend          (F: TColor32; var B: TColor32; M: TColor32);
    procedure SoftLightBlend        (F: TColor32; var B: TColor32; M: TColor32);
    procedure HardLightBlend        (F: TColor32; var B: TColor32; M: TColor32);
    procedure BrightLightBlend      (F: TColor32; var B: TColor32; M: TColor32);
    procedure ColorDodgeBlend       (F: TColor32; var B: TColor32; M: TColor32);
    procedure ColorBurnBlend        (F: TColor32; var B: TColor32; M: TColor32);
    procedure DarkenBlend           (F: TColor32; var B: TColor32; M: TColor32);
    procedure LightenBlend          (F: TColor32; var B: TColor32; M: TColor32);
    procedure DifferenceBlend       (F: TColor32; var B: TColor32; M: TColor32);
    procedure NegationBlend         (F: TColor32; var B: TColor32; M: TColor32);
    procedure ExclusionBlend        (F: TColor32; var B: TColor32; M: TColor32);
    procedure HueBlend              (F: TColor32; var B: TColor32; M: TColor32);
    procedure SaturationBlend       (F: TColor32; var B: TColor32; M: TColor32);
    procedure ColorBlend            (F: TColor32; var B: TColor32; M: TColor32);
    procedure LuminosityBlend       (F: TColor32; var B: TColor32; M: TColor32);
    procedure AverageBlend          (F: TColor32; var B: TColor32; M: TColor32);
    procedure InverseColorDodgeBlend(F: TColor32; var B: TColor32; M: TColor32);
    procedure InverseColorBurnBlend (F: TColor32; var B: TColor32; M: TColor32);
    procedure SoftColorDodgeBlend   (F: TColor32; var B: TColor32; M: TColor32);
    procedure SoftColorBurnBlend    (F: TColor32; var B: TColor32; M: TColor32);
    procedure ReflectBlend          (F: TColor32; var B: TColor32; M: TColor32);
    procedure GlowBlend             (F: TColor32; var B: TColor32; M: TColor32);
    procedure FreezeBlend           (F: TColor32; var B: TColor32; M: TColor32);
    procedure HeatBlend             (F: TColor32; var B: TColor32; M: TColor32);
    procedure AdditiveBlend         (F: TColor32; var B: TColor32; M: TColor32);
    procedure SubtractiveBlend      (F: TColor32; var B: TColor32; M: TColor32);
    procedure InterpolationBlend    (F: TColor32; var B: TColor32; M: TColor32);
    procedure StampBlend            (F: TColor32; var B: TColor32; M: TColor32);
    procedure xorBlend              (F: TColor32; var B: TColor32; M: TColor32);
    procedure andBlend              (F: TColor32; var B: TColor32; M: TColor32);
    procedure orBlend               (F: TColor32; var B: TColor32; M: TColor32);
    procedure RedBlend              (F: TColor32; var B: TColor32; M: TColor32);
    procedure GreenBlend            (F: TColor32; var B: TColor32; M: TColor32);
    procedure BlueBlend             (F: TColor32; var B: TColor32; M: TColor32);
    procedure DissolveBlend         (F: TColor32; var B: TColor32; M: TColor32);
  end;

  function BlendModeList: TStringList;
  procedure GetBlendModeList(AList: TStrings); //safety: dont create, just fill.
  function GetBlendMode(Index: Integer): TPixelCombineEvent;
  function GetBlendIndex(Mode: TPixelCombineEvent): Integer;
  function GetBlendModeString(const Mode: TBlendMode32): string;
  
  function ARGBBlendByMode(const F, B: TColor32; const M: TColor32;
    const Mode: TBlendMode32): TColor32;

var
  Blendmode: TBlendMode;
  BlendMap : TBlendMap;

implementation

{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}

uses
  Math,  GR32_Blend;

var
  SqrtTable: array [0 .. 65535] of Byte;
  CosineTab: array [0 .. 255] of Integer;
  ProbTable: array [0..100, 0..99] of Boolean;

const
  SEmptySource = 'The source is nil';

function BlendModeList: TStringList;
begin
  Result := TStringList.Create;
  GetBlendModeList(Result);
end;

procedure GetBlendModeList(AList: TStrings);
begin
  with AList do
  begin
    BeginUpdate();
    try
    Add('Normal');
    Add('Multiply');
    Add('Screen');
    Add('Overlay');
    Add('Soft Light');
    Add('Hard Light');
    Add('Bright Light');
    Add('Color Dodge');
    Add('Color Burn');
    Add('Darken');
    Add('Lighten');
    Add('Difference');
    Add('Negation');
    Add('Exclusion');
    Add('Hue');
    Add('Saturation');
    Add('Color');
    Add('Luminosity');
    Add('Average');
    Add('Inverse Color Dodge');
    Add('Inverse Color Burn');
    Add('Soft Color Dodge');
    Add('Soft Color Burn');
    Add('Reflect');
    Add('Glow');
    Add('Freeze');
    Add('Heat');
    Add('Additive');
    Add('Subtractive');
    Add('Interpolation');
    Add('Stamp');
    Add('XOR');
    Add('AND');
    Add('OR');
    Add('Red');
    Add('Green');
    Add('Blue');
    Add('Dissolve');
    finally
      EndUpdate;
    end;
  end;
end;

function GetBlendIndex(Mode: TPixelCombineEvent): Integer;
var
  PM, PB: Pointer;
  Tmp   : TPixelCombineEvent;
begin
  { Workaround here.. couldn't find any other way to do this... }
  PM := @Mode;
  with BlendMode do
  begin
    Tmp := NormalBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 0;
      Exit;
    end;

    Tmp := MultiplyBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 1;
      Exit;
    end;

    Tmp := ScreenBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 2;
      Exit;
    end;

    Tmp := OverlayBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 3;
      Exit;
    end;

    Tmp := SoftLightBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 4;
      Exit;
    end;

    Tmp := HardLightBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 5;
      Exit;
    end;
    
    Tmp := BrightLightBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 6;
      Exit;
    end;
    
    Tmp := ColorDodgeBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 7;
      Exit;
    end;

    Tmp := ColorBurnBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 8;
      Exit;
    end;
    
    Tmp := DarkenBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 9;
      Exit;
    end;

    Tmp := LightenBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 10;
      Exit;
    end;
    
    Tmp := DifferenceBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 11;
      Exit;
    end;

    Tmp := NegationBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 12;
      Exit;
    end;

    Tmp := ExclusionBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 13;
      Exit;
    end;

    Tmp := HueBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 14;
      Exit;
    end;
    
    Tmp := SaturationBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 15;
      Exit;
    end;

    Tmp := ColorBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 16;
      Exit;
    end;
    
    Tmp := LuminosityBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 17;
      Exit;
    end;

    Tmp := AverageBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 18;
      Exit;
    end;
    
    Tmp := InverseColorDodgeBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 19;
      Exit;
    end;
    
    Tmp := InverseColorBurnBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 20;
      Exit;
    end;
    
    Tmp := SoftColorDodgeBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 21;
      Exit;
    end;
    
    Tmp := SoftColorBurnBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 22;
      Exit;
    end;
    
    Tmp := ReflectBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 23;
      Exit;
    end;
    
    Tmp := GlowBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 24;
      Exit;
    end;
    
    Tmp := FreezeBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 25;
      Exit;
    end;

    Tmp := HeatBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 26;
      Exit;
    end;
    
    Tmp := AdditiveBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 27;
      Exit;
    end;

    Tmp := SubtractiveBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 28;
      Exit;
    end;
    
    Tmp := InterpolationBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 29;
      Exit;
    end;

    Tmp := StampBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 30;
      Exit;
    end;
    
    Tmp := xorBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 31;
      Exit;
    end;

    Tmp := andBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 32;
      Exit;
    end;

    Tmp := orBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 33;
      Exit;
    end;
    
    Tmp := RedBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 34;
      Exit;
    end;

    Tmp := GreenBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 35;
      Exit;
    end;

    Tmp := BlueBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 36;
      Exit;
    end;

    Tmp := DissolveBlend;
    PB  := @Tmp;
    if PM = PB then
    begin
      Result := 37;
      Exit;
    end;
    
    Result := -1; { Unknown address }
  end;
end; 

function GetBlendMode(Index: Integer): TPixelCombineEvent;
begin
  with BlendMode do
  begin
    case Index of
      -1:
        begin
          Result := nil;
        end;

      0:
       begin
         Result := NormalBlend;
       end;

      1:
        begin
          Result := MultiplyBlend;
        end;

      2:
        begin
          Result := ScreenBlend;
        end;

      3:
        begin
          Result := OverlayBlend;
        end;

      4:
        begin
          Result := SoftLightBlend;
        end;

      5:
        begin
          Result := HardLightBlend;
        end;

      6:
        begin
          Result := BrightLightBlend;
        end;

      7:
        begin
          Result := ColorDodgeBlend;
        end;

      8:
        begin
          Result := ColorBurnBlend;
        end;

      9:
        begin
          Result := DarkenBlend;
        end;
        
      10:
        begin
          Result := LightenBlend;
        end;

      11:
        begin
          Result := DifferenceBlend;
        end;
        
      12:
        begin
          Result := NegationBlend;
        end;

      13:
        begin
          Result := ExclusionBlend;
        end;

      14:
        begin
          Result := HueBlend;
        end;

      15:
        begin
          Result := SaturationBlend;
        end;

      16:
        begin
          Result := ColorBlend;
        end;

      17:
        begin
          Result := LuminosityBlend;
        end;

      18:
        begin
          Result := AverageBlend;
        end;

      19:
        begin
          Result := InverseColorDodgeBlend;
        end;

      20:
        begin
          Result := InverseColorBurnBlend;
        end;

      21:
        begin
          Result := SoftColorDodgeBlend;
        end;

      22:
        begin
          Result := SoftColorBurnBlend;
        end;

      23:
        begin
          Result := ReflectBlend;
        end;

      24:
        begin
          Result := GlowBlend;
        end;

      25:
        begin
          Result := FreezeBlend;
        end;

      26:
        begin
          Result := HeatBlend;
        end;

      27:
        begin
          Result := AdditiveBlend;
        end;

      28:
        begin
          Result := SubtractiveBlend;
        end;
        
      29:
        begin
          Result := InterpolationBlend;
        end;

      30:
        begin
          Result := StampBlend;
        end;

      31:
        begin
          Result := xorBlend;
        end;

      32:
        begin
          Result := andBlend;
        end;

      33:
        begin
          Result := orBlend;
        end;

      34:
        begin
          Result := RedBlend;
        end;

      35:
        begin
          Result := GreenBlend;
        end;

      36:
        begin
          Result := BlueBlend;
        end;

      37:
        begin
          Result := DissolveBlend;
        end;
    end;
  end;
end;

function GetBlendModeString(const Mode: TBlendMode32): string;
var
  s: string;
begin
  case Mode of
    bbmNormal32           : s := 'Normal';
    bbmMultiply32         : s := 'Multiply';
    bbmScreen32           : s := 'Screen';
    bbmOverlay32          : s := 'Overlay';
    bbmBrightLight32      : s := 'Bright Light';
    bbmSoftLightXF32      : s := 'Soft Light XF';
    bbmHardLight32        : s := 'Hard Light';
    bbmColorDodge32       : s := 'Color Dodge';
    bbmColorBurn32        : s := 'Color Burn';
    bbmDarken32           : s := 'Darken';
    bbmLighten32          : s := 'Lighten';
    bbmDifference32       : s := 'Difference';
    bbmNegation32         : s := 'Negation';
    bbmExclusion32        : s := 'Exclusion';
    bbmHue32              : s := 'Hue';
    bbmSaturation32       : s := 'Saturation';
    bbmColor32            : s := 'Color';
    bbmLuminosity32       : s := 'Luminosity';
    bbmAverage32          : s := 'Average';
    bbmInverseColorDodge32: s := 'Inverse Color Dodge';
    bbmInverseColorBurn32 : s := 'Inverse Color Burn';
    bbmSoftColorDodge32   : s := 'Soft Color Dodge';
    bbmSoftColorBurn32    : s := 'Soft Color Burn';
    bbmReflect32          : s := 'Reflect';
    bbmGlow32             : s := 'Glow';
    bbmFreeze32           : s := 'Freeze';
    bbmHeat32             : s := 'Heat';
    bbmAdditive32         : s := 'Additive';
    bbmSubtractive32      : s := 'Subtractive';
    bbmInterpolation32    : s := 'Interpolation';
    bbmStamp32            : s := 'Stamp';
    bbmXOR32              : s := 'XOR';
    bbmAND32              : s := 'AND';
    bbmOR32               : s := 'OR';
    bbmRed32              : s := 'Red';
    bbmGreen32            : s := 'Green';
    bbmBlue32             : s := 'Blue';
    bbmDissolve32         : s := 'Dissolve';
  end;
  
  Result := s;
end;

function ARGBBlendByMode(const F, B: TColor32; const M: TColor32;
  const Mode: TBlendMode32): TColor32;
begin
  Result := B;

  case Mode of
    bbmNormal32           : BlendMode.NormalBlend(F, Result, M);
    bbmMultiply32         : BlendMode.MultiplyBlend(F, Result, M);
    bbmScreen32           : BlendMode.ScreenBlend(F, Result, M);
    bbmOverlay32          : BlendMode.OverlayBlend(F, Result, M);
    bbmBrightLight32      : BlendMode.BrightLightBlend(F, Result, M);
    bbmSoftLightXF32      : BlendMode.SoftLightBlend(F, Result, M);
    bbmHardLight32        : BlendMode.HardLightBlend(F, Result, M);
    bbmColorDodge32       : BlendMode.ColorDodgeBlend(F, Result, M);
    bbmColorBurn32        : BlendMode.ColorBurnBlend(F, Result, M);
    bbmDarken32           : BlendMode.DarkenBlend(F, Result, M);
    bbmLighten32          : BlendMode.LightenBlend(F, Result, M);
    bbmDifference32       : BlendMode.DifferenceBlend(F, Result, M);
    bbmNegation32         : BlendMode.NegationBlend(F, Result, M);
    bbmExclusion32        : BlendMode.ExclusionBlend(F, Result, M);
    bbmHue32              : BlendMode.HueBlend(F, Result, M);
    bbmSaturation32       : BlendMode.SaturationBlend(F, Result, M);
    bbmColor32            : BlendMode.ColorBlend(F, Result, M);
    bbmLuminosity32       : BlendMode.LuminosityBlend(F, Result, M);
    bbmAverage32          : BlendMode.AverageBlend(F, Result, M);
    bbmInverseColorDodge32: BlendMode.InverseColorDodgeBlend(F, Result, M);
    bbmInverseColorBurn32 : BlendMode.InverseColorBurnBlend(F, Result, M);
    bbmSoftColorDodge32   : BlendMode.SoftColorDodgeBlend(F, Result, M);
    bbmSoftColorBurn32    : BlendMode.SoftColorBurnBlend(F, Result, M);
    bbmReflect32          : BlendMode.ReflectBlend(F, Result, M);
    bbmGlow32             : BlendMode.GlowBlend(F, Result, M);
    bbmFreeze32           : BlendMode.FreezeBlend(F, Result, M);
    bbmHeat32             : BlendMode.HeatBlend(F, Result, M);
    bbmAdditive32         : BlendMode.AdditiveBlend(F, Result, M);
    bbmSubtractive32      : BlendMode.SubtractiveBlend(F, Result, M);
    bbmInterpolation32    : BlendMode.InterpolationBlend(F, Result, M);
    bbmStamp32            : BlendMode.StampBlend(F, Result, M);
    bbmXOR32              : BlendMode.xorBlend(F, Result, M);
    bbmAND32              : BlendMode.andBlend(F, Result, M);
    bbmOR32               : BlendMode.orBlend(F, Result, M);
    bbmRed32              : BlendMode.RedBlend(F, Result, M);
    bbmGreen32            : BlendMode.GreenBlend(F, Result, M);
    bbmBlue32             : BlendMode.BlueBlend(F, Result, M);
    bbmDissolve32         : BlendMode.DissolveBlend(F, Result, M);
  end;
end;

//--- Blendmodes ---------------------------------------------------------------

procedure TBlendMode.NormalBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  ba, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR;
  BlendG := fG;
  BlendB := fB;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.MultiplyBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := bR * fR div 255;
  BlendG := bG * fG div 255;
  BlendB := bB * fB div 255;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.ScreenBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := 255 - (255 - fR) * (255 - bR) div 255;
  BlendG := 255 - (255 - fG) * (255 - bG) div 255;
  BlendB := 255 - (255 - fB) * (255 - bB) div 255;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.OverlayBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  if bR < 128 then
  begin
    BlendR := bR * fR div 128;
  end
  else
  begin
    BlendR := 255 - (255 - bR) * (255 - fR) div 128;
  end;

  if bG < 128 then
  begin
    BlendG := bG * fG div 128;
  end
  else
  begin
    BlendG := 255 - (255 - bG) * (255 - fG) div 128;
  end;

  if bB < 128 then
  begin
    BlendB := bB * fB div 128;
  end
  else
  begin
    BlendB := 255 - (255 - bB) * (255 - fB) div 128;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

{ Soft Light - formula by Jens Gruschel }
procedure TBlendMode.SoftLightBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM, C                 : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;
  
  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  C      := bR * fR div 255;
  BlendR := C + bR * (  255 - ( (255 - bR) * (255 - fR) div 255 ) - C  ) div 255;

  C      := bG * fG div 255;
  BlendG := C + bG * (  255 - ( (255 - bG) * (255 - fG) div 255 ) - C  ) div 255;

  C      := bB * fB div 255;
  BlendB := C + bB * (  255 - ( (255 - bB) * (255 - fB) div 255 ) - C  ) div 255;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.HardLightBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  if fR < 128 then
  begin
    BlendR := bR * fR div 128;
  end
  else
  begin
    BlendR := 255 - (255 - bR) * (255 - fR) div 128;
  end;

  if fG < 128 then
  begin
    BlendG := bG * fG div 128;
  end
  else
  begin
    BlendG := 255 - (255 - bG) * (255 - fG) div 128;
  end;

  if fB < 128 then
  begin
    BlendB := bB * fB div 128;
  end
  else
  begin
    BlendB := 255 - (255 - bB) * (255 - fB) div 128;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

{ Bright Light - Introduced by Michael Hansen -  much like average }
procedure TBlendMode.BrightLightBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := SqrtTable[fR * bR];
  BlendG := SqrtTable[fG * bG];
  BlendB := SqrtTable[fB * bB];

  {Blend}
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.ColorDodgeBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR; 
  BlendG := fG;
  BlendB := fB;

  if fR < 255 then
  begin
    BlendR := bR * 255 div (255 - fR);

    if BlendR > 255 then
    begin
      BlendR := 255;
    end;
  end;

  if fG < 255 then
  begin
    BlendG := bG * 255 div (255 - fG);

    if BlendG > 255 then
    begin
      BlendG := 255;
    end;
  end;

  if fB < 255 then
  begin
    BlendB := bB * 255 div (255 - fB);

    if BlendB > 255 then
    begin
      BlendB := 255;
    end;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.ColorBurnBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  Temp                  : Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR;
  BlendG := fG;
  BlendB := fB;

  if fR > 0 then
  begin
    Temp := 255 - ( (255 - bR) * 255 div fR );

    if Temp < 0 then
    begin
      BlendR := 0;
    end
    else
    begin
      BlendR := Temp;
    end;
  end;

  if fG > 0 then
  begin
    Temp := 255 - ( (255 - bG) * 255 div fG );

    if Temp < 0 then
    begin
      BlendG := 0;
    end
    else
    begin
      BlendG := Temp;
    end;
  end;

  if fB > 0 then
  begin
    Temp := 255 - ( (255 - bB) * 255 div fB );

    if Temp < 0 then
    begin
      BlendB := 0;
    end
    else
    begin
      BlendB := Temp;
    end;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.DarkenBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR;
  BlendG := fG;
  BlendB := fB;

  if fR > bR then
  begin
    BlendR := bR;
  end;

  if fG > bG then
  begin
    BlendG := bG;
  end;

  if fB > bB then
  begin
    BlendB := bB;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.LightenBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR;
  BlendG := fG;
  BlendB := fB;

  if fR < bR then
  begin
    BlendR := bR;
  end;

  if fG < bG then
  begin
    BlendG := bG;
  end;

  if fB < bB then
  begin
    BlendB := bB;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA; 

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.DifferenceBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := Abs(bR - fR);
  BlendG := Abs(bG - fG);
  BlendB := Abs(bB - fB);

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

{ Negation - introduced by Jens Gruschel }
procedure TBlendMode.NegationBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := 255 - Abs(255 - bR - fR);
  BlendG := 255 - Abs(255 - bG - fG);
  BlendB := 255 - Abs(255 - bB - fB);

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.ExclusionBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := bR + fR - bR * fR div 128;
  BlendG := bG + fG - bG * fG div 128;
  BlendB := bB + fB - bB * fB div 128;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.HueBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  fH, fS, fL            : Single;
  bH, bS, bL            : Single;
  NewHSL                : TColor32;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;            
  bB := B        and $FF;

  { Combine }

  RGBToHSL(F, fH, fS, fL);        // Invert Channel To HSL
  RGBToHSL(B, bH, bS, BL);        // Invert Channel To HSL

  NewHSL := HSLToRGB(fH, bS, bL); // Combine HSL and invert it to RGB

  BlendR := NewHSL shr 16 and $FF;
  BlendG := NewHSL shr  8 and $FF;
  BlendB := NewHSL        and $FF;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.SaturationBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  fH, fS, fL            : Single;
  bH, bS, bL            : Single;
  NewHSL                : TColor32;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  RGBToHSL(F, fH, fS, fL);        // Invert Channel To HSL
  RGBToHSL(B, bH, bS, BL);        // Invert Channel To HSL

  NewHSL := HSLToRGB(bH, fS, bL); // Combine HSL and invert it to RGB

  BlendR := NewHSL shr 16 and $FF;
  BlendG := NewHSL shr  8 and $FF;
  BlendB := NewHSL        and $FF;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.ColorBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  fH, fS, fL            ,
  bH, bS, bL            : Integer;
  NewHSL                : TColor32;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
{  RGBToHSL(F, fH, fS, fL);        // Invert channel to HLS
  RGBToHSL(B, bH, bS, BL);        // Invert channel to HLS

  NewHSL := HSLToRGB(fH, fS, bL); // Combine HSL and invert it to RGB
}
  {Color mode:
  The new HSL values consist of
  F...hue of the blend image
  F...saturation of the blend image
  B...lumniance of the base image}

{  RGBToHSL(F, fH, fS, fL);        // Invert channel to HLS
  RGBToHSL(B, bH, bS, bL);        // Invert channel to HLS

  NewHSL := HSLToRGB(fH, fS, bL); // Combine HSL and invert it to RGB

{
  RGBToHSV(F, fH, fS, fL);        // Invert channel to HSV
  RGBToHSV(B, bH, bS, bL);        // Invert channel to HSV

  NewHSL := HSVToRGB(fH, fS, bL); // Combine HSL and invert it to RGB
}

  RGBtoHSLRange(WinColor(F), fH, fS, fL);        // Invert channel to HLS
  RGBtoHSLRange(WinColor(B), bH, bS, bL);        // Invert channel to HLS

  NewHSL := Color32( HSLRangeToRGB(fH, fS, bL)); // Combine HSL and invert it to RGB

  BlendR := NewHSL shr 16 and $FF;
  BlendG := NewHSL shr  8 and $FF;
  BlendB := NewHSL        and $FF;

  { Blend }
  rA := fA + bA - ba * fa div 255;                                  

  NewHSL := NewHSL and $FFFFFF or (fA shl 24);
  //B := CombineReg(NewHSL,b, fA);
  B := MergeReg(NewHSL,B);
  B := NewHSL;
  Exit;


  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.LuminosityBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  fH, fS, fL            : Single;
  bH, bS, bL            : Single;
  NewHSL                : TColor32;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  RGBToHSL(F, fH, fS, fL);        // Invert channel To HSL
  RGBToHSL(B, bH, bS, BL);        // Invert channel To HSL

  NewHSL := HSLToRGB(bH, bS, fL); // Combine HSL and invert it to RGB

  { Channel separation }
  BlendR := NewHSL shr 16 and $FF;
  BlendG := NewHSL shr  8 and $FF;
  BlendB := NewHSL        and $FF;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

{ Average - useful in some cases - but the same as Normal with MasterAlpha = 128 }
procedure TBlendMode.AverageBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := (fR + bR) div 2;
  BlendG := (fg + bG) div 2;
  BlendB := (fB + bB) div 2;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.InverseColorDodgeBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  if bR = 255 then
  begin
    BlendR := 255;
  end
  else
  begin
    BlendR := fR * 255 div (255 - bR);

    if BlendR > 255 then
    begin
      BlendR := 255;
    end;
  end;

  if bG = 255 then
  begin
    BlendG := 255;
  end
  else
  begin
    BlendG := fG * 255 div (255 - bG);

    if BlendG > 255 then
    begin
      BlendG := 255;
    end;
  end;

  if bB = 255 then
  begin
    BlendB := 255;
  end
  else
  begin
    BlendB := fB * 255 div (255 - bB);

    if BlendB > 255 then
    begin
      BlendB := 255;
    end;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.InverseColorBurnBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  Temp                  : Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  if bR = 0 then
  begin
    BlendR := 0;
  end
  else
  begin
    Temp := 255 - (255 - fR) * 255 div bR;

    if Temp < 0 then
    begin
      BlendR := 0;
    end
    else
    begin
      BlendR := Temp;
    end;
  end;

  if bG = 0 then
  begin
    BlendG := 0;
  end
  else
  begin
    Temp := 255 - (255 - fG) * 255 div bG;

    if Temp < 0 then
    begin
      BlendG := 0;
    end
    else
    begin
      BlendG := Temp;
    end;
  end;

  if bB = 0 then
  begin
    BlendB := 0;
  end
  else
  begin
    Temp := 255 - (255 - fB) * 255 div bB;

    if Temp < 0 then
    begin
      BlendB := 0;
    end
    else
    begin
      BlendB := Temp;
    end;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.SoftColorDodgeBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  Temp                  : Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR;
  BlendG := fG;
  BlendB := fB;

  if (bR + fR) < 256 then
  begin
    if fR <> 255 then
    begin
      BlendR := bR * 128 div (255 - fR);

      if BlendR > 255 then
      begin
        BlendR := 255;
      end;
    end;
  end
  else
  begin
    Temp := 255 - (255 - fR) * 128 div bR;

    if Temp < 0 then
    begin
      BlendR := 0;
    end
    else
    begin
      BlendR := Temp;
    end;
  end;

  if (bG + fG) < 256 then
  begin
    if fG <> 255 then
    begin
      BlendG := bG * 128 div (255 - fG);

      if BlendG > 255 then
      begin
        BlendG := 255;
      end;
    end;
  end
  else
  begin
    Temp := 255 - (255 - fG) * 128 div bG;

    if Temp < 0 then
    begin
      BlendG := 0;
    end
    else
    begin
      BlendG := Temp;
    end;
  end;

  if (bB + fB) < 256 then
  begin
    if fB <> 255 then
    begin
      BlendB := bB * 128 div (255 - fB);

      if BlendB > 255 then
      begin
        BlendB := 255;
      end;
    end;
  end
  else
  begin
    Temp := 255 - (255 - fB) * 128 div bB;

    if Temp < 0 then
    begin
      BlendB := 0;
    end
    else
    begin
      BlendB := Temp;
    end;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.SoftColorBurnBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  Temp                  : Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  if (bR + fR) < 256 then
  begin
    if bR = 255 then
    begin
      BlendR := 255;
    end
    else
    begin
      BlendR := fR * 128 div (255 - bR);

      if BlendR > 255 then
      begin
        BlendR := 255;
      end;
    end;
  end
  else
  begin
    Temp := 255 - (255 - bR) * 128  div fR;

    if Temp < 0 then
    begin
      BlendR := 0;
    end
    else
    begin
      BlendR := Temp;
    end;
  end;

  if (bG + fG) < 256 then
  begin
    if bG = 255 then
    begin
      BlendG := 255;
    end
    else
    begin
      BlendG := fG * 128 div (255 - bG);

      if BlendG > 255 then
      begin
        BlendG := 255;
      end;
    end;
  end
  else
  begin
    Temp := 255 - (255 - bG) * 128 div fG;

    if Temp < 0 then
    begin
      BlendG := 0;
    end
    else
    begin
      BlendG := Temp;
    end;
  end;

  if (bB + fB) < 256 then
  begin
    if bB = 255 then
    begin
      BlendB := 255;
    end
    else
    begin
      BlendB := fB * 128 div (255 - bB);

      if BlendB > 255 then
      begin
        BlendB := 255;
      end;
    end;
  end
  else
  begin
    Temp := 255 - (255 - bB) * 128 div fB;

    if Temp < 0 then
    begin
      BlendB := 0;
    end
    else
    begin
      BlendB := Temp;
    end;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

{ Reflect - introduced by Michael Hansen }
procedure TBlendMode.ReflectBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR;
  BlendG := fG;
  BlendB := fB;

  if fR <> 255 then
  begin
    BlendR := Sqr(bR) div (255 - fR);

    if BlendR > 255 then
    begin
      BlendR := 255;
    end;
  end;

  if fG <> 255 then
  begin
    BlendG := Sqr(bG) div (255 - fG);

    if BlendG > 255 then
    begin
      BlendG := 255;
    end;
  end;

  if fB <> 255 then
  begin
    BlendB := Sqr(bB) div (255 - fB);

    if BlendB > 255 then
    begin
      BlendB := 255;
    end;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.GlowBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  if bR < 255 then
  begin
    BlendR := sqr(fR) div (255 - bR);

    if BlendR > 255 then
    begin
      BlendR := 255;
    end;
  end
  else
  begin
    BlendR := 255;
  end;

  if bG < 255 then
  begin
    BlendG := sqr(fG) div (255 - bG);

    if BlendG > 255 then
    begin
      BlendG := 255;
    end;
  end
  else
  begin
    BlendG := 255;
  end;

  if bB < 255 then
  begin
    BlendB := sqr(fB) div (255 - bB);

    if BlendB > 255 then
    begin
      BlendB := 255;
    end;
  end
  else
  begin
    BlendB := 255;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.FreezeBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  Temp                  : Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR;
  BlendG := fG;
  BlendB := fB;

  if fR > 0 then
  begin
    Temp := 255 - Sqr(255 - bR) div fR;

    if Temp < 0 then
    begin
      BlendR := 0;
    end
    else
    begin
      BlendR := Temp;
    end;
  end;

  if fG > 0 then
  begin
    Temp := 255 - Sqr(255 - bG) div fG;

    if Temp < 0 then
    begin
      BlendG := 0;
    end
    else
    begin
      BlendG := Temp;
    end;
  end;

  if fB > 0 then
  begin
    Temp := 255 - Sqr(255 - bB) div fB;

    if Temp < 0 then
    begin
      BlendB := 0;
    end
    else
    begin
      BlendB := Temp;
    end;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.HeatBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  Temp                  : Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr 8  and $FF;
  bB := B        and $FF;

  { Combine }
  if bR = 0 then
  begin
    BlendR := 0;
  end
  else
  begin
    Temp := 255 - Sqr(255 - fR) div bR;

    if Temp < 0 then
    begin
      BlendR := 0;
    end
    else
    begin
      BlendR := Temp;
    end;
  end;

  if bG = 0 then
  begin
    BlendG := 0;
  end
  else
  begin
    Temp := 255 - Sqr(255 - fG) div bG;

    if Temp < 0 then
    begin
      BlendG := 0;
    end
    else
    begin
      BlendG := Temp;
    end;
  end;

  if bB = 0 then
  begin
    BlendB := 0;
  end
  else
  begin
    Temp := 255 - Sqr(255 - fB) div bB;

    if Temp < 0 then
    begin
      BlendB := 0;
    end
    else
    begin
      BlendB := Temp;
    end;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.AdditiveBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR + bR;
  BlendG := fG + bG;
  BlendB := fB + bB;

  if BlendR > 255 then
  begin
    BlendR := 255;
  end;

  if BlendG > 255 then
  begin
    BlendG := 255;
  end;

  if BlendB > 255 then
  begin
    BlendB := 255;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.SubtractiveBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  Temp                  : Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  Temp := bR + fR - 256;
  
  if Temp < 0 then
  begin
    BlendR := 0;
  end
  else
  begin
    BlendR := Temp;
  end;

  Temp := bG + fG - 256;

  if Temp < 0 then
  begin
    BlendG := 0;
  end
  else
  begin
    BlendG := Temp;
  end;

  Temp := bB + fB - 256;

  if Temp < 0 then
  begin
    BlendB := 0;
  end
  else
  begin
    BlendB := Temp;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.InterpolationBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;
  
  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := CosineTab[fR] + CosineTab[bR];
  BlendG := CosineTab[fG] + CosineTab[bG];
  BlendB := CosineTab[fB] + CosineTab[bB];
  
  if BlendR > 255 then
  begin
    BlendR := 255;
  end;

  if BlendG > 255 then
  begin
    BlendG := 255;
  end;

  if BlendB > 255 then
  begin
    BlendB := 255;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.StampBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
  Temp                  : Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  Temp := bR + fR * 2 - 255; //256;

  if Temp < 0 then
  begin
    BlendR := 0;
  end
  else if Temp > 255 then
  begin
    BlendR := 255;
  end
  else
  begin
    BlendR := Temp;
  end;

  Temp := bG + fG * 2 - 255; //256;

  if Temp < 0 then
  begin
    BlendG := 0;
  end
  else if Temp > 255 then
  begin
    BlendG := 255;
  end
  else
  begin
    BlendG := Temp;
  end;

  Temp := bB + fB * 2 - 255; //256;

  if Temp < 0 then
  begin
    BlendB := 0;
  end
  else if Temp > 255 then
  begin
    BlendB := 255;
  end
  else
  begin
    BlendB := Temp;
  end;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.xorBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := bR xor fR;
  BlendG := bG xor fG;
  BlendB := bB xor fB;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.andBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := bR and fR;
  BlendG := bG and fG;
  BlendB := bB and fB;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.orBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := bR or fR;
  BlendG := bG or fG;
  BlendB := bB or fB;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.RedBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := fR;
  BlendG := bG;
  BlendB := bB;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.GreenBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := bR;
  BlendG := fG;
  BlendB := bB;

  {Blend}
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.BlueBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  aM                    : Byte;
  fA, fR, fG, fB        : Byte;
  bA, bR, bG, bB        : Byte;
  rA, rR, rG, rB        : Byte;
  tR, tG, tB            : Integer;
  BlendR, BlendG, BlendB: Integer;
begin
  {Foreground Alpha and Master Alpha combined}
  aM := M and $FF;
  fA := F shr 24 and $FF;
  fA := fA * aM div 255;

  if fA = 0 then
  begin
    Exit;  //exit if nothing changes ...
  end;

  { Channel separation }
  fR := F shr 16 and $FF;
  fG := F shr  8 and $FF;
  fB := F        and $FF;

  bA := B shr 24 and $FF;
  bR := B shr 16 and $FF;
  bG := B shr  8 and $FF;
  bB := B        and $FF;

  { Combine }
  BlendR := bR;
  BlendG := bG;
  BlendB := fB;

  { Blend }
  rA := fA + bA - ba * fa div 255;

  tR := bR - bR * fA div rA + (fR - (fR - BlendR) * bA div 255) * fA div rA;
  tG := bG - bG * fA div rA + (fG - (fG - BlendG) * bA div 255) * fA div rA;
  tB := bB - bB * fA div rA + (fB - (fB - BlendB) * bA div 255) * fA div rA;

  if tR < 0 then
  begin
    rR := 0;
  end
  else if tR > 255 then
  begin
    rR := 255;
  end
  else
  begin
    rR := tR;
  end;

  if tG < 0 then
  begin
    rG := 0;
  end
  else if tG > 255 then
  begin
    rG := 255;
  end
  else
  begin
    rG := tG;
  end;

  if tB < 0 then
  begin
    rB := 0;
  end
  else if tB > 255 then
  begin
    rB := 255;
  end
  else
  begin
    rB := tB;
  end;

  B := (rA shl 24) or (rR shl 16) or (rG shl 8) or rB;
end;

procedure TBlendMode.DissolveBlend(F: TColor32; var B: TColor32; M: TColor32);
var
  LProbIndex  : Cardinal;
  LRandomIndex: Integer;
begin
  LProbIndex   := Round( (M and $FF) / 255 * 100 );
  LRandomIndex := Random(100);

  if not ProbTable[LProbIndex, LRandomIndex] then
  begin
    F := F and $00FFFFFF;
  end;

  BlendMode.NormalBlend(F, B, 255);  
end;

//-- initialization part -------------------------------------------------------

procedure InitTables;
var
  i, j: Integer;
  x, y: Integer;
  LTmp: Integer;
begin
  { Init SqrtTable }
  for x := 0 to 65535 do
  begin
    LTmp := Round(Sqrt(x));

    if LTmp <= 255 then
    begin
      SqrtTable[x] := LTmp;
    end
    else
    begin
      SqrtTable[x] := 255;
    end;
  end;

  { Init Custom Blendmap - like normal blend }
  for x := 0 to 255 do
  begin
    for y := 0 to 255 do
    begin
      FillChar(BlendMap[y + x shl 8], 3, x);
    end;
  end;

  { Init CosineTable }
  for i := 0 to 255 do
  begin
    CosineTab[i] := Round( 64 - Cos(i * Pi / 255) * 64 );
  end;

  { Init ProbTable -- Probability Table }
  for i := 0 to 100 do
  begin
    for j := 0 to 99 do
    begin
      if j < i then
      begin
        ProbTable[i, j] := True;
      end
      else
      begin
        ProbTable[i, j] := False;
      end;
    end;
  end;
end;

initialization
  InitTables;
  Randomize;

end.
