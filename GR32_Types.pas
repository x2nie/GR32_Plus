unit GR32_Types;

//----------------------------------------------------------------------------------------------------------------------

interface

uses
  Windows, Controls;

{$R Cursors.res}

const
  // Cursors (Photoshop like). The value are the same as the resource IDs.
  // This helps to avoid duplicate cursor IDs.
  crGrIBeam = TCursor(250);
  crGrCross = TCursor(251);
  crGrOpenHand = TCursor(252);                      
  crGrClosedHand = TCursor(253);
  crGrHSplit = TCursor(254);
  crGrVSplit = TCursor(255);
  crGrFinger = TCursor(256);
  crGrCrossPlus = TCursor(258);
  crGrCrossMinu = TCursor(259);
  crGrCrossCross = TCursor(260);
  crGrWand = TCursor(261);
  crGrWandPlus = TCursor(262);
  crGrWandMinus = TCursor(263);
  crGrWandCross = TCursor(264);
  crGrLasso = TCursor(265);
  crGrLassoPlus = TCursor(266);
  crGrLassoMinus = TCursor(268);
  crGrLassoCross = TCursor(269);
  crGrIBeam2 = TCursor(270);
  crGrIBeam2Plus = TCursor(271);
  crGrIBeam2Minus = TCursor(272);
  crGrIBeam2Cross = TCursor(273);
  crGrFingerRect = TCursor(274);
  crGrFingerRectPlus = TCursor(275);
  crGrFingerRectMinus = TCursor(276);
  crGrFingerRectCross = TCursor(277);
  crGrArrowQuestionMark = TCursor(278);
  crGrLightCross = TCursor(279);
  crGrLightCrossPlus = TCursor(280);
  crGrLightCrossMinus = TCursor(281);
  crGrLightCrossCross = TCursor(282);
  crGrPolygon = TCursor(283);
  crGrPolygonPlus = TCursor(284);
  crGrPolygonMinus = TCursor(285);
  crGrPolygonCross = TCursor(286);
  crGrPolygonCircle = TCursor(287);
  crGrArrowHollow = TCursor(288);
  crGrEraserStar = TCursor(290);
  crGrIBeamRect = TCursor(291);
  crGrIBeamVertical = TCursor(292);
  crGrIBeamVerticalRect = TCursor(293);
  crGrMoveCenter = TCursor(294);
  crGrMoveText = TCursor(295);
  crGrCopyText = TCursor(296);
  crGrKnife = TCursor(297);
  crGrSelectKnife = TCursor(298);
  crGrMoveKnife = TCursor(299);
  crGrSelectMoveKnife = TCursor(301);
  crGrMoveKnifeHollow = TCursor(302);
  crGrMoveEffect = TCursor(303);
  crGrEffectOpenHand = TCursor(304);
  crGrArrowFinger = TCursor(305);
  crGrMoveSelectFinger = TCursor(306);
  crGrMoveFingerHollow = TCursor(307);
  crGrMoveFingerHollowMinus = TCursor(308);
  crGrMoveFingerHollowPlus = TCursor(309);
  crGrSmallCrossCircle = TCursor(310);
  crGrArrow = TCursor(313);
  crGrZoomIn = TCursor(315);
  crGrZoomOut = TCursor(316);
  crGrMagnifier = TCursor(317);
  crGrHollowRect = TCursor(318);
  crGrNewDocRect = TCursor(319);
  crGrPencil = TCursor(320);
  crGrBrush = TCursor(321);
  crGrAirbrush = TCursor(322);
  crGrRoundDropHollow = TCursor(323);
  crGrTriDropHollow = TCursor(324);
  crGrFingerDown = TCursor(325);
  crGrPipetteEmpty = TCursor(326);
  crGrFill = TCursor(327);
  crGrSmallCross = TCursor(328);
  crGrStamp = TCursor(329);
  crGrStampHollow = TCursor(330);
  crGrCircleCross = TCursor(333);
  crGrCrop = TCursor(334);
  crGrScissor = TCursor(335);
  crGrFountainPen = TCursor(337);
  crGrFountainPenPlus = TCursor(338);
  crGrFountainPenMinus = TCursor(339);
  crGrFountainPenCircle = TCursor(341);
  crGrArrowHollowPartial = TCursor(342);
  crGrFilledCircleStick = TCursor(343);
  crGrHandPick = TCursor(344);
  crGrPipetteFilled = TCursor(345);
  crGrPipetteFilledHalf = TCursor(346);
  crGrPipetteFilledHollow = TCursor(346);
  crGrHammer = TCursor(348);
  crGrNot = TCursor(349);
  crGrDoubleArrow = TCursor(350);
  crGrSwam = TCursor(351);
  crGrMoveCrossLight = TCursor(352);
  crGrPipettePlus = TCursor(353);
  crGrPipetteMinus = TCursor(354);
  crGrEraser = TCursor(355);
  crGrEraseDocument = TCursor(356);
  crGrBlendLight = TCursor(357);
  crGrBlendDark = TCursor(358);
  crGrArrowHollow2 = TCursor(362);
  crGrArrowCut = TCursor(363);
  crGrArrowSmall = TCursor(364);
  crGrDoubleArrowSmall = TCursor(365);
  crGrArrowMove = TCursor(367);
  crArrowHollowRect = TCursor(368);
  crArrowFountainPen = TCursor(369);
  crGrMoveCross = TCursor(371);
  crGrCircle = TCursor(374);
  crGrCircleOriented = TCursor(380);
  crGrMovePointNS = TCursor(381);
  crGrMovePointWE = TCursor(382);
  crGrMovePointNWSE = TCursor(383);
  crGrMovePointNESW = TCursor(384);
  crGrArrowMoveNS = TCursor(385);
  crGrArrowMoveWE = TCursor(386);
  crGrArrowMoveNWSE = TCursor(387);
  crGrArrowMoveNESW = TCursor(389);
  crGrArrowSmallPattern = TCursor(390);
  crGrRotateE = TCursor(391);
  crGrRotateSE = TCursor(392);
  crGrRotateS = TCursor(393);
  crGrRotateSW = TCursor(394);
  crGrRotateW = TCursor(395);
  crGrRotateNW = TCursor(396);
  crGrRotateN = TCursor(397);
  crGrRotateNE = TCursor(398);

type
  // These states can be entered by the rubber band layer.
  TRubberbandDragState = (rdsNone, rdsMoveLayer, rdsMovePivot, rdsResizeN, rdsResizeNE, rdsResizeE, rdsResizeSE,
    rdsResizeS, rdsResizeSW, rdsResizeW, rdsResizeNW,
    rdsSheerN, rdsSheerE, rdsSheerS, rdsSheerW,
    rdsRotate
  );

//----------------------------------------------------------------------------------------------------------------------

implementation

uses
  SysUtils, Forms;
  
//----------------------------------------------------------------------------------------------------------------------

function LoadCursor(const Name: PChar; Index: Cardinal): HCURSOR;

// Loads a cursor from a cursor group given the group's name and the cursor's index.
// The group name has the usual form used for calls to Windows.LoadCursor.

type
  PCursorResDir = ^TCursorResDir;
  TCursorResDir = packed record
    Cursor: packed record
      Width,
      Height: Word;
    end;
    Planes: Word;
    BitCount: Word;
    BytesInRes: Cardinal;
    CursorID: Word;
  end;
  
var
  Resource: HRSRC;
  ResData: HGlobal;
  ResPointer: Pointer;
  ResDir: PCursorResDir;
  Count: Cardinal;

begin
  Result := 0;
  // Load the entire cursor group to lookup the cursor.
  Resource := FindResourceEx(HInstance, RT_GROUP_CURSOR, Name, LANG_NEUTRAL or SUBLANG_NEUTRAL shl 10);
  if Resource <> 0 then
  begin
    ResData := LoadResource(HInstance, Resource);
    if ResData <> 0 then
    begin
      ResPointer := LockResource(ResData);
      if Assigned(ResPointer) then
      begin
        // Get the number of cursors in the group (ResPointer points to a NEWHEADER structure).
        Count := PWord(PChar(ResPointer) + 4)^;
        if Index >= Count then
          Index := Count - 1;
        // Advance to the proper resource dir structure (which directly follow the header).
        ResDir := Pointer(PChar(ResPointer) + 6 + Index * SizeOf(TCursorResDir));
        
        // Find the bits for the cursor whose resource ID is given in the res dir. We can reuse the variables because
        // they are no longer needed. Resource data is automatically freed.
        Resource := FindResource(HInstance, MakeIntResource(ResDir.CursorID), RT_CURSOR);

        // Load and lock the cursor.
        ResData := LoadResource(HInstance, Resource);                                      
        ResPointer := LockResource(ResData);

        // Create a handle to the cursor.
        Result := CreateIconFromResourceEx(ResPointer, ResDir.BytesInRes, False, $30000, 0, 0, LR_DEFAULTCOLOR);
      end;
    end;
  end;                                                   
end;

//----------------------------------------------------------------------------------------------------------------------

procedure LoadCursors;
                                                                             
var
  Win2K: Boolean;

begin
  // There are two versions of each cursor in the resource. One is a plain b&w variant (index 0) and the
  // other is a shadowed variant of the same cursor (index 1).
  // The latter can be used on Windows 2000 and up.
  Win2K := ((Win32Platform and VER_PLATFORM_WIN32_NT) <> 0) and (Win32MajorVersion > 4);
  with Screen do
  begin
    Cursors[crGrIBeam] := LoadCursor(MakeIntResource(250), Ord(Win2K));
    Cursors[crGrCross] := LoadCursor(MakeIntResource(251), Ord(Win2K));
    Cursors[crGrOpenHand] := LoadCursor(MakeIntResource(252), Ord(Win2K));
    Cursors[crGrClosedHand] := LoadCursor(MakeIntResource(253), Ord(Win2K));
    Cursors[crGrHSplit] := LoadCursor(MakeIntResource(254), Ord(Win2K));
    Cursors[crGrVSplit] := LoadCursor(MakeIntResource(255), Ord(Win2K));
    Cursors[crGrFinger] := LoadCursor(MakeIntResource(256), Ord(Win2K));
    Cursors[crGrCrossPlus] := LoadCursor(MakeIntResource(258), Ord(Win2K));
    Cursors[crGrCrossMinu] := LoadCursor(MakeIntResource(259), Ord(Win2K));
    Cursors[crGrCrossCross] := LoadCursor(MakeIntResource(260), Ord(Win2K));
    Cursors[crGrWand] := LoadCursor(MakeIntResource(261), Ord(Win2K));
    Cursors[crGrWandPlus] := LoadCursor(MakeIntResource(262), Ord(Win2K));
    Cursors[crGrWandMinus] := LoadCursor(MakeIntResource(263), Ord(Win2K));
    Cursors[crGrWandCross] := LoadCursor(MakeIntResource(264), Ord(Win2K));
    Cursors[crGrLasso] := LoadCursor(MakeIntResource(265), Ord(Win2K));
    Cursors[crGrLassoPlus] := LoadCursor(MakeIntResource(266), Ord(Win2K));
    Cursors[crGrLassoMinus] := LoadCursor(MakeIntResource(268), Ord(Win2K));
    Cursors[crGrLassoCross] := LoadCursor(MakeIntResource(269), Ord(Win2K));
    Cursors[crGrIBeam2] := LoadCursor(MakeIntResource(270), Ord(Win2K));
    Cursors[crGrIBeam2Plus] := LoadCursor(MakeIntResource(271), Ord(Win2K));
    Cursors[crGrIBeam2Minus] := LoadCursor(MakeIntResource(272), Ord(Win2K));
    Cursors[crGrIBeam2Cross] := LoadCursor(MakeIntResource(273), Ord(Win2K));
    Cursors[crGrFingerRect] := LoadCursor(MakeIntResource(274), Ord(Win2K));
    Cursors[crGrFingerRectPlus] := LoadCursor(MakeIntResource(275), Ord(Win2K));
    Cursors[crGrFingerRectMinus] := LoadCursor(MakeIntResource(276), Ord(Win2K));
    Cursors[crGrFingerRectCross] := LoadCursor(MakeIntResource(277), Ord(Win2K));
    Cursors[crGrArrowQuestionMark] := LoadCursor(MakeIntResource(278), Ord(Win2K));
    Cursors[crGrLightCross] := LoadCursor(MakeIntResource(279), Ord(Win2K));
    Cursors[crGrLightCrossPlus] := LoadCursor(MakeIntResource(280), Ord(Win2K));
    Cursors[crGrLightCrossMinus] := LoadCursor(MakeIntResource(281), Ord(Win2K));
    Cursors[crGrLightCrossCross] := LoadCursor(MakeIntResource(282), Ord(Win2K));
    Cursors[crGrPolygon] := LoadCursor(MakeIntResource(283), Ord(Win2K));
    Cursors[crGrPolygonPlus] := LoadCursor(MakeIntResource(284), Ord(Win2K));
    Cursors[crGrPolygonMinus] := LoadCursor(MakeIntResource(285), Ord(Win2K));
    Cursors[crGrPolygonCross] := LoadCursor(MakeIntResource(286), Ord(Win2K));
    Cursors[crGrPolygonCircle] := LoadCursor(MakeIntResource(287), Ord(Win2K));
    Cursors[crGrArrowHollow] := LoadCursor(MakeIntResource(288), Ord(Win2K));
    Cursors[crGrEraserStar] := LoadCursor(MakeIntResource(290), Ord(Win2K));
    Cursors[crGrIBeamRect] := LoadCursor(MakeIntResource(291), Ord(Win2K));
    Cursors[crGrIBeamVertical] := LoadCursor(MakeIntResource(292), Ord(Win2K));
    Cursors[crGrIBeamVerticalRect] := LoadCursor(MakeIntResource(293), Ord(Win2K));
    Cursors[crGrMoveCenter] := LoadCursor(MakeIntResource(294), Ord(Win2K));
    Cursors[crGrMoveText] := LoadCursor(MakeIntResource(295), Ord(Win2K));
    Cursors[crGrCopyText] := LoadCursor(MakeIntResource(296), Ord(Win2K));
    Cursors[crGrKnife] := LoadCursor(MakeIntResource(297), Ord(Win2K));
    Cursors[crGrSelectKnife] := LoadCursor(MakeIntResource(298), Ord(Win2K));
    Cursors[crGrMoveKnife] := LoadCursor(MakeIntResource(299), Ord(Win2K));
    Cursors[crGrSelectMoveKnife] := LoadCursor(MakeIntResource(301), Ord(Win2K));
    Cursors[crGrMoveKnifeHollow] := LoadCursor(MakeIntResource(302), Ord(Win2K));
    Cursors[crGrMoveEffect] := LoadCursor(MakeIntResource(303), Ord(Win2K));
    Cursors[crGrEffectOpenHand] := LoadCursor(MakeIntResource(304), Ord(Win2K));
    Cursors[crGrArrowFinger] := LoadCursor(MakeIntResource(305), Ord(Win2K));
    Cursors[crGrMoveSelectFinger] := LoadCursor(MakeIntResource(306), Ord(Win2K));
    Cursors[crGrMoveFingerHollow] := LoadCursor(MakeIntResource(307), Ord(Win2K));
    Cursors[crGrMoveFingerHollowMinus] := LoadCursor(MakeIntResource(308), Ord(Win2K));
    Cursors[crGrMoveFingerHollowPlus] := LoadCursor(MakeIntResource(309), Ord(Win2K));
    Cursors[crGrSmallCrossCircle] := LoadCursor(MakeIntResource(310), Ord(Win2K));
    Cursors[crGrArrow] := LoadCursor(MakeIntResource(313), Ord(Win2K));
    Cursors[crGrZoomIn] := LoadCursor(MakeIntResource(315), Ord(Win2K));
    Cursors[crGrZoomOut] := LoadCursor(MakeIntResource(316), Ord(Win2K));
    Cursors[crGrMagnifier] := LoadCursor(MakeIntResource(317), Ord(Win2K));
    Cursors[crGrHollowRect] := LoadCursor(MakeIntResource(318), Ord(Win2K));
    Cursors[crGrNewDocRect] := LoadCursor(MakeIntResource(319), Ord(Win2K));
    Cursors[crGrPencil] := LoadCursor(MakeIntResource(320), Ord(Win2K));
    Cursors[crGrBrush] := LoadCursor(MakeIntResource(321), Ord(Win2K));
    Cursors[crGrAirbrush] := LoadCursor(MakeIntResource(322), Ord(Win2K));
    Cursors[crGrRoundDropHollow] := LoadCursor(MakeIntResource(323), Ord(Win2K));
    Cursors[crGrTriDropHollow] := LoadCursor(MakeIntResource(324), Ord(Win2K));
    Cursors[crGrFingerDown] := LoadCursor(MakeIntResource(325), Ord(Win2K));
    Cursors[crGrPipetteEmpty] := LoadCursor(MakeIntResource(326), Ord(Win2K));
    Cursors[crGrFill] := LoadCursor(MakeIntResource(327), Ord(Win2K));
    Cursors[crGrSmallCross] := LoadCursor(MakeIntResource(328), Ord(Win2K));
    Cursors[crGrStamp] := LoadCursor(MakeIntResource(329), Ord(Win2K));
    Cursors[crGrStampHollow] := LoadCursor(MakeIntResource(330), Ord(Win2K));
    Cursors[crGrCircleCross] := LoadCursor(MakeIntResource(333), Ord(Win2K));
    Cursors[crGrCrop] := LoadCursor(MakeIntResource(334), Ord(Win2K));
    Cursors[crGrScissor] := LoadCursor(MakeIntResource(335), Ord(Win2K));
    Cursors[crGrFountainPen] := LoadCursor(MakeIntResource(337), Ord(Win2K));
    Cursors[crGrFountainPenPlus] := LoadCursor(MakeIntResource(338), Ord(Win2K));
    Cursors[crGrFountainPenMinus] := LoadCursor(MakeIntResource(339), Ord(Win2K));
    Cursors[crGrFountainPenCircle] := LoadCursor(MakeIntResource(341), Ord(Win2K));
    Cursors[crGrArrowHollowPartial] := LoadCursor(MakeIntResource(342), Ord(Win2K));
    Cursors[crGrFilledCircleStick] := LoadCursor(MakeIntResource(343), Ord(Win2K));
    Cursors[crGrHandPick] := LoadCursor(MakeIntResource(344), Ord(Win2K));
    Cursors[crGrPipetteFilled] := LoadCursor(MakeIntResource(345), Ord(Win2K));
    Cursors[crGrPipetteFilledHalf] := LoadCursor(MakeIntResource(346), Ord(Win2K));
    Cursors[crGrPipetteFilledHollow] := LoadCursor(MakeIntResource(346), Ord(Win2K));
    Cursors[crGrHammer] := LoadCursor(MakeIntResource(348), Ord(Win2K));
    Cursors[crGrNot] := LoadCursor(MakeIntResource(349), Ord(Win2K));
    Cursors[crGrDoubleArrow] := LoadCursor(MakeIntResource(350), Ord(Win2K));
    Cursors[crGrSwam] := LoadCursor(MakeIntResource(351), Ord(Win2K));
    Cursors[crGrMoveCrossLight] := LoadCursor(MakeIntResource(352), Ord(Win2K));
    Cursors[crGrPipettePlus] := LoadCursor(MakeIntResource(353), Ord(Win2K));
    Cursors[crGrPipetteMinus] := LoadCursor(MakeIntResource(354), Ord(Win2K));
    Cursors[crGrEraser] := LoadCursor(MakeIntResource(355), Ord(Win2K));
    Cursors[crGrEraseDocument] := LoadCursor(MakeIntResource(356), Ord(Win2K));
    Cursors[crGrBlendLight] := LoadCursor(MakeIntResource(357), Ord(Win2K));
    Cursors[crGrBlendDark] := LoadCursor(MakeIntResource(358), Ord(Win2K));
    Cursors[crGrArrowHollow2] := LoadCursor(MakeIntResource(362), Ord(Win2K));
    Cursors[crGrArrowCut] := LoadCursor(MakeIntResource(363), Ord(Win2K));
    Cursors[crGrArrowSmall] := LoadCursor(MakeIntResource(364), Ord(Win2K));
    Cursors[crGrDoubleArrowSmall] := LoadCursor(MakeIntResource(365), Ord(Win2K));
    Cursors[crGrArrowMove] := LoadCursor(MakeIntResource(367), Ord(Win2K));
    Cursors[crArrowHollowRect] := LoadCursor(MakeIntResource(368), Ord(Win2K));
    Cursors[crArrowFountainPen] := LoadCursor(MakeIntResource(369), Ord(Win2K));
    Cursors[crGrMoveCross] := LoadCursor(MakeIntResource(371), Ord(Win2K));
    Cursors[crGrCircle] := LoadCursor(MakeIntResource(374), Ord(Win2K));
    Cursors[crGrCircleOriented] := LoadCursor(MakeIntResource(380), Ord(Win2K));
    Cursors[crGrMovePointNS] := LoadCursor(MakeIntResource(381), Ord(Win2K));
    Cursors[crGrMovePointWE] := LoadCursor(MakeIntResource(382), Ord(Win2K));
    Cursors[crGrMovePointNWSE] := LoadCursor(MakeIntResource(383), Ord(Win2K));
    Cursors[crGrMovePointNESW] := LoadCursor(MakeIntResource(384), Ord(Win2K));
    Cursors[crGrArrowMoveNS] := LoadCursor(MakeIntResource(385), Ord(Win2K));
    Cursors[crGrArrowMoveWE] := LoadCursor(MakeIntResource(386), Ord(Win2K));
    Cursors[crGrArrowMoveNWSE] := LoadCursor(MakeIntResource(387), Ord(Win2K));
    Cursors[crGrArrowMoveNESW] := LoadCursor(MakeIntResource(389), Ord(Win2K));
    Cursors[crGrArrowSmallPattern] := LoadCursor(MakeIntResource(390), Ord(Win2K));
    Cursors[crGrRotateE] := LoadCursor(MakeIntResource(391), Ord(Win2K));
    Cursors[crGrRotateSE] := LoadCursor(MakeIntResource(392), Ord(Win2K));
    Cursors[crGrRotateS] := LoadCursor(MakeIntResource(393), Ord(Win2K));
    Cursors[crGrRotateSW] := LoadCursor(MakeIntResource(394), Ord(Win2K));
    Cursors[crGrRotateW] := LoadCursor(MakeIntResource(395), Ord(Win2K));
    Cursors[crGrRotateNW] := LoadCursor(MakeIntResource(396), Ord(Win2K));
    Cursors[crGrRotateN] := LoadCursor(MakeIntResource(397), Ord(Win2K));
    Cursors[crGrRotateNE] := LoadCursor(MakeIntResource(398), Ord(Win2K));
  end;
end;

//----------------------------------------------------------------------------------------------------------------------

initialization
  LoadCursors;
end.
