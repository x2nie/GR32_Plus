unit GR32_ElasticLayers;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1 or LGPL 2.1 with linking exception
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * Alternatively, the contents of this file may be used under the terms of the
 * Free Pascal modified version of the GNU Lesser General Public License
 * Version 2.1 (the "FPC modified LGPL License"), in which case the provisions
 * of this license are applicable instead of those above.
 * Please see the file LICENSE.txt for additional information concerning this
 * license.
 *
 * The Original Code is Elastic Layer for Graphics32
 *
 * The Initial Developer of the Original Code is
 *   Fathony Luthfillah - www.x2nie.com
 *   x2nie@yahoo.com
 *
 *
 * Portions created by the Initial Developer are Copyright (C) 2014
 * the Initial Developer. All Rights Reserved.
 *
 * The code was partially taken from GR32_Layers.pas
 *   www.graphics32.org
 *   http://graphics32.org/documentation/Docs/Units/GR32_Layers/_Body.htm
 *
 * The code was partially taken from GR32_ExtLayers.pas by
 *   Mike Lischke  www.delphi-gems.com  www.lischke-online.de
 *   public@lischke-online.de
 *
 * Contributor(s):
 *
 *
 * ***** END LICENSE BLOCK ***** *)


interface

uses
  Windows, Classes, SysUtils, Controls, Forms, Graphics,
  GR32_Types, GR32, GR32_Image, GR32_Layers, GR32_Transforms, GR32_Polygons,
  GR32_Add_BlendModes;

const
  // These states can be entered by the rubber band layer.
  {
    WIND DIRECTION:         INDEX:            normal cursor:     rotated cursor:
                                                  ^                   ^
    NW    N   NE          0   4   1           \   ^   /             \   E
    W     C   E           7   8   5           <-W   E->          <-       ->
    SW    S   SE          3   6   2           /   v   \             W   \
                                                  v                   v
   9 CELLS:
   --------------
      0   1   2
      3   4   5
      6   7   8
  }
  ZoneToClockwiseIndex : array[0..8] of Integer = (0, 4, 1, 7, 8, 5, 3, 6, 2);

type

  TTicDragState = (
    {tdsResizeNW, tdsResizeN, tdsResizeNE,
    tdsResizeE, tdsResizeSE,
    tdsResizeS, tdsResizeSW, tdsResizeW,
    tdsSheerN, tdsSheerE, tdsSheerS, tdsSheerW,}
    tdsMoveLayer, tdsMovePivot,
    tdsResizeCorner, tdsRotate,
    tdsResizeSide, tdsSkew,
    tdsDistortion, tdsPerspective,
    tdsNone
  );
  TCursorDirection = (
    cdNotUsed,
    cdNorthWest,
    cdNorth,
    cdNorthEast,
    cdEast,
    cdSouthEast,
    cdSouth,
    cdSouthWest,
    cdWest
  );
  {
  TTicDragState = (
    tdsResizeNW, tdsResizeNE, tdsResizeSE, tdsResizeSW,
    tdsResizeN, tdsResizeE, tdsResizeS, tdsResizeW,
    tdsSheerN, tdsSheerE, tdsSheerS, tdsSheerW,
    tdsMoveLayer, tdsMovePivot,
    tdsRotate,
    tdsNone
  );
  }
  {
  TTicDragState = (
    tdsNone, tdsMoveLayer, tdsMovePivot,
    tdsResizeN, tdsResizeNE, tdsResizeE, tdsResizeSE,
    tdsResizeS, tdsResizeSW, tdsResizeW, tdsResizeNW,
    tdsSheerN, tdsSheerE, tdsSheerS, tdsSheerW,
    tdsRotate
  );
  }



  
  TExtRubberBandOptions = set of (
    rboAllowPivotMove,
    rboAllowCornerResize,
    rboAllowEdgeResize,
    rboAllowMove,
    rboAllowRotation,
    rboShowFrame,
    rboShowHandles
  );

const
  DefaultRubberbandOptions = [rboAllowCornerResize, rboAllowEdgeResize, rboAllowMove,
    rboAllowRotation, rboShowFrame, rboShowHandles];

type

  TTicTransformation = class;

  TElasticLayer = class(TCustomLayer)
  private
    FScaled: Boolean;
    FCropped: Boolean;
    function GetTic(index: Integer): TFloatPoint;
    procedure SetTic(index: Integer; const Value: TFloatPoint);
    procedure SetScaled(const Value: Boolean);
    procedure SetCropped(const Value: Boolean);
    
    procedure SetEdges(const Value: TArrayOfFloatPoint);
    function GetSourceRect: TFloatRect;
    procedure SetSourceRect(const Value: TFloatRect);
    function GetEdges: TArrayOfFloatPoint;
  protected
    FTransformation : TTicTransformation {T3x3Transformation};  //Non ViewPort world
    FInViewPortTransformation : TTicTransformation ;            //used in Paint() and MouseMove
    //function Matrix : TFloatMatrix; //read only property
    //FTic : array[0..3] of TFloatPoint;
    //FQuadX: array [0..3] of TFloat;
    //FQuadY: array [0..3] of TFloat;
    //FEdges: TArrayOfFloatPoint;
    procedure DoSetEdges(const Value: TArrayOfFloatPoint); virtual;

  public
    constructor Create(ALayerCollection: TLayerCollection); override;
    destructor Destroy; override;
    
    function GetScaledRect(const R: TFloatRect): TFloatRect; virtual;
    function GetScaledEdges : TArrayOfFloatPoint; 
    procedure SetBounds(APosition: TFloatPoint; ASize: TFloatPoint); overload;
    procedure SetBounds(ABoundsRect: TFloatRect); overload;

    property Tic[index : Integer] : TFloatPoint read GetTic write SetTic; // expected index: 0 .. 3
  published
    property Edges: TArrayOfFloatPoint read GetEdges write SetEdges;
    property Scaled: Boolean read FScaled write SetScaled;
    property SourceRect : TFloatRect read GetSourceRect write SetSourceRect;
    property Cropped: Boolean read FCropped write SetCropped;
  end;


  TElasticBitmapLayer = class(TElasticLayer)
  private
    FBitmap: TBitmap32;
    FBlendMode: TBlendMode32;
    procedure BitmapChanged(Sender: TObject);
    procedure SetBitmap(const Value: TBitmap32);
    procedure SetBlendMode(const Value: TBlendMode32);
  protected
    function DoHitTest(X, Y: Integer): Boolean; override;
    procedure Paint(Buffer: TBitmap32); override;
  public
    constructor Create(ALayerCollection: TLayerCollection); override;
    destructor Destroy; override;
    //procedure PaintTo(Buffer: TBitmap32; const R: TRect);
  published
    property Bitmap: TBitmap32 read FBitmap write SetBitmap;
    property BlendMode : TBlendMode32 read FBlendMode write SetBlendMode;
  end;

  TElasticRubberBandLayer = class(TElasticLayer)
  private
    FChildLayer: TElasticLayer;
    // Drag/resize support
    FIsDragging: Boolean;
    FOldEdges : TArrayOfFloatPoint;
    FDragState: TTicDragState;
    FCompass : Integer;
    {FOldPosition: TFloatPoint;         // Keep the old values to restore in case of a cancellation.
    FOldScaling: TFloatPoint;
    FOldPivot: TFloatPoint;
    FOldSkew: TFloatPoint;
    FOldAbsAnchor, FOldAnchor : TFloatPoint;
    FOldAngle: Single;}
    FDragPos: TPoint;                   // set on mouseDown
    FOriginDragPos,
    FOldOriginPivot,
    FOldInViewPortPivot,
    FOldTransformedPivot : TFloatPoint;
    FMouseOverPos : TPoint;             // set on mouseMove
    FThreshold: Integer;
    FPivotPoint: TFloatPoint;
    FOptions: TExtRubberBandOptions;
    FHandleSize: Integer;
    FHandleFrame: TColor;
    FHandleFill: TColor;

    procedure SetChildLayer(const Value: TElasticLayer);
    procedure SetOptions(const Value: TExtRubberBandOptions);
    procedure SetHandleFill(const Value: TColor);
    procedure SetHandleFrame(const Value: TColor);
    procedure SetHandleSize(Value: Integer);
    procedure SetPivotOrigin(Value: TFloatPoint);
  protected
    //function DoHitTest(X, Y: Integer): Boolean; override;
    procedure DoSetEdges(const Value: TArrayOfFloatPoint); override;
    //function GetHitCode(X, Y: Integer; Shift: TShiftState): TTicDragState;
    function GetRotatedCompass(LocalCompas: Integer) : Integer;
    function GetPivotOrigin : TFloatPoint;
    function GetPivotTransformed : TFloatPoint;
    function GetRotatedEdges( AEdges: TArrayOfFloatPoint; dx,dy : TFloat):TArrayOfFloatPoint;
    
    procedure Paint(Buffer: TBitmap32); override;
    procedure SetLayerOptions(Value: Cardinal); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;    
  public
    constructor Create(ALayerCollection: TLayerCollection); override;
    //destructor Destroy; override;
    property ChildLayer: TElasticLayer read FChildLayer write SetChildLayer;
    property Options: TExtRubberBandOptions read FOptions write SetOptions default DefaultRubberbandOptions;
    property HandleSize: Integer read FHandleSize write SetHandleSize default 3;
    property HandleFill: TColor read FHandleFill write SetHandleFill default clWhite;
    property HandleFrame: TColor read FHandleFrame write SetHandleFrame default clBlack;
    
    property PivotPoint: TFloatPoint read FPivotPoint write FPivotPoint;
    property Threshold: Integer read FThreshold write FThreshold default 8;

  end;


  // A TProjectiveTransformation that doesnt store the values in itself
  TTicTransformation = class(T3x3Transformation)
  private
    FEdges: TArrayOfFloatPoint;
    FMiddleEdges: TArrayOfFloatPoint;
    FMiddleEdgesValid : Boolean;
    procedure SetEdges(const Value: TArrayOfFloatPoint);
  protected
    //FOwner : TTicLayer;
    procedure AssignTo(Dest: TPersistent); override;

    procedure PrepareTransform; override;
    procedure ReverseTransformFixed(DstX, DstY: TFixed; out SrcX, SrcY: TFixed); override;
    procedure ReverseTransformFloat(DstX, DstY: TFloat; out SrcX, SrcY: TFloat); override;
    procedure TransformFixed(SrcX, SrcY: TFixed; out DstX, DstY: TFixed); override;
    procedure TransformFloat(SrcX, SrcY: TFloat; out DstX, DstY: TFloat); override;
  public
    //constructor Create(AOwner: TTicLayer); virtual;
    constructor Create; virtual;
    function GetTransformedBounds(const ASrcRect: TFloatRect): TFloatRect; override;
    function GetMiddleEdges: TArrayOfFloatPoint;
    //procedure Scale(Sx, Sy: TFloat); //overload;
    //procedure Scale(Value: TFloat); overload;
    //procedure Translate(Dx, Dy: TFloat);

    property Edges: TArrayOfFloatPoint read FEdges write SetEdges;
  end;

  
implementation

uses
  Math, GR32_Blend, GR32_LowLevel, GR32_Math, GR32_Bindings,
  GR32_Resamplers;

type
  TLayerCollectionAccess = class(TLayerCollection);
  TImage32Access = class(TCustomImage32);

var
  UPivotBitmap : TBitmap32 = nil;

function GetPivotBitmap : TBitmap32;
begin
  if not Assigned(UPivotBitmap) then
  begin
    UPivotBitmap := TBitmap32.Create;
    UPivotBitmap.SetSize(16,16);
    UPivotBitmap.Clear(0);
    UPivotBitmap.DrawMode := dmBlend;

    DrawIconEx(UPivotBitmap.Handle, 0,0, Screen.Cursors[crGrCircleCross], 0, 0, 0, 0, DI_NORMAL);
  end;

  Result := UPivotBitmap;
end;
  
function SafelyGetEdgeIndex(AIndex: integer):integer;
begin
  Result := AIndex;

  while Result < 0 do
    inc(Result,4);
  while Result > 3 do
    dec(Result, 4);
end;

function EdgesToFloatRect(AEdges: TArrayOfFloatPoint): TFloatRect ;
  // Rotation supported
begin
    Result.Left   := Min(Min(AEdges[0].X, AEdges[1].X), Min(AEdges[2].X, AEdges[3].X));
    Result.Right  := Max(Max(AEdges[0].X, AEdges[1].X), Max(AEdges[2].X, AEdges[3].X));
    Result.Top    := Min(Min(AEdges[0].Y, AEdges[1].Y), Min(AEdges[2].Y, AEdges[3].Y));
    Result.Bottom := Max(Max(AEdges[0].Y, AEdges[1].Y), Max(AEdges[2].Y, AEdges[3].Y));
end;


function MiddlePointOf2Lines(const x1,x2 : TFloat;
  divo: Integer = 2; mulo : Integer = 1): TFloat; overload;
begin

  if x1 < x2 then
    Result := x1 + (x2 - x1) / divo * mulo
  else
    Result := x2 + (x1 - x2) / divo * mulo;

end;



function MiddlePointOf2Lines(const x1,y1,x2,y2 : TFloat;
  divo: Integer = 2; mulo : Integer = 1): TFloatPoint; overload;
begin

  if x1 < x2 then
    Result.X := x1 + (x2 - x1) / divo * mulo
  else
    Result.X := x2 + (x1 - x2) / divo * mulo;

  if y1 < y2 then
    Result.Y := y1 + (y2 - y1) / divo * mulo
  else
    Result.Y := y2 + (y1 - y2) / divo * mulo;
end;

function MiddlePointOf2Lines(const P1,P2 : TFloatPoint;
    divo: Integer = 2; mulo : Integer = 1): TFloatPoint; overload;
begin
  Result := MiddlePointOf2Lines(P1.X, P1.Y, P2.X, P2.Y, divo, mulo );
{
  x1 := Min(A.X, B.X);
  y1 := Min(A.Y, B.Y);
  x2 := Max(A.X, B.X);
  y2 := Max(A.Y, B.Y);

  //Result.X := x1 -1 + (x2 - x1 + 1) /2; //precise pixels width
  //Result.Y := y1 -1 + (y2 - y1 + 1) /2; //precise pixels height
  Result.X := x1 + (x2 - x1 ) /2;
  Result.Y := y1 + (y2 - y1 ) /2;
  }
end;

function CentroidOf(AEdges: TArrayOfFloatPoint): TFloatPoint ;
  // use bounding. non skew, non perspective
begin
  with EdgesToFloatRect(AEdges) do
  begin
    Result.X := Left + (Right - Left) / 2;
    Result.Y := Top  + (Bottom - Top) / 2;
  end;
end;

function CenterOf(MiddleEdges: TArrayOfFloatPoint): TFloatPoint ;
  // direct distance
  // skew+distortion+perspective supported
begin
  Result.X := MiddlePointOf2Lines(MiddleEdges[0].X, MiddleEdges[2].X);
  Result.Y := MiddlePointOf2Lines(MiddleEdges[1].Y, MiddleEdges[3].Y);
end;

function DegreeOfBuggy(MidPoint,OppositePoint: TFloatPoint): TFloat;
var
  Radians : TFloat;
begin
  Radians := ArcTan2( OppositePoint.Y - MidPoint.Y, MidPoint.X - OppositePoint.X );
  Result := RadToDeg( Radians );
end;

function DegreeOf(Center,OppositePoint: TFloatPoint): TFloat;
var
  Radians : TFloat;
begin
  //Radians := ArcTan2( OppositePoint.Y - MidPoint.Y, MidPoint.X - OppositePoint.X );
  //Radians := ArcTan2( MidPoint.Y - OppositePoint.Y, OppositePoint.X - MidPoint.X );
  Radians := ArcTan2( Center.Y - OppositePoint.Y, OppositePoint.X - Center.X );

  //this follows degree quadrant used by GR32 to draw arc= WRONG.
  //Result := RadToDeg( Radians ) * -1;

  //this follows degree quadrant used by GR32 to rotate in TAffineTransformation = OKE!
  Result := RadToDeg( Radians ) ;
  while Result < 0 do
    Result := Result + 360;
  while Result > 360 do
    Result := Result - 360;
end;

function PtIn9Zones(P: TFloatPoint; TT: TTicTransformation; var MouseInside : Boolean): Integer ; overload;
const FTreshold : TFloat = 8;
var
  Mids,LEdges : TArrayOfFloatPoint;
  Xdeg, Ydeg, prevDeg, nextDeg, dx,dy, compassDeg, half, pDeg : TFloat;
  X,Y,Center : TFloatPoint;
  AT : TAffineTransformation;
  prev,next, cx,cy,Zone,Compass : Integer;
begin
  AT := TAffineTransformation.Create;
  Mids := TT.GetMiddleEdges;
  LEdges := TT.Edges;
  Xdeg := DegreeOf(Mids[3], Mids[1]);

  AT.Rotate(Mids[3].X, Mids[3].Y, -Xdeg);
  Y := AT.Transform(P);
  Dy := Mids[3].Y - Y.Y;
  if Abs(dy) <= FTreshold then
    cy := 1
  else
  if Dy > 0 then
    cy := 0
  else
    cy := 2;

  Ydeg := DegreeOf(Mids[2], Mids[0]);

  AT.Clear;
  AT.Rotate(Mids[2].X, Mids[2].Y, -Ydeg);
  X := AT.Transform(P);
  Dx := Mids[2].Y - X.Y ;
  if Abs(Dx) <= FTreshold then
    cx := 1
  else
  if Dx > 0 then
    cx := 0
  else
    cx := 2;

  // get index in: left-to-right-then-bottom order
  Zone := cx + cy * 3;
  // get index
  Compass := ZoneToClockwiseIndex[Zone];

  Result := Compass;
  MouseInside := PtInRect(TT.SrcRect, TT.ReverseTransform(P) );
  
  // correct by toleranced-degree if cx=0 or cy=0 =========================================




  // I am worry only about the range of Edges; its too wide.
  // It also report as "false positive" due the middleEdges is too narrow,
  // while calculated by FTreshold. So, this is the correction
  if Compass <=3 then
  begin
    Center  := CenterOf(Mids);
    pDeg    := Abs( DegreeOf(Center, P) );
    compassDeg:= Abs( DegreeOf(Center, LEdges[Compass]) );

    //debug
    //MouseInside := pDeg < compassDeg;
    //exit;

    if pDeg > compassDeg then
    begin

      // compas = edge; prev&next = mid
      prev := SafelyGetEdgeIndex(Compass -1);
      prevDeg := Abs(DegreeOf(Center, Mids[prev]));
      half := Abs( compassDeg - prevDeg) /2;

      if pDeg > compassDeg + half then
        Result := prev +4 ;

    end
    else
    begin
      next := SafelyGetEdgeIndex(Compass );
      nextDeg := Abs( DegreeOf(Center, Mids[next]) );

      half := Abs( compassDeg - nextDeg) /2;

      if pDeg < nextDeg + half then
      begin
        Result := next +4 ;
      end;
    end;


  end;
  (*else
  begin
    // compas = mid; prev&next = edge
    prev := SafelyGetEdgeIndex(Compass  -4);
    next := SafelyGetEdgeIndex(Compass  -3);
    prevDeg := DegreeOf(Center, Ledges[prev]);
    nextDeg := DegreeOf(Center, Ledges[next]);
    compassDeg:= DegreeOf(Center, Mids[SafelyGetEdgeIndex(Compass-4)]);
    half := Abs( compassDeg - prevDeg) /2;

    Result := prev ;

    if Abs( pDeg - compassDeg) < half then
    begin
      Result := Compass

    end
    else
    begin
      Result := next;
      half := Abs( compassDeg - nextDeg) /2;

      if Abs( pDeg - compassDeg) < half then
      begin
        Result := Compass 
      end;

    end;
  end;


   *)



end;


function PtIn9ZonesBuggy(P: TPoint; SrcRect: TRect; var MouseInside : Boolean): Integer ; overload;

  // Non rotated world, cells clamped to range of [0..2]
  {   0   1   2
      3   4   5
      6   7   8   }
var
  W,H, X,Y, cx, cy : Integer;
  dx,dy : TFloat;
begin

  // get bounds of whole grid
  with SrcRect do
  begin
    W := Right - Left;
    H := Bottom - Top;

    // in case Transformation.SrcRect.TopLeft < Point(0,0)
    X := P.X - Left;
    Y := P.Y - Top;
  end;

  // get bounds of a cell.
  // Precisely. don't div here
  dx := W / 3;
  dy := H / 3;

  //get cell contained XY
  cx := Floor(X / dx);
  cy := Floor(Y / dy);

  //detect wether mouse in rect
  MouseInside := (cx in [0..2]) and (cy in [0..2]);

  cx := Clamp(cx, 0, 2);
  cy := Clamp(cy, 0, 2);

  // get index in: left-to-right-then-bottom order
  Result := cx + cy * 3;
end;

{function PtIn9Zones(X,Y:TFloat;OriginEdges: TArrayOfFloatPoint): Integer ; overload;

  // Non rotated world, cells clamped to range of [0..2]
var
  R : TRect;
  W,H, i, cx, cy : Integer;
  dx,dy : TFloat;
begin
  Result := -1;

  R := MakeRect(FloatRect(OriginEdges[0], OriginEdges[2]));

  // in case Transformation.SrcRect.TopLeft < Point(0,0)
  X := X - R.Left;
  Y := Y - R.Top;

  // get bounds of whole grid
  with R do
  begin
    W := Right - Left;
    H := Bottom - Top;
  end;

  // get bounds of a cell.
  // Precisely. don't div here
  dx := W / 3;
  dy := H / 3;

  //get cell contained XY
  cx := Round(X / dx);
  cy := Round(Y / dy);

  Clamp(cx, 0, 2);
  Clamp(cy, 0, 2);

  // get index in: left-to-right-then-bottom order
  Result := cx + cy * 3;
end;}

function LineDistance(const A,B: TFloatPoint; UsingRadius: Boolean = False): TFloat ;
var
  i,j,c:TFloat;
begin
  i:=A.X - B.X;
  j:=A.Y - B.Y;
  if i < 0 then i := i * -1;
  if j < 0 then j := j * -1;
  if UsingRadius then
  begin
    c:=sqr(i)+sqr(j);
    //if c > 0 then
      Result :=  sqrt(c)
    //else
      //Result := 0;
  end
  else
    Result := Max(i,j);
end;




procedure IncF(var P : TFloatPoint; dx, dy : TFloat); overload;
begin
  P.X  := P.X + dx;
  P.Y  := P.Y + dy;
end;

{procedure Inc(AEdges : TArrayOfFloatPoint; Index: Integer; dx, dy : TFloat); overload;
begin
  AEdges[Index].X  := AEdges[Index].X + dx;
  AEdges[Index].Y  := AEdges[Index].Y + dy;
end;

procedure Inc(var F : TFloat; Delta : TFloat); overload;
begin
  F  := F + Delta;
end;


procedure Inc(var X: Integer; N: Integer =1); overload;
begin
  System.Inc(X,N);
end; }

function IncOf(APointF : TFloatPoint; dx, dy : TFloat):TFloatPoint;
begin
  Result.X  := APointF.X + dx;
  Result.Y  := APointF.Y + dy;
end;

function MoveEdges(AEdges : TArrayOfFloatPoint; dx, dy : TFloat): TArrayOfFloatPoint;
var i : Integer;
begin
  //Result := AEdges;         //Wrong, share the content
  //SetLength(Result,4);
  //Move(AEdges[0], Result[0], 4 * SizeOf(TFloatPoint) );
  Result := Copy(AEdges,0,4);

  for i := 0 to 3 do
  begin
    Result[i].X  := Result[i].X + dx;
    Result[i].Y  := Result[i].Y + dy;
  end;
end;






function SlopeOf(I, Opposite: TFloatPoint): TFloatPoint;
begin
  Result := FloatPoint(I.X - Opposite.X, I.Y - Opposite.Y  );
end;

function Straight90degreeAt(MidPoint,OppositePoint,MousePoint : TFloatPoint ): TFloatPoint;
var
  Radians, Angle : TFloat;
  hypotenuse, opposite, adjacent : TFloat;
  TT : TAffineTransformation;
  M : TFloatPoint;
begin
  Result := MousePoint;
  
  Radians := ArcTan2( OppositePoint.Y - MidPoint.Y, MidPoint.X - OppositePoint.X );
  Angle := RadToDeg( Radians );

  with OppositePoint do
    //inc(MousePoint, -X, -Y);
    MousePoint := IncOf(MousePoint, -X, -Y);

      
  TT := TAffineTransformation.Create;
  try
    TT.Rotate(-Angle);

    M := TT.Transform( MousePoint );
    M.Y := 0;

    TT.Clear;
    TT.Rotate(Angle);
    TT.Translate(OppositePoint.X, OppositePoint.Y);
    Result := TT.Transform(M);
    //Result := M;
  finally
    TT.Free;
  end;
end;

function StraightPointWithTailDegrees(MidPoint,OppositePoint,TailPoint, MousePoint : TFloatPoint ): TFloatPoint;
    // P is the point of intersection
    function Intersect(const A1, A2, B1, B2: TFloatPoint; out P: TFloatPoint): Boolean;
    var
      Adx, Ady, Bdx, Bdy, ABy, ABx: TFloat;
      t, ta, tb: TFloat;
    begin
      Result := False;
      Adx := A2.X - A1.X;
      Ady := A2.Y - A1.Y;
      Bdx := B2.X - B1.X;
      Bdy := B2.Y - B1.Y;
      t := (Bdy * Adx) - (Bdx * Ady);

      if t = 0 then Exit; // lines are parallell

      ABx := A1.X - B1.X;
      ABy := A1.Y - B1.Y;
      ta := Bdx * ABy - Bdy * ABx;
      tb := Adx * ABy - Ady * ABx;
    //  if InSignedRange(ta, 0, t) and InSignedRange(tb, 0, t) then
      begin
        Result := True;
        ta := ta / t;
        P.X := A1.X + ta * Adx;
        P.Y := A1.Y + ta * Ady;
      end;
    end;
var
  Radians, Angle, Angle1, Angle2 : TFloat;
  hypotenuse, opposite, adjacent : TFloat;
  TT : TAffineTransformation;
  M,M1,M2,distance : TFloatPoint;
begin
  Radians := ArcTan2( OppositePoint.Y - MidPoint.Y, MidPoint.X - OppositePoint.X );
  Angle1 := RadToDeg( Radians );

  Radians := ArcTan2( TailPoint.Y - MidPoint.Y, MidPoint.X - TailPoint.X );
  Angle2 := RadToDeg( Radians ) - 90;
                
  {M := MousePoint;
  with MidPoint do
    inc(M, -X, -Y);}
  with MidPoint do
  M := IncOf(MousePoint, -X, -Y);

  TT := TAffineTransformation.Create;
  try
    //TT.Translate(-OppositePoint.X, -OppositePoint.Y);


    TT.Clear;
    TT.Rotate(0,0, -Angle2);
    M2 := TT.Transform( M );
    M2.Y := 0;

    TT.Clear;
    TT.Rotate(0,0, Angle2);
    TT.Translate(MidPoint.X , MidPoint.Y);
    M2 := TT.Transform(M2); // X oke here
    //--------------------------------------
    //second pass
    {distance := FloatPoint(M1.X - M.X, M1.Y - M.Y);

    TT.Clear;
    TT.Translate(-distance.X, -distance.Y);
    Angle := Angle2 - 180;
    TT.Rotate(0,0, Angle);
    TT.Translate(distance.X, distance.Y);
    M2 := TT.Transform( M1 );}


    //Result := M1;
    if not Intersect(MousePoint,M2, MidPoint,OppositePoint, Result) then
    //Result := FloatPoint(M2.Y, M1.Y);
    begin
      TT.Clear;
      TT.Rotate(0,0, -Angle1);
      M1 := TT.Transform( M );
      M1.Y := 0;

      TT.Clear;
      TT.Rotate(0,0, Angle1);
      TT.Translate(MidPoint.X , MidPoint.Y);
      M1 := TT.Transform(M1); // Y oke here
      //--------------------------------------
      Result := M1;
    end;
  finally
    TT.Free;
  end;
end;

function Move2Edges(AEdges : TArrayOfFloatPoint; Start: Integer;
  dx, dy : TFloat): TArrayOfFloatPoint;
var i,s : Integer;
begin
  Result := Copy(AEdges,0,4);

  for i := Start to Start + 1 do
  begin
    s := SafelyGetEdgeIndex(i);
    IncF(Result[s], dx,dy);
  end;
end;

function ResizeBySide(AEdges : TArrayOfFloatPoint; Start: Integer;
  dx, dy : TFloat; AStraight: Boolean): TArrayOfFloatPoint;

  // RESIZE

var i,k : Integer;
  m1, m2, mid, ops, pair, needed, adjusted : TFloatPoint;
  ax,ay : TFloat;
begin


  if Odd(Start) then
  // locally horizontal resize
  begin
    m1 := MiddlePointOf2Lines(Aedges[0], AEdges[3]);
    m2 := MiddlePointOf2Lines(Aedges[1], AEdges[2]);
  end
  else
  // locally vertical resize
  begin
    m1 := MiddlePointOf2Lines(Aedges[0], AEdges[1]);
    m2 := MiddlePointOf2Lines(Aedges[2], AEdges[3]);
  end;

  if Start in [1,2] then
  begin
    mid := m2;
    ops := m1;
  end
  else  //start = 3
  begin
    mid := m1;
    ops := m2;
  end;

  needed := IncOf(mid, dx,dy);

  if AStraight then
  begin
    //adjusted := StraightLinePointAt(mid, ops, needed);
    adjusted := StraightPointWithTailDegrees(mid, ops, AEdges[start], needed);
  end
  else
  begin
    adjusted := needed;
  end;

  dx := adjusted.X -mid.X;
  dy := adjusted.Y -mid.Y;

  Result := Move2Edges(AEdges, Start, dx, dy);

end;

function SkewBySide(AEdges : TArrayOfFloatPoint; Start: Integer;
  dx, dy : TFloat; AStraight : Boolean): TArrayOfFloatPoint;

  // SKEW

var pair, i,k : Integer;
  mid, opposite, needed, adjusted : TFloatPoint;
begin
  pair := SafelyGetEdgeIndex(Start+1);
  mid  := MiddlePointOf2Lines(AEdges[start], AEdges[pair]);
  opposite := AEdges[pair];

  needed := IncOf(mid, dx,dy);

  if AStraight then
  begin
    adjusted := Straight90degreeAt(mid, opposite, needed);
  end
  else
  begin
    adjusted := needed;
  end;

  dx := adjusted.X -mid.X;
  dy := adjusted.Y -mid.Y;

  Result := Move2Edges(AEdges, Start, dx, dy);
end;

function MirrorPoint(const P,Axis: TFloatPoint): TFloatPoint ;
var
  ZeroP : TFloatPoint;
begin
  ZeroP := IncOf(P, -Axis.X, -Axis.Y); // get distance

  Result := IncOf(Axis, - ZeroP.X, - ZeroP.Y);
end;

function PerspectiveByCorner(AEdges : TArrayOfFloatPoint; Start: Integer;
  dx, dy : TFloat; AStraight : Boolean): TArrayOfFloatPoint;

  // PERSPECTIVE

var pair, iPrev,iNext, i,k : Integer;
  mid, node, prev, next, draggedPrev,draggedNext, opposite,  needed, adjusted : TFloatPoint;
begin
  Result := Copy(AEdges,0,4);
  
  iPrev := SafelyGetEdgeIndex(Start-1);
  iNext := SafelyGetEdgeIndex(Start+1);

  node  := AEdges[start];
  prev  := AEdges[iPrev];
  next  := Aedges[iNext];

  needed := IncOf(node, dx,dy);

  draggedPrev := Straight90degreeAt(node, prev, needed);
  draggedNext := Straight90degreeAt(node, next, needed);

  // which XY is dragged further ?
  if LineDistance(node, draggedPrev, True) > LineDistance(node, draggedNext, True) then
  begin
    Result[Start] := draggedPrev;
    mid  := MiddlePointOf2Lines(AEdges[start], AEdges[iPrev]);
    Result[iPrev] := MirrorPoint(Result[Start], mid);
//    reduction := FloatPoint()
  end
  else
  begin
    Result[Start] := draggedNext;
    mid  := MiddlePointOf2Lines(AEdges[start], AEdges[iNext]);
    Result[iNext] := MirrorPoint(Result[Start], mid);
  end;
end;

function SkewBySideBuggy(AEdges : TArrayOfFloatPoint; Start: Integer; dx, dy : TFloat): TArrayOfFloatPoint;

  // SKEW

var opposite, i,k : Integer;
  slope : TFloatPoint;
begin
  opposite := SafelyGetEdgeIndex(Start+1);

  // calc slope
  slope:= SlopeOf(AEdges[Opposite], AEdges[Start]);



  

  if Odd(Start) then  // locally vertical skew
  begin
    with slope do
    //TODO : what if ax = 0 ?
    dx := dx + (x/y) * dy;
  end
  else
  begin                // locally horizontal skew
    with slope do
    //TODO : what if ay = 0 ?
    dy := dy + (y/x) * dx;
  end;




  Result := Move2Edges(AEdges, Start, dx, dy);
end;

function Move2CornersBuggy(AEdges : TArrayOfFloatPoint; Start: Integer; dx, dy : TFloat): TArrayOfFloatPoint;

  // RESIZE

var i,k : Integer;
  m1, m2, mid, ops, needed, adjusted : TFloatPoint;
  ax,ay : TFloat;
begin
  Result := Copy(AEdges,0,4);

  //find the opposite side
  if Odd(Start) then
  // locally horizontal resize
  begin
    m1 := MiddlePointOf2Lines(Aedges[0], AEdges[3]);
    m2 := MiddlePointOf2Lines(Aedges[1], AEdges[2]);

    if Start = 1 then
    begin
      mid := m2;
      ops := m1;
    end
    else
    begin
      mid := m1;
      ops := m2;
    end;

    needed := IncOf(AEdges[start],dx,dy);
    adjusted := Straight90degreeAt(mid, ops, needed);
    dx := adjusted.X -mid.X;
    dy := adjusted.Y -mid.Y;


    
    // calc slope
    ax := (m1.X - m2.X);
    ay := (m1.Y - m2.Y);

    //TODO : what if ax = 0 ?
    dy := dy + (ay/ax) * dx;
  end
  else
  // locally vertical resize
  begin
    m1 := MiddlePointOf2Lines(Aedges[0], AEdges[1]);
    m2 := MiddlePointOf2Lines(Aedges[2], AEdges[3]);

    // calc slope
    ax := (m1.X - m2.X);
    ay := (m1.Y - m2.Y);

    //TODO : what if ay = 0 ?
    dx := dx + (ax/ay) * dy;
  end;





  for k := Start to Start + 1 do
  begin
    i := k; if i > 3 then i := 0;

    {Result[i].X  := Result[i].X + dx;
    Result[i].Y  := Result[i].Y + dy;}
    //IncEdge(Result,i,dx,dy);
    IncF(Result[i], dx,dy);
  end;
end;



function ResizeByCorner(Sender: TElasticLayer; AEdges : TArrayOfFloatPoint; Mid: Integer; dx, dy : TFloat;
  Straight, OddCompass: Boolean): TArrayOfFloatPoint;
var
  //Global var used inside this functions.

  LEdges : TArrayOfFloatPoint;
  


  function RatioOf(I, Opposite: Integer): TFloatPoint;
  begin
    Result := FloatPoint(LEdges[I].X - LEdges[Opposite].X,
                            LEdges[I].Y - LEdges[Opposite].Y  )
  end;



var
  I,Prev,Next, Opposite : Integer;
  //oldMidRatio, newMidRatio,
  MidPoint,
  MidPointOrigin, newMidPointOrigin,
  MousePoint, newMidPoint,
  MidPointRotatedOrigin, newMidPointRotatedOrigin,
  MidPointRotated, newMidPointRotated,
  OppositeOrigin,
  pivotBefore, pivotAfter, Scale,
  slopePrev, slopeNext, slopeMid,
  d,ScaleRatio,slopeMouse, mouseInSlope : TFloatPoint;
  diagonalScale, Radius,Ratio, newRadius, A,B,C,R : TFloat;
  TT : TTicTransformation ;   

  Affine : TAffineTransformation;
  Radians, Angle1, NewAngle : TFloat;

begin
  LEdges := Copy(AEdges,0,4);

  // PUSH THE VALUES BEFORE THEY BEING MODIFIED
  MidPoint := Ledges[Mid];
  Prev := SafelyGetEdgeIndex( Mid -1 );
  Next := SafelyGetEdgeIndex( Mid +1 );
  Opposite := SafelyGetEdgeIndex( Mid -2 );

  Radius := LineDistance(Ledges[Mid], LEdges[Opposite]);

  {oldMidRatio := RatioOf(Mid, Opposite);
  slopePrev   := RatioOf(Prev,Opposite);
  slopeNext   := RatioOf(Next,Opposite);}
  pivotBefore := MiddlePointOf2Lines(Ledges[Mid], LEdges[Opposite]);
  slopePrev   := SlopeOf(LEdges[Prev],pivotBefore);
  slopeNext   := SlopeOf(LEdges[Next],pivotBefore);

  Radians := ArcTan2( LEdges[Opposite].Y - Ledges[Mid].Y, Ledges[Mid].X - LEdges[Opposite].X );
  Angle1  := RadToDeg( Radians );

  //------------------------------------------------------------
  // MOVE THE "MID" EDGE

  newMidPoint := IncOf( LEdges[Mid], dx, dy);
  if Straight then
  begin
    newMidPoint := Straight90degreeAt(MidPoint, Ledges[Opposite], newMidPoint)
  end;


  newRadius := LineDistance(newMidPoint, LEdges[Opposite]);
  {if Straight then
  
    Inc(LEdges[Mid], dx, dy); }
  //------------------------------------------------------------

  Radians := ArcTan2( LEdges[Opposite].Y - newMidPoint.Y, newMidPoint.X - LEdges[Opposite].X );
  NewAngle := RadToDeg( Radians );

  Affine := TAffineTransformation.Create;
  //Affine.SrcRect := EdgesToFloatRect(LEdges);
  // Scale to non viewport if activated.

  //Affine.SrcRect := FloatRect(LEdges[Opposite], LEdges[Opposite]);
  //Affine.Rotate(LEdges[Opposite].X, LEdges[Opposite].Y, NewAngle - Angle1);


  Affine.Translate( -LEdges[Opposite].X, -LEdges[Opposite].Y);
  {diagonalScale := Min(
    Abs(newMidPoint.X -LEdges[Opposite].X) / Abs(Ledges[Mid].X -LEdges[Opposite].X),
    Abs(newMidPoint.Y -LEdges[Opposite].Y) / Abs(Ledges[Mid].Y -LEdges[Opposite].Y) );}

  diagonalScale := newRadius / Radius;
  TT :=  TTicTransformation.Create ;
  TT.Assign(Sender.FTransformation);            
  MidPointOrigin := TT.ReverseTransform(Ledges[Mid]);
  newMidPointOrigin := TT.ReverseTransform(newMidPoint);
  OppositeOrigin := TT.ReverseTransform(LEdges[Opposite]);

  //Affine.Scale(
  ScaleRatio := FloatPoint(
    Abs(newMidPointOrigin.X -OppositeOrigin.X) / Abs(MidPointOrigin.X -OppositeOrigin.X),
    Abs(newMidPointOrigin.Y -OppositeOrigin.Y) / Abs(MidPointOrigin.Y -OppositeOrigin.Y)
  );
  ScaleRatio := FloatPoint(
    Abs(newMidPoint.X -LEdges[Opposite].X) / Abs(Ledges[Mid].X -LEdges[Opposite].X),
    Abs(newMidPoint.Y -LEdges[Opposite].Y) / Abs(Ledges[Mid].Y -LEdges[Opposite].Y) );
  //Scale.X :=

  //Affine.Scale(diagonalScale, diagonalScale);
  //if not Straight then
  Affine.Rotate(0,0, NewAngle - Angle1);

  //newMidPointRotatedOrigin := Affine.ReverseTransform(FloatPoint(newMidPoint.X -LEdges[Opposite].X, newMidPoint.Y -LEdges[Opposite].Y));

  MidPointRotated := Affine.Transform(MidPoint);
  newMidPointRotated := FloatPoint(newMidPoint.X -LEdges[Opposite].X, newMidPoint.Y -LEdges[Opposite].Y);


  ScaleRatio := FloatPoint(
    Abs( newMidPointRotated.X / MidPointRotated.X),
    Abs( newMidPointRotated.Y / MidPointRotated.Y) );

  Affine.Scale(ScaleRatio.X, ScaleRatio.Y);

  if Straight then
  begin
//    Affine.Rotate(0,0, 360-NewAngle );
  end;

  Affine.Translate( LEdges[Opposite].X, LEdges[Opposite].Y);
  //Affine.Translate( Pivot.X, Pivot.Y );
  //Affine.Scale( Abs(newMidPoint.X / Ledges[Mid].X), Abs(newMidPoint.Y / Ledges[Mid].Y) );

  for i := 0 to 3 do
  begin
    LEdges[i] := Affine.Transform(Ledges[i]);
  end;

  Result := LEdges;
end;

function Move3EdgesBuggy(AEdges : TArrayOfFloatPoint; Mid: Integer; dx, dy : TFloat;
  Straight, OddCompass: Boolean): TArrayOfFloatPoint;
var
  //Global var used inside this functions.

  LEdges : TArrayOfFloatPoint;
  


  function RatioOf(I, Opposite: Integer): TFloatPoint;
  begin
    Result := FloatPoint(LEdges[I].X - LEdges[Opposite].X,
                            LEdges[I].Y - LEdges[Opposite].Y  )
  end;



var
  Prev,Next, Opposite : Integer;
  //oldMidRatio, newMidRatio,
  MousePoint,
  pivotBefore, pivotAfter,
  slopePrev, slopeNext, slopeMid,
  slopeMouse, mouseInSlope : TFloatPoint;
  Angle, Radius,Ratio, newRadius, A,B,C,R : TFloat;
begin
  LEdges := Copy(AEdges,0,4);

  // PUSH THE VALUES BEFORE THEY BEING MODIFIED
  
  Prev := SafelyGetEdgeIndex( Mid -1 );
  Next := SafelyGetEdgeIndex( Mid +1 );
  Opposite := SafelyGetEdgeIndex( Mid -2 );

  Radius := LineDistance(Ledges[Mid], LEdges[Opposite]);

  {oldMidRatio := RatioOf(Mid, Opposite);
  slopePrev   := RatioOf(Prev,Opposite);
  slopeNext   := RatioOf(Next,Opposite);}
  pivotBefore := MiddlePointOf2Lines(Ledges[Mid], LEdges[Opposite]);
  slopePrev   := SlopeOf(LEdges[Prev],pivotBefore);
  slopeNext   := SlopeOf(LEdges[Next],pivotBefore);


  //------------------------------------------------------------
  // MOVE THE "MID" EDGE
  if Straight then
  begin
    //slopeMouse := SlopeOf(FloatPoint(dx,dy), LEdges[Opposite]);
    MousePoint := Ledges[Mid];
    IncF(MousePoint, dx, dy);


    slopeMid := SlopeOf(Ledges[Mid], LEdges[Opposite]);
    with slopeMid do
    begin
      // get on slopeMid the 90 degree of mousepos using pythagoras
      //C:= MousePoint.Y * X
      mouseInSlope.Y := MousePoint.Y;
      mouseInSlope.X := X/Y * MousePoint.Y;
      Angle := ArcTan2(Y,X);
      C := LineDistance(mouseInSlope, MousePoint, True);
      A := Cos(Angle) * C;

      dx := mouseInSlope.X + A * Cos(Angle);
      dy := mouseInSlope.Y + A * Sin(Angle);

      LEdges[Mid].X := mouseInSlope.X + Cos(Angle) * C;
      LEdges[Mid].Y := mouseInSlope.Y + Sin(Angle) * C;

      //if Odd(Mid) then
      //if Abs(x) < Abs(y) then
      //if Abs(dx) < Abs(dy) then
      //if Abs(slopeMouse.X) < Abs(slopeMouse.Y) then
      if OddCompass then

      // listen X only
      begin
        //TODO : what if ay = 0 ?
//        dy := (y/x) * dx;
      end
      else

      // listen Y only
      begin
        //TODO : what if ax = 0 ?
//        dx := (x/y) * dy;
      end;
    end;
  end
  else
    IncF(LEdges[Mid], dx, dy);
  //------------------------------------------------------------

  // Recalculate the ratios
  {newMidRatio := RatioOf(Mid,Opposite);
  X := newMidRatio.X / oldMidRatio.X ;
  Y := newMidRatio.Y / oldMidRatio.Y ;

  //PREV
  LEdges[Prev].X := LEdges[Opposite].X + slopePrev.X * X;
  LEdges[Prev].Y := LEdges[Opposite].Y + slopePrev.Y * Y;

  //NEXT
  LEdges[Next].X := LEdges[Opposite].X + slopeNext.X * X;
  LEdges[Next].Y := LEdges[Opposite].Y + slopeNext.Y * Y;}


  newRadius := LineDistance(Ledges[Mid], LEdges[Opposite]);
  Ratio := newRadius / Radius;

  pivotAfter := MiddlePointOf2Lines(Ledges[Mid], LEdges[Opposite]);
  {X := pivotAfter.X / pivotBefore.X ;
  Y := pivotAfter.Y / pivotBefore.Y ;}

  //PREV
  LEdges[Prev].X := pivotAfter.X + slopePrev.X * Ratio;
  LEdges[Prev].Y := pivotAfter.Y + slopePrev.Y * Ratio;

  //NEXT
  LEdges[Next].X := pivotAfter.X + slopeNext.X * Ratio;
  LEdges[Next].Y := pivotAfter.Y + slopeNext.Y * Ratio;


  {if Odd(Mid) then
  begin
    Result[Prev].Y := Result[Mid].Y;
    Result[Next].X := Result[Mid].X;
  end
  else
  begin
    Result[Prev].X := Result[Mid].X;
    Result[Next].Y := Result[Mid].Y;
  end;}

  Result := LEdges;
end;


function MostLeftEdge(AEdges : TArrayOfFloatPoint): Integer;
var i : Integer;
begin
  Result := 0;
  for i := Length(AEdges)-1 downto 1 do
  begin
    if AEdges[i].X < AEdges[0].X then
      Result := i;
  end;
end;

{ TTicLayer }

constructor TElasticLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited;
  LayerOptions := LOB_VISIBLE or LOB_MOUSE_EVENTS;  
  FTransformation := TTicTransformation.Create;
  FInViewPortTransformation := TTicTransformation.Create;
  
end;

destructor TElasticLayer.Destroy;
begin
  FTransformation.Free;
  inherited;
end;

procedure TElasticLayer.DoSetEdges(const Value: TArrayOfFloatPoint);
begin
  FTransformation.Edges := Value;
end;

function TElasticLayer.GetScaledEdges: TArrayOfFloatPoint;
var
  ScaleX, ScaleY, ShiftX, ShiftY: TFloat;
  i : Integer;
begin
  //Result := Edges; ERROR HERE, IT SHARE THE ARRAY CONTENT.
  //SetLength(Result,4);
  Result := Copy(Edges,0,4);

  if Scaled and Assigned(LayerCollection) then
  begin
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    LayerCollection.GetViewportScale(ScaleX, ScaleY);

    for i := 0 to Length(Result)-1 do
    begin
      Result[i].X := Result[i].X * ScaleX + ShiftX;
      Result[i].Y := Result[i].Y * ScaleY + ShiftY;
    end;
  end;
end;

function TElasticLayer.GetScaledRect(const R: TFloatRect): TFloatRect;
var
  ScaleX, ScaleY, ShiftX, ShiftY: TFloat;
begin
  if Scaled and Assigned(LayerCollection) then
  begin
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    LayerCollection.GetViewportScale(ScaleX, ScaleY);

    with Result do
    begin
      Left := R.Left * ScaleX + ShiftX;
      Top := R.Top * ScaleY + ShiftY;
      Right := R.Right * ScaleX + ShiftX;
      Bottom := R.Bottom * ScaleY + ShiftY;
    end;
  end
  else
    Result := R;
end;

function TElasticLayer.GetEdges: TArrayOfFloatPoint;
begin
  Result := FTransformation.Edges;
end;

function TElasticLayer.GetSourceRect: TFloatRect;
begin
  Result := FTransformation.SrcRect;
end;

function TElasticLayer.GetTic(index: Integer): TFloatPoint;
begin
  //Result.X  := FQuadX[index];
  //Result.Y  := FQuadY[index];
  Result := Edges[index];
end;


procedure TElasticLayer.SetBounds(APosition, ASize: TFloatPoint);
begin
  SetBounds(FloatRect(APosition, FloatPoint(APosition.X+ ASize.X, APosition.Y+ ASize.Y) ));
end;

procedure TElasticLayer.SetBounds(ABoundsRect: TFloatRect);
begin
  BeginUpdate;
  try
    with ABoundsRect do
    begin
      Tic[0] := TopLeft;
      Tic[1] := FloatPoint(Right, Top);
      Tic[2] := BottomRight;
      Tic[3] := FloatPoint(Left, Bottom);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TElasticLayer.SetCropped(const Value: Boolean);
begin
  if Value <> FCropped then
  begin
    FCropped := Value;
    Changed;
  end;
end;

procedure TElasticLayer.SetEdges(const Value: TArrayOfFloatPoint);
begin
  if Edges <> Value then
  begin
    Changing;
    DoSetEdges(Value);
    //FTransformation.TransformValid := False;
    Changed;
  end;
end;

procedure TElasticLayer.SetScaled(const Value: Boolean);
begin
  if Value <> FScaled then
  begin
    Changing;
    FScaled := Value;
    Changed;
  end;
end;


procedure TElasticLayer.SetSourceRect(const Value: TFloatRect);
begin
  Changing;
  FTransformation.SrcRect := Value;
  Changed;
end;

procedure TElasticLayer.SetTic(index: Integer; const Value: TFloatPoint);
begin
  Changing;
  //FQuadX[index] := Value.X;
  //FQuadY[index] := Value.Y;
  Edges[index] := Value;
  //FTransformation.TransformValid := False;
  Changed;
end;


{ TTicTransformation }

{constructor TTicTransformation.Create(AOwner: TTicLayer);
begin
  Assert(AOwner <> nil, 'Must be TTicLayer');
  inherited Create;
  FOwner := AOwner;
end;}

procedure TTicTransformation.AssignTo(Dest: TPersistent);
begin
  if Dest is TTicTransformation then
  begin
    TTicTransformation(Dest).SrcRect := Self.SrcRect;
    TTicTransformation(Dest).Edges := Copy(Self.Edges,0,4);
  end
  else
  inherited;

end;

constructor TTicTransformation.Create;
begin
  inherited;
  SetLength(FEdges,4);
end;

function TTicTransformation.GetMiddleEdges: TArrayOfFloatPoint;
var i, next : Integer;
begin
  //use cache because it seem called several times
  if not FMiddleEdgesValid then
  begin
    SetLength(FMiddleEdges,4);

    for i := 0 to 3 do
    begin
      next := i + 1;
      if next > 3 then next := 0;

      FMiddleEdges[i].X := Min(FEdges[i].X, FEdges[next].X ) + Abs(FEdges[i].X - FEdges[next].X) /2;
      FMiddleEdges[i].Y := Min(FEdges[i].Y, FEdges[next].Y ) + Abs(FEdges[i].Y - FEdges[next].Y) /2;
    end;
    FMiddleEdgesValid := True;
  end;

  Result := FMiddleEdges;

end;

function TTicTransformation.GetTransformedBounds(const ASrcRect: TFloatRect): TFloatRect;
{var
  V1, V2, V3, V4: TVector3f;}
begin
{  V1[0] := ASrcRect.Left;  V1[1] := ASrcRect.Top;    V1[2] := 1;
  V2[0] := ASrcRect.Right; V2[1] := V1[1];           V2[2] := 1;
  V3[0] := V1[0];          V3[1] := ASrcRect.Bottom; V3[2] := 1;
  V4[0] := V2[0];          V4[1] := V3[1];           V4[2] := 1;
  V1 := VectorTransform(Matrix, V1);
  V2 := VectorTransform(Matrix, V2);
  V3 := VectorTransform(Matrix, V3);
  V4 := VectorTransform(Matrix, V4);
  Result.Left   := Min(Min(V1[0], V2[0]), Min(V3[0], V4[0]));
  Result.Right  := Max(Max(V1[0], V2[0]), Max(V3[0], V4[0]));
  Result.Top    := Min(Min(V1[1], V2[1]), Min(V3[1], V4[1]));
  Result.Bottom := Max(Max(V1[1], V2[1]), Max(V3[1], V4[1]));}
  //with FOwner do
  begin
    Result.Left   := Min(Min(FEdges[0].X, FEdges[1].X), Min(FEdges[2].X, FEdges[3].X));
    Result.Right  := Max(Max(FEdges[0].X, FEdges[1].X), Max(FEdges[2].X, FEdges[3].X));
    Result.Top    := Min(Min(FEdges[0].Y, FEdges[1].Y), Min(FEdges[2].Y, FEdges[3].Y));
    Result.Bottom := Max(Max(FEdges[0].Y, FEdges[1].Y), Max(FEdges[2].Y, FEdges[3].Y));
  end;
end;

procedure TTicTransformation.PrepareTransform;
var
  dx1, dx2, px, dy1, dy2, py: TFloat;
  g, h, k: TFloat;
  R: TFloatMatrix;
  LQuadX,LQuadY : array[0..3] of TFloat;
  i : Integer;
begin
  for i := 0 to 3 do
  with {FOwner.}FEdges[i] do
  begin
    LQuadX[i] := X;
    LQuadY[i] := Y;
  end;



  px  := LQuadX[0] - LQuadX[1] + LQuadX[2] - LQuadX[3];
  py  := LQuadY[0] - LQuadY[1] + LQuadY[2] - LQuadY[3];

  if (px = 0) and (py = 0) then
  begin
    // affine mapping
    FMatrix[0, 0] := LQuadX[1] - LQuadX[0];
    FMatrix[1, 0] := LQuadX[2] - LQuadX[1];
    FMatrix[2, 0] := LQuadX[0];

    FMatrix[0, 1] := LQuadY[1] - LQuadY[0];
    FMatrix[1, 1] := LQuadY[2] - LQuadY[1];
    FMatrix[2, 1] := LQuadY[0];

    FMatrix[0, 2] := 0;
    FMatrix[1, 2] := 0;
    FMatrix[2, 2] := 1;
  end
  else
  begin
    // projective mapping
    dx1 := LQuadX[1] - LQuadX[2];
    dx2 := LQuadX[3] - LQuadX[2];
    dy1 := LQuadY[1] - LQuadY[2];
    dy2 := LQuadY[3] - LQuadY[2];
    k := dx1 * dy2 - dx2 * dy1;
    if k <> 0 then
    begin
      k := 1 / k;
      g := (px * dy2 - py * dx2) * k;
      h := (dx1 * py - dy1 * px) * k;

      FMatrix[0, 0] := LQuadX[1] - LQuadX[0] + g * LQuadX[1];
      FMatrix[1, 0] := LQuadX[3] - LQuadX[0] + h * LQuadX[3];
      FMatrix[2, 0] := LQuadX[0];

      FMatrix[0, 1] := LQuadY[1] - LQuadY[0] + g * LQuadY[1];
      FMatrix[1, 1] := LQuadY[3] - LQuadY[0] + h * LQuadY[3];
      FMatrix[2, 1] := LQuadY[0];

      FMatrix[0, 2] := g;
      FMatrix[1, 2] := h;
      FMatrix[2, 2] := 1;
    end
    else
    begin
      FillChar(FMatrix, SizeOf(FMatrix), 0);
    end;
  end;

  // denormalize texture space (u, v)
  R := IdentityMatrix;
  if IsRectEmpty(SrcRect) then
  begin
    R[0, 0] := 1;
    R[1, 1] := 1;
  end
  else
  begin
    R[0, 0] := 1 / (SrcRect.Right - SrcRect.Left);
    R[1, 1] := 1 / (SrcRect.Bottom - SrcRect.Top);
  end;  
  FMatrix := Mult(FMatrix, R);

  R := IdentityMatrix;
  R[2, 0] := -SrcRect.Left;
  R[2, 1] := -SrcRect.Top;
  FMatrix := Mult(FMatrix, R);

  inherited;
end;


procedure TTicTransformation.ReverseTransformFixed(DstX, DstY: TFixed;
  out SrcX, SrcY: TFixed);
var
  Z: TFixed;
  Zf: TFloat;
begin
  Z := FixedMul(FInverseFixedMatrix[0, 2], DstX) +
    FixedMul(FInverseFixedMatrix[1, 2], DstY) + FInverseFixedMatrix[2, 2];

  if Z = 0 then Exit;

  {$IFDEF UseInlining}
  SrcX := FixedMul(DstX, FInverseFixedMatrix[0, 0]) +
    FixedMul(DstY, FInverseFixedMatrix[1, 0]) + FInverseFixedMatrix[2, 0];
  SrcY := FixedMul(DstX, FInverseFixedMatrix[0,1]) +
    FixedMul(DstY, FInverseFixedMatrix[1, 1]) + FInverseFixedMatrix[2, 1];
  {$ELSE}
  inherited;
  {$ENDIF}

  if Z <> FixedOne then
  begin
    EMMS;
    Zf := FixedOne / Z;
    SrcX := Round(SrcX * Zf);
    SrcY := Round(SrcY * Zf);
  end;
end;


procedure TTicTransformation.ReverseTransformFloat(
  DstX, DstY: TFloat;
  out SrcX, SrcY: TFloat);
var
  Z: TFloat;
begin
  EMMS;
  Z := FInverseMatrix[0, 2] * DstX + FInverseMatrix[1, 2] * DstY +
    FInverseMatrix[2, 2];

  if Z = 0 then Exit;

  {$IFDEF UseInlining}
  SrcX := DstX * FInverseMatrix[0, 0] + DstY * FInverseMatrix[1, 0] +
    FInverseMatrix[2, 0];
  SrcY := DstX * FInverseMatrix[0, 1] + DstY * FInverseMatrix[1, 1] +
    FInverseMatrix[2, 1];
  {$ELSE}
  inherited;
  {$ENDIF}

  if Z <> 1 then
  begin
    Z := 1 / Z;
    SrcX := SrcX * Z;
    SrcY := SrcY * Z;
  end;
end;


{procedure TTicTransformation.Scale(Sx, Sy: TFloat);
var
  M: TFloatMatrix;
begin
  M := IdentityMatrix;
  M[0, 0] := Sx;
  M[1, 1] := Sy;
  FMatrix := Mult(M, Matrix);

  //Changed;
  inherited PrepareTransform;
end;}

procedure TTicTransformation.SetEdges(const Value: TArrayOfFloatPoint);
begin
  FEdges := Value;
  TransformValid := False;
  FMiddleEdgesValid := False;
end;

procedure TTicTransformation.TransformFixed(SrcX, SrcY: TFixed;
  out DstX, DstY: TFixed);
var
  Z: TFixed;
  Zf: TFloat;
begin
  Z := FixedMul(FFixedMatrix[0, 2], SrcX) +
    FixedMul(FFixedMatrix[1, 2], SrcY) + FFixedMatrix[2, 2];

  if Z = 0 then Exit;

  {$IFDEF UseInlining}
  DstX := FixedMul(SrcX, FFixedMatrix[0, 0]) +
    FixedMul(SrcY, FFixedMatrix[1, 0]) + FFixedMatrix[2, 0];
  DstY := FixedMul(SrcX, FFixedMatrix[0, 1]) +
    FixedMul(SrcY, FFixedMatrix[1, 1]) + FFixedMatrix[2, 1];
  {$ELSE}
  inherited;
  {$ENDIF}

  if Z <> FixedOne then
  begin
    EMMS;
    Zf := FixedOne / Z;
    DstX := Round(DstX * Zf);
    DstY := Round(DstY * Zf);
  end;
end;


procedure TTicTransformation.TransformFloat(SrcX, SrcY: TFloat;
  out DstX, DstY: TFloat);
var
  Z: TFloat;
begin
  EMMS;
  Z := FMatrix[0, 2] * SrcX + FMatrix[1, 2] * SrcY + FMatrix[2, 2];

  if Z = 0 then Exit;

  {$IFDEF UseInlining}
  DstX := SrcX * Matrix[0, 0] + SrcY * Matrix[1, 0] + Matrix[2, 0];
  DstY := SrcX * Matrix[0, 1] + SrcY * Matrix[1, 1] + Matrix[2, 1];
  {$ELSE}
  inherited;
  {$ENDIF}

  if Z <> 1 then
  begin
    Z := 1 / Z;
    DstX := DstX * Z;
    DstY := DstY * Z;
  end;
end;




{ TTicBitmapLayer }

procedure TElasticBitmapLayer.BitmapChanged(Sender: TObject);
begin
  SourceRect := FloatRect(0, 0, Bitmap.Width - 1, Bitmap.Height - 1);
end;

constructor TElasticBitmapLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited;
  FBitmap := TBitmap32.Create;
  FBitmap.OnChange := BitmapChanged;
end;

destructor TElasticBitmapLayer.Destroy;
begin
  FBitmap.Free;
  inherited;
end;


function TElasticBitmapLayer.DoHitTest(X, Y: Integer): Boolean;

var
  B: TPoint;
begin
  B := FInViewPortTransformation.ReverseTransform(Point(X, Y));


  Result := PtInRect(Rect(0, 0, Bitmap.Width, Bitmap.Height), B);
  if Result and {AlphaHit and} (Bitmap.PixelS[B.X, B.Y] and $FF000000 = 0) then
    Result := False;
end;


procedure TElasticBitmapLayer.Paint(Buffer: TBitmap32);
var ImageRect : TRect;
  DstRect, ClipRect, TempRect: TRect;
  //LTransformer : TTicTransformation;
  ShiftX, ShiftY, ScaleX, ScaleY: Single;  
begin
 if Bitmap.Empty then Exit;

  //LEdges := GetScaledEdges;

  //Buffer.FrameRectS(MakeRect(EdgesToFloatRect(LEdges)), clBlueViolet32);

  //LTransformer := TTicTransformation.Create;
  //LTransformer.Assign(Self.FTransformation);

  // Scale to viewport if activated.
  FInViewPortTransformation.Edges := GetScaledEdges;
  FInViewPortTransformation.SrcRect := FTransformation.SrcRect;

  DstRect := MakeRect(FInViewPortTransformation.GetTransformedBounds);
  //DstRect := MakeRect(EdgesToFloatRect(LTransformer.Edges));
  ClipRect := Buffer.ClipRect;
  IntersectRect(ClipRect, ClipRect, DstRect);
  if IsRectEmpty(ClipRect) then Exit;
  
  if Cropped and (LayerCollection.Owner is TCustomImage32) and
    not (TImage32Access(LayerCollection.Owner).PaintToMode) then
  begin
    ImageRect := TCustomImage32(LayerCollection.Owner).GetBitmapRect;
    IntersectRect(ClipRect, ClipRect, ImageRect);
    if IsRectEmpty(ClipRect) then Exit;
  end;

  //Transform(Buffer, FBitmap, FTransformation,ClipRect);
  Transform(Buffer, FBitmap, FInViewPortTransformation,ClipRect);

  //Buffer.Draw(MakeRect(FloatRect(Tic[0],Tic[2])), Bitmap.BoundsRect, Bitmap);
  //Buffer.Draw(MakeRect(LTransformer.GetTransformedBounds), Bitmap.BoundsRect, Bitmap);
  
 (*
 if Bitmap.Empty then Exit;

  LTransformer := TTicTransformation.Create;
  LTransformer.Assign(Self.FTransformation);

    // Scale to viewport if activated.
  if FScaled and Assigned(LayerCollection) then
  begin
    LTransformer.PrepareTransform;
    
    LayerCollection.GetViewportScale(ScaleX, ScaleY);
    LTransformer.Scale(ScaleX, ScaleY);
    
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    LTransformer.Translate(ShiftX, ShiftY);
  end;

  DstRect := MakeRect(LTransformer.GetTransformedBounds);
  ClipRect := Buffer.ClipRect;
  IntersectRect(ClipRect, ClipRect, DstRect);
  if IsRectEmpty(ClipRect) then Exit;
  
  if Cropped and (LayerCollection.Owner is TCustomImage32) and
    not (TImage32Access(LayerCollection.Owner).PaintToMode) then
  begin
    ImageRect := TCustomImage32(LayerCollection.Owner).GetBitmapRect;
    IntersectRect(ClipRect, ClipRect, ImageRect);
    //IntersectRect(ClipRect, ClipRect, MakeRect(LTransformer.GetTransformedBounds) );
  end;

  //Transform(Buffer, FBitmap, FTransformation,ClipRect);
  Transform(Buffer, FBitmap, LTransformer,ClipRect);

  //Buffer.Draw(MakeRect(FloatRect(Tic[0],Tic[2])), Bitmap.BoundsRect, Bitmap);
  //Buffer.Draw(MakeRect(LTransformer.GetTransformedBounds), Bitmap.BoundsRect, Bitmap);
 *)

end;

procedure TElasticBitmapLayer.SetBitmap(const Value: TBitmap32);
begin
  Changing;
  FBitmap.Assign(Value);
  Changed;
end;

procedure TElasticBitmapLayer.SetBlendMode(const Value: TBlendMode32);
begin
  if FBlendMode <> Value then
  begin
    FBlendMode := Value;
    case Value of
      bbmNormal32 :
        begin
          Bitmap.OnPixelCombine := nil;
          Bitmap.DrawMode := dmBlend;
        end;
      else
        begin
          Bitmap.DrawMode := dmCustom;
          Bitmap.OnPixelCombine := GetBlendMode(ord(FblendMode));
        end;
    end;
    Changed;
  end;
end;

{ TTicRubberBandLayer }

constructor TElasticRubberBandLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited;
  FThreshold := 8;
  FHandleFrame := clBlack;
  FHandleFill := clWhite;
  FOptions := DefaultRubberbandOptions;
  FHandleSize := 3;
  FPivotPoint := FloatPoint(0.5, 0.5);  
end;

procedure TElasticRubberBandLayer.DoSetEdges(const Value: TArrayOfFloatPoint);
begin
  inherited;
  if Assigned(FChildLayer) then
    FChildLayer.Edges := Value;
end;



(*function TTicRubberBandLayer.GetHitCode(X, Y: Integer;
  Shift: TShiftState): TTicDragState;
// Determines the possible drag state, which the layer could enter.

{
    DIRECTION:            INDEX:

    NW    N   NE          0   4   1
    W         E           7       5
    SW    S   SE          3   6   2

}


    function IsXYNear(AnEdge: TFloatPoint): Boolean ;
    var a,b:double;
    begin
      a:=abs(AnEdge.X - X);
      b:=abs(AnEdge.Y - Y);
      Result := Max(a,b) <= FThreshold;
    end;

    function GetNearestEdges(AnEdges : TArrayOfFloatPoint): Integer;
    var
      i :Integer;
    begin
      Result := -1;

      for i := 0 to Length(AnEdges)-1 do
      begin
        if IsXYNear(AnEdges[i]) then
        begin
          Result := i;
          Break;
        end;
      end;

      {if IsXYNear(LEdge[0]) then
        Result := rdsResizeNW
      else
      if IsXYNear(LEdge[1]) then
        Result := rdsResizeNE
      else
      if IsXYNear(LEdge[2]) then
        Result := rdsResizeSE
      else
      if IsXYNear(LEdge[3]) then
        Result := rdsResizeSW;}
    end;

var
  dX, dY: Single;
  Local: TPoint;
  LocalThresholdX,
  LocalThresholdY: Integer;
  NearTop,
  NearRight,
  NearBottom,
  NearLeft: Boolean;
  ScaleX, ScaleY: Single;
  OriginRect : TFloatRect;
  i : Integer;
  LEdge : TArrayOfFloatPoint;
  MatchEdge : Integer;
begin
  Result := tdsNone;

  // Transform coordinates into local space.
  //Local := FTransformation.ReverseTransform(Point(X, Y));
  Local := FInViewPortTransformation.ReverseTransform(Point(X, Y));

  LocalThresholdX := Abs(Round(FThreshold {/ FScaling.X}));
  LocalThresholdY := Abs(Round(FThreshold {/ FScaling.Y}));
  if FScaled and Assigned(LayerCollection) then
  begin
    LayerCollection.GetViewportScale(ScaleX, ScaleY);
    LocalThresholdX := Round(LocalThresholdX / ScaleX);
    LocalThresholdY := Round(LocalThresholdY / ScaleY);
  end;

  // Check rotation Pivot first.
  {dX := Round(Local.X - FPivotPoint.X);
  if Abs(dX) < LocalThresholdX then
    dX := 0;
  dY := Round(Local.Y - FPivotPoint.Y);
  if Abs(dY) < LocalThresholdY then
    dY := 0;

  // Special case: rotation Pivot is hit.
  if (dX = 0) and (dY = 0) and (rboAllowPivotMove in FOptions) then
    Result := tdsMovePivot
  else}

  if (rboAllowPivotMove in FOptions) and IsXYNear(FPivotPoint) then
    Result := tdsMovePivot

  else
  begin
    OriginRect := FTransformation.SrcRect;
    InflateRect(OriginRect, LocalThresholdX, LocalThresholdY);
    // Check if the mouse is within the bounds.
    //if (Local.X >= -LocalThresholdX) and (Local.X <= FSize.cx + LocalThresholdX) and
    //   (Local.Y >= -LocalThresholdY) and (Local.Y <= FSize.cy + LocalThresholdY) then
    if PtInRect( OriginRect, Local ) then
    begin
      Result := tdsMoveLayer;

      LEdge := FInViewPortTransformation.Edges;

      {NearLeft := Local.X <= LocalThresholdX;
      NearRight := FSize.cx - Local.X <= LocalThresholdX;
      NearTop := Abs(Local.Y) <= LocalThresholdY;
      NearBottom := Abs(FSize.cy - Local.Y) <= LocalThresholdY;}

      {NearLeft  := Abs(LEdge[0].X - X) <= FThreshold;
      NearRight := Abs(LEdge[1].X - X) <= FThreshold;
      NearTop   := Abs(LEdge[1].X - X) <= FThreshold;
      NearBottom := Abs(FSize.cy - Local.Y) <= LocalThresholdY;}

      {if rboAllowCornerResize in FOptions then
      begin
        // Check borders.
        if NearTop then
        begin
          if NearRight then
            Result := rdsResizeNE
          else
            if NearLeft then
              Result := rdsResizeNW;
        end
        else
          if NearBottom then
          begin
            if NearRight then
              Result := rdsResizeSE
            else
              if NearLeft then
                Result := rdsResizeSW;
          end;
      end;}

      {if IsXYNear(LEdge[0]) then
        Result := rdsResizeNW
      else
      if IsXYNear(LEdge[1]) then
        Result := rdsResizeNE
      else
      if IsXYNear(LEdge[2]) then
        Result := rdsResizeSE
      else
      if IsXYNear(LEdge[3]) then
        Result := rdsResizeSW;}

{      MatchEdge := GetNearestEdges(LEdge);
      if MatchEdge > -1 then
        Result := TTicDragState( Ord(tdsResizeNW)+ MatchEdge *2 );
}

      
      {if (Result = rdsMoveLayer) and (rboAllowEdgeResize in FOptions) then
      begin
        // Check for border if no corner hit.
        if NearTop then
          Result := rdsResizeN
        else
          if NearBottom then
            Result := rdsResizeS
          else
            if NearRight then
              Result := rdsResizeE
            else
              if NearLeft then
                Result := rdsResizeW;
      end;}
      if (Result = tdsMoveLayer) {and (rboAllowEdgeResize in FOptions)} then
      begin
        // Check for border if no corner hit.
        LEdge := FInViewPortTransformation.GetMiddleEdges;
        
        {if IsXYNear(LEdge[0]) then
          Result := rdsResizeN
        else
        if IsXYNear(LEdge[1]) then
          Result := rdsResizeE
        else
        if IsXYNear(LEdge[2]) then
          Result := rdsResizeS
        else
        if IsXYNear(LEdge[3]) then
          Result := rdsResizeW;}
{
        MatchEdge := GetNearestEdges(LEdge);
        if MatchEdge > -1 then
          //Result := TTicDragState(4 + MatchEdge);
          Result := TTicDragState( Ord(tdsResizeN)+ MatchEdge *2 );
}
      end;
{
      // If the user holds down the control key then sheering becomes active (only for edges).
      if ssCtrl in Shift then
      begin
        case Result of
          tdsResizeN:
            Result := tdsSheerN;
          tdsResizeE:
            Result := tdsSheerE;
          tdsResizeS:
            Result := tdsSheerS;
          tdsResizeW:
            Result := tdsSheerW;
        end;
      end;}
    end
    else
    begin
      // Mouse is not within the bounds. So if rotating is allowed we can return the rotation state.
      if rboAllowRotation in FOptions then
        Result := tdsRotate;
    end;
  end;

end; *)


function TElasticRubberBandLayer.GetPivotOrigin: TFloatPoint;
var
  W,H : TFloat;
begin

  // get really (final) pivot position in Origin space.
  // Note: FPivotPoint is always in range ( [0..1] , [0..1] ) when pivotPoint inside layer
  with FInViewPortTransformation.SrcRect do
  begin
    W := Right - Left +1;
    H := Bottom - Top +1;

    Result.X := Left -1 + W * FPivotPoint.X;
    Result.Y := Top -1 + H * FPivotPoint.Y;
  end;
end;

function TElasticRubberBandLayer.GetPivotTransformed: TFloatPoint;
begin
  // get really (final) pivot position in Viewport space.
  // Note: FPivotPoint is always in range ( [0..1] , [0..1] ) when pivotPoint inside layer
  Result := FInViewPortTransformation.Transform( GetPivotOrigin );
end;

function TElasticRubberBandLayer.GetRotatedCompass(
  LocalCompas: Integer): Integer;

  // it is used for correction of cursor while resizing/rotating being made.

var
  //R : TFloatRect;
  P, Center : TFloatPoint;
  Radians, Angle : TFloat;
  Compass : Integer;
  LEdges : TArrayOfFloatPoint;
begin
  if LocalCompas <= 3 then
  begin
    LEdges := FInViewPortTransformation.Edges;
    Compass := LocalCompas;
  end
  else
  begin
    LEdges := FInViewPortTransformation.GetMiddleEdges;
    Compass := LocalCompas - 4;
  end;

  P := LEdges[ Compass ];
  Center := CentroidOf( LEdges );

  //Radians := ArcTan2( P.Y - Center.Y, P.X - Center.X );
  Radians := ArcTan2( Center.Y - P.Y, P.X - Center.X );
  Angle := Round( RadToDeg( Radians ));

  // invert to clockwise
  Angle := 180 - Angle;

  // set NorthWest as zero axis
  Angle := Angle - 45;

  // add degree treshold around (+/-)
  Angle := Angle + 22.5;

  //clamp
  while Angle < 0 do
    Angle := Angle + 360;
  while Angle > 360 do
    Angle := Angle - 360;

  // force div with 8 zone
  Result := Floor( Angle / 45 );

  //set back?
  //if LocalCompas > 3 then
  //  Result := Result + 4;

  if Result < 0 then
    Result := 8 - Result;

  //Result := Compass;
end;


function TElasticRubberBandLayer.GetRotatedEdges(AEdges: TArrayOfFloatPoint;
    dx,dy : TFloat): TArrayOfFloatPoint;
var
  LocalPivot, LPivot, P1,P2 : TFloatPoint;
  LEdges : TArrayOfFloatPoint;
  Affine : TAffineTransformation;
  Radians, Angle1, NewAngle : TFloat;
  ShiftX, ShiftY, ScaleX, ScaleY: Single;
  i : Integer;
begin
  //LocalPivot := GetPivotOrigin;
  //Pivot := GetPivotTransformed;
  //Pivot  := FTransformation.Transform(LocalPivot);
  LPivot := FOldTransformedPivot;
  //LocalPivot := FOldOriginPivot;
  //LocalPivot := LPivot;
  LocalPivot := FOldInViewPortPivot;

  P1 := FloatPoint(FDragPos);
  P2 := IncOf(P1, dx, dy);

  // Scale to non viewport if activated.
  (*if Scaled and Assigned(LayerCollection) then
  begin
    LayerCollection.GetViewportScale(ScaleX, ScaleY);
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    {P1.X := P1.X / ScaleX - ShiftX;
    P1.Y := P1.Y / ScaleY - ShiftY;
    P2.X := P2.X / ScaleX - ShiftX;
    P2.Y := P2.Y / ScaleY - ShiftY;}
    P1.X := P1.X / ScaleX - ShiftX;
    P1.Y := P1.Y / ScaleY - ShiftY;
    P2.X := P2.X / ScaleX - ShiftX;
    P2.Y := P2.Y / ScaleY - ShiftY;
    LocalPivot.X := LocalPivot.X / ScaleX - ShiftX;
    LocalPivot.Y := LocalPivot.Y / ScaleY - ShiftY;
  end;*)
  {
  //P1 := FInViewPortTransformation.ReverseTransform(FloatPoint(FDragPos));
  P1 := FOriginDragPos;
  //P2 := FInViewPortTransformation.ReverseTransform(NewDragPos);
  P2 := P1;
  inc(P2, dx, dy);}



  //Radians := ArcTan2( Pivot.Y - FDragPos.Y, FDragPos.X - Pivot.X );
  //Radians := ArcTan2( P1.Y, P1.X );
  Radians := ArcTan2( LocalPivot.Y - P1.Y, P1.X - LocalPivot.X );
  Angle1  := RadToDeg( Radians );

  //Radians  := ArcTan2( Pivot.Y - NewDragPos.Y, NewDragPos.X - Pivot.X );
  Radians := ArcTan2( LocalPivot.Y - P2.Y, P2.X - LocalPivot.X );
  NewAngle := RadToDeg( Radians );


  // translate the center to zero pos
  //LEdges := MoveEdges(AEdges, -Pivot.X, -Pivot.Y);
  LEdges := Copy(AEdges,0,4);


  Affine := TAffineTransformation.Create;
  //Affine.SrcRect := EdgesToFloatRect(LEdges);
  // Scale to non viewport if activated.
  if Scaled and Assigned(LayerCollection) then
  begin
    LayerCollection.GetViewportScale(ScaleX, ScaleY);
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    //LPivot.X := LPivot.X  - ShiftX;
    //LPivot.Y := LPivot.Y  - ShiftY;

    {dX := 1 / ScaleX - ShiftX;
    dY := 1 / ScaleY - ShiftY;}
  end;
  Affine.Rotate(LPivot.X, LPivot.Y, NewAngle - Angle1);
  //Affine.Translate( Pivot.X, Pivot.Y );

  for i := 0 to 3 do
  begin
    LEdges[i] := Affine.Transform(Ledges[i]);
  end;

  Result := LEdges;

  Affine.Free;
end;

procedure TElasticRubberBandLayer.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FIsDragging then Exit;
  FDragPos := Point(X, Y);
  FOldInViewPortPivot := GetPivotTransformed();

  FOriginDragPos := FInViewPortTransformation.ReverseTransform(FloatPoint(FDragPos));

  FOldOriginPivot := GetPivotOrigin;
  //FOldTransformedPivot := GetPivotTransformed;
  FOldTransformedPivot := FTransformation.Transform(FOldOriginPivot);

  FOldEdges := Copy(Edges,0,4); //TODO: shall we use Copy(e,0,4) instead ??
  FIsDragging := True;
  inherited;
end;




procedure TElasticRubberBandLayer.MouseMove(Shift: TShiftState; X, Y: Integer);

const
  MoveCursor: array [0..7] of TCursor = (
    crGrMovePointNWSE,  // cdNorthWest
    crGrMovePointNS,    // cdNorth
    crGrMovePointNESW,  // cdNorthEast
    crGrMovePointWE,    // cdEast
    crGrMovePointNWSE,  // cdSouthEast
    crGrMovePointNS,    // cdSouth
    crGrMovePointNESW,  // cdSouthWest
    crGrMovePointWE     // cdWest
  );

  RotateCursor: array [0..7] of TCursor = (
    crGrRotateNW,       // cdNorthWest
    crGrRotateN,        // cdNorth
    crGrRotateNE,       // cdNorthEast
    crGrRotateE,        // cdEast
    crGrRotateSE,       // cdSouthEast
    crGrRotateS,        // cdSouth
    crGrRotateSW,       // cdSouthWest
    crGrRotateW         // cdWest
  );

  SheerCursor: array [0..7] of TCursor = (
    crGrArrowMoveNWSE,  // cdNorthWest
    crGrArrowMoveWE,    // cdNorth
    crGrArrowMoveNESW,  // cdNorthEast
    crGrArrowMoveNS,    // cdEast
    crGrArrowMoveNWSE,  // cdSouthEast
    crGrArrowMoveWE,    // cdSouth
    crGrArrowMoveNESW,  // cdSouthWest
    crGrArrowMoveNS     // cdWest
  );

  function GetNonViewport(P: TFloatPoint):TFloatPoint ;
  var
    ScaleX, ScaleY, ShiftX, ShiftY : Single;
  begin
    Result := P;
    // Scale to non viewport if activated.
    if Scaled and Assigned(LayerCollection) then
    begin
      LayerCollection.GetViewportScale(ScaleX, ScaleY);
      LayerCollection.GetViewportShift(ShiftX, ShiftY);
      Result.X := Result.X / ScaleX - ShiftX;
      Result.Y := Result.Y / ScaleY - ShiftY;
    end;
  end;



var
  dx,dy,ScaleX, ScaleY : TFloat;
  Zone : Integer;
  ZeroAxis : Integer; //possibly 1 or 0 for straight drag
  Local : TPoint;
  P : TFloatPoint;
  LStraight, MouseInside : Boolean;
  LEdges : TArrayOfFloatPoint;
begin

  FMouseOverPos := Point(X,Y); //used to correct cursor by KeyDown

  if not FIsDragging then
  begin
    P := FloatPoint(X,Y);


    // Transform coordinates into local space.
    Local := FInViewPortTransformation.ReverseTransform(Point(X, Y));
    //Zone  := PtIn9Zones(Local, MakeRect(FInViewPortTransformation.SrcRect), MouseInside);
    Zone := PtIn9Zones(P, FInViewPortTransformation,  MouseInside);
    //FCompass := ZoneToClockwiseIndex[ Zone ];
    FCompass := Zone;

    if (rboAllowPivotMove in FOptions) {and (FCompass = 8)} and ( LineDistance(P,GetPivotTransformed)<= FThreshold) then
      FDragState := tdsMovePivot
    else
    begin
      // initial assumed pos
      if MouseInside then
        FDragState := tdsMoveLayer
      else
        FDragState := tdsNone;  // outside and too far = no selection

      // real detection. Distance is  using inView space
      // Note:  We don't need to search the nearest distance for each edges+middle_Edge,
      //        because the compass was already known.
      if FCompass < 8 then
      begin
        //if MouseInside then //DEBUG
        with FInViewPortTransformation do
        begin

          if (FCompass <= 3) then
          begin
            if LineDistance(P, Edges[FCompass]) <= FThreshold  then
              FDragState := tdsResizeCorner
          end
          else
            if LineDistance(P, GetMiddleEdges[FCompass - 4]) <= FThreshold then
              FDragState := tdsResizeSide;
        end;

        // If the user holds down the control key then sheering becomes active (only for sides).
        if (FDragState = tdsResizeSide) and (ssCtrl in Shift) then
        begin
          FDragState := tdsSkew;
        end
        // If the user holds down the control key then distorting becomes active (only for corners).
        else if (FDragState = tdsResizeCorner) then
        begin
          if (ssCtrl in Shift) then
            FDragState := tdsDistortion
          else
            if (ssShift in Shift) then
              FDragState := tdsPerspective;
        end;
      end;

      //TODO: Add treshold for rotation
      if FDragState = tdsNone then  // outside ? currently is always rotation
        FDragState := tdsRotate;

    end;

    //GetTransformedZone(Zone)
    //FDragState := GetHitCode(X, Y, Shift);
    case FDragState of
      tdsNone:
        Cursor := crDefault;
      tdsRotate:
        Cursor := RotateCursor[ GetRotatedCompass(FCompass) ];
      tdsMoveLayer:
        Cursor := crGrArrow;
      tdsMovePivot:
        Cursor := crGrMoveCenter;
        
      tdsDistortion, tdsPerspective,
      tdsResizeCorner, tdsResizeSide :
        Cursor := MoveCursor[GetRotatedCompass(FCompass) ];
        
      {tdsSheerN..tdsSheerW:
        Cursor := SheerCursor[GetCursorDirection(FDragState)];}
      tdsSkew : Cursor := SheerCursor[GetRotatedCompass(FCompass)];
    else
      //Cursor := MoveCursor[GetRotatedCompass(Compass) ];
      //tdsNone:
        Cursor := crDefault;
    end;

  end
  else
  //if FIsDragging then
  begin
    // If the user holds down the control key then sheering becomes active (only for sides).
    if (FDragState in [tdsResizeSide, tdsSkew]) then
    begin
      if (ssCtrl in Shift) then
        FDragState := tdsSkew
      else
        FDragState := tdsResizeSide;
    end
    // If the user holds down the control key then distorting becomes active (only for corners).
    else if (FDragState in [tdsResizeCorner, tdsDistortion])  then
    begin
      if ssCtrl in Shift then
        FDragState := tdsDistortion
      else
        FDragState := tdsResizeCorner;
    end;

    if (ssAlt in Shift) then
      ZeroAxis := 1
    else
      ZeroAxis := 0;

    LStraight := not (ssAlt in Shift);
     
    dx := X - FDragPos.X;
    dy := Y - FDragPos.Y;
    if Scaled then
    begin
      LayerCollection.GetViewportScale(ScaleX, ScaleY);
      dx := dx / ScaleX;
      dy := dy / ScaleY;
    end;

    case FDragState of
      tdsMoveLayer  :
          Edges := MoveEdges( FOldEdges, dx, dy );

      tdsMovePivot  :
          begin
            P := FInViewPortTransformation.ReverseTransform(FloatPoint(X,Y));
            SetPivotOrigin(P);
          end;

      tdsResizeSide :
          begin
            Edges := ResizeBySide( FOldEdges, FCompass - 4, dx, dy, LStraight);
            Cursor := MoveCursor[GetRotatedCompass(FCompass) ];
          end;

      tdsSkew :
          begin
            Edges := SkewBySide( FOldEdges, FCompass - 4, dx, dy, LStraight);
          end;

      tdsResizeCorner :
          begin
            Edges  := ResizeByCorner(Self, FOldEdges, FCompass, dx, dy, LStraight, Odd(GetRotatedCompass(FCompass)) );
            Cursor := MoveCursor[GetRotatedCompass(FCompass) ];
          end;

      tdsDistortion :
          begin
            P := GetNonViewport(FloatPoint(X,Y));

            LEdges := Copy(FOldEdges,0,4);
            LEdges[FCompass] := P;

            Edges := LEdges;

            Cursor := MoveCursor[GetRotatedCompass(FCompass) ];
          end;

      tdsRotate :
          begin
            dx := X - FDragPos.X;
            dy := Y - FDragPos.Y;
            
            Edges  := GetRotatedEdges( FOldEdges, dx, dy );
            Cursor := RotateCursor[GetRotatedCompass(FCompass) ];
          end;

      tdsPerspective :
          begin
            Edges := PerspectiveByCorner( FOldEdges, FCompass, dx, dy, LStraight);
          end;
      {tdsResizeNW,
      tdsResizeNE,
      tdsResizeSE,
      tdsResizeSW : Edges := Move3Edges( FOldEdgest, ord(FDragState) div 2, dx, dy);}
    end;
  end;
  inherited;

end;

procedure TElasticRubberBandLayer.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FIsDragging then
  begin
    FIsDragging := False;
  end;
  inherited;

end;

procedure TElasticRubberBandLayer.Paint(Buffer: TBitmap32);

var
  //Contour: TContour;
  LEdges : TArrayOfFloatPoint;

  //--------------- local functions -------------------------------------------

  {procedure CalculateContour(X, Y, W, H: Single);

  // Constructs four vertex points from the given coordinates and sizes and
  // transforms them into a contour structure, which corresponds to the
  // current transformations.

  var
    R: TFloatRect;

  begin
    R.TopLeft := FloatPoint(X, Y);
    R.BottomRight := FloatPoint(X + W, Y + H);

    with FTransformation do
    begin
      // Upper left
      Contour[0].X := Fixed(Matrix[0, 0] * R.Left + Matrix[1, 0] * R.Top + Matrix[2, 0]);
      Contour[0].Y := Fixed(Matrix[0, 1] * R.Left + Matrix[1, 1] * R.Top + Matrix[2, 1]);

      // Upper right
      Contour[1].X := Fixed(Matrix[0, 0] * R.Right + Matrix[1, 0] * R.Top + Matrix[2, 0]);
      Contour[1].Y := Fixed(Matrix[0, 1] * R.Right + Matrix[1, 1] * R.Top + Matrix[2, 1]);

      // Lower right
      Contour[2].X := Fixed(Matrix[0, 0] * R.Right + Matrix[1, 0] * R.Bottom + Matrix[2, 0]);
      Contour[2].Y := Fixed(Matrix[0, 1] * R.Right + Matrix[1, 1] * R.Bottom + Matrix[2, 1]);

      // Lower left
      Contour[3].X := Fixed(Matrix[0, 0] * R.Left + Matrix[1, 0] * R.Bottom + Matrix[2, 0]);
      Contour[3].Y := Fixed(Matrix[0, 1] * R.Left + Matrix[1, 1] * R.Bottom + Matrix[2, 1]);
    end;
  end; }

  //---------------------------------------------------------------------------

  procedure DrawLineP(A,B: TFloatPoint);
  begin
    with Buffer, MakeRect(FloatRect(A,B)) do
    begin
      if Top = Bottom then
        HorzLineTSP(Left, Top, Right)
      else
        if Left = Right then
          VertLineTSP(Left, Top, Bottom)
        else
        begin
          MoveToF(A.X, A.Y);
          LineToFSP(B.X, B.Y);
        end;
    end;
  end;

  procedure DrawContour;

  begin
    with Buffer do
    begin
      DrawLineP( LEdges[0], LEdges[1] );
      DrawLineP( LEdges[1], LEdges[2] );
      DrawLineP( LEdges[2], LEdges[3] );
      DrawLineP( LEdges[3], LEdges[0] );
      //MoveToF(LEdges[0].X, LEdges[0].Y);
      {MoveToF(LEdges[1].X, 0);
      LineToFSP(LEdges[1].X, LEdges[1].Y);
      LineToFSP(LEdges[2].X, LEdges[2].Y);
      LineToFSP(LEdges[3].X, LEdges[3].Y);
      LineToFSP(LEdges[0].X, LEdges[0].Y);

      LineToFSP(90, LEdges[0].Y);
      MoveToF(50, LEdges[0].Y);
//      LineToFSP(50,50);
      LineToFSP(50,650);}
    end;
  end;

  //---------------------------------------------------------------------------

  procedure DrawHandle(XY: TFloatPoint);

  // Special version for handle vertex calculation. Handles are fixed sized and not rotated.

  var
    R : TRect;
  begin
    with Point(XY) do
      R := MakeRect(X,Y,X,Y);

    InflateRect(R, FHandleSize, FHandleSize);

    Buffer.FillRectS(R, FHandleFill);
    Buffer.FrameRectS(R, FHandleFrame);
  end;
  //---------------------------------------------------------------------------

  procedure DrawHandles(AEdges: TArrayOfFloatPoint);

  // Special version for handle vertex calculation. Handles are fixed sized and not rotated.

  var
    i : Integer;
  begin
    for i := 0 to 3 do
    begin
      DrawHandle(AEdges[i]);
    end;
  end;

  //---------------------------------------------------------------------------

  procedure DrawPivot();

  // Special version for the pivot image. Also this image is neither rotated nor scaled.

  //var
    //XNew, YNew, ShiftX, ShiftY: Single;

  begin

    {with FTransformation do
    begin
      XNew := Matrix[0, 0] * X + Matrix[1, 0] * Y + Matrix[2, 0];
      YNew := Matrix[0, 1] * X + Matrix[1, 1] * Y + Matrix[2, 1];
    end;

{    if FScaled and Assigned(LayerCollection) then
    begin
      LayerCollection.GetViewportScale(XNew, YNew);
      LayerCollection.GetViewportShift(ShiftX, ShiftY);
      XNew := XNew * X + ShiftX;
      YNew := YNew * Y + ShiftY;
    end
    else
    begin
      XNew := X;
      YNew := Y;
    end;}
    with GetPivotTransformed() do
      //DrawIconEx(Buffer.Handle, Round(X - 8), Round(Y - 8), Screen.Cursors[crGrCircleCross], 0, 0, 0, 0, DI_NORMAL);
      Buffer.Draw(Round(X - 8), Round(Y - 8), GetPivotBitmap() );
  end;

  
  //--------------- end local functions ---------------------------------------

//var  Cx, Cy: Single;
//var
  //i : Integer;
  //LTransformer : TTicTransformation;
  //ShiftX, ShiftY, ScaleX, ScaleY: Single;
  //LEdges : TArrayOfFloatPoint;
begin
  // Scale to viewport if activated.
  LEdges := GetScaledEdges;
  FInViewPortTransformation.Edges := LEdges;
  FInViewPortTransformation.SrcRect := FTransformation.SrcRect;


  //CalculateContour(0, 0, FSize.cx, FSize.cy);

  //if AlphaComponent(FOuterColor) > 0 then
    //FillOuter(Buffer, Rect(0, 0, Buffer.Width, Buffer.Height), Contour);

  if rboShowFrame in FOptions then
  begin
    Buffer.SetStipple([clWhite32, clWhite32, clBlack32, clBlack32]);
    Buffer.StippleCounter := 0;
    Buffer.StippleStep := 1;
    DrawContour;
  end;

  if rboShowHandles in FOptions then
  begin
    DrawHandles(LEdges);

    LEdges := FInViewPortTransformation.GetMiddleEdges;
    DrawHandles(LEdges);
  end;
  
  if rboAllowPivotMove in FOptions then
    DrawPivot();


  {Buffer.PenColor := clYellow32;
    Buffer.MoveToF(LEdges[0].X, LEdges[0].Y );
    for i := 1 to 3 do
    begin
      //Buffer.LineToFS(LEdges[i].X, LEdges[i].Y );
    end;}
  //Buffer.FrameRectS(MakeRect(EdgesToFloatRect(LEdges)), clBlueViolet32);

  {
  LTransformer := TTicTransformation.Create;
  LTransformer.Assign(Self.FTransformation);

    // Scale to viewport if activated.
  if FScaled and Assigned(LayerCollection) then
  begin
    LTransformer.PrepareTransform;
    
    LayerCollection.GetViewportScale(ScaleX, ScaleY);
    LTransformer.Scale(ScaleX, ScaleY);
    
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    LTransformer.Translate(ShiftX, ShiftY);
  end;

  Buffer.PenColor := clBlack32;
  with LTransformer do
  begin

    Buffer.FrameRectS(MakeRect(GetTransformedBounds), clBlueViolet32);
  end;
  }
end;

procedure TElasticRubberBandLayer.SetChildLayer(const Value: TElasticLayer);
begin
  if Assigned(FChildLayer) then
    RemoveNotification(FChildLayer);
    
  FChildLayer := Value;
  if Assigned(Value) then
  begin
    //Location := Value.Location;
    //SetBounds(FloatRect(Value.Tic[0], Value.Tic[2]));
    FTransformation.Assign(Value.FTransformation);
    Scaled := Value.Scaled;
    AddNotification(FChildLayer);
  end;
end;

{procedure TTicTransformation.Translate(Dx, Dy: TFloat);
var
  M: TFloatMatrix;
begin
  M := IdentityMatrix;
  M[2, 0] := Dx;
  M[2, 1] := Dy;
  FMatrix := Mult(M, Matrix);

  //Changed;
  inherited PrepareTransform;
end;}

procedure TElasticRubberBandLayer.SetHandleFill(const Value: TColor);
begin
  if FHandleFill <> Value then
  begin
    FHandleFill := Value;
    TLayerCollectionAccess(LayerCollection).GDIUpdate;
  end;
end;

procedure TElasticRubberBandLayer.SetHandleFrame(const Value: TColor);
begin
  if FHandleFrame <> Value then
  begin
    FHandleFrame := Value;
    TLayerCollectionAccess(LayerCollection).GDIUpdate;
  end;
end;

procedure TElasticRubberBandLayer.SetHandleSize(Value: Integer);
begin
  if Value < 1 then
    Value := 1;
  if FHandleSize <> Value then
  begin
    FHandleSize := Value;
    TLayerCollectionAccess(LayerCollection).GDIUpdate;
  end;
end;

procedure TElasticRubberBandLayer.SetLayerOptions(Value: Cardinal);
begin
  Value := Value and not LOB_NO_UPDATE; // workaround for changed behaviour
  inherited SetLayerOptions(Value);
end;

procedure TElasticRubberBandLayer.SetOptions(
  const Value: TExtRubberBandOptions);
begin
  if FOptions <> Value then
  begin
    Changing;
    FOptions := Value;
    Changed; // Layer collection.
    //DoChange;
  end;
end;




procedure TElasticRubberBandLayer.SetPivotOrigin(Value: TFloatPoint);
var
  W,H : TFloat;
begin

  // set pivot position, based on Origin space
  // Note: FPivotPoint is always in range ( [0..1] , [0..1] ) when pivotPoint inside layer
  with FInViewPortTransformation.SrcRect do
  begin
    W := Right - Left +1;
    H := Bottom - Top +1;

    Changing;
    FPivotPoint.X := Value.X / W;
    FPivotPoint.Y := Value.Y / H;
    Changed;
  end;
end;

initialization

finalization
  if Assigned(UPivotBitmap) then
    UPivotBitmap.Free;
end.
