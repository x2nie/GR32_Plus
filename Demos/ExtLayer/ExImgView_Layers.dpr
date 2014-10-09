program ExImgView_Layers;

{$R 'Media.res' 'Media.rc'}

uses
  Forms,
  ExMainUnit in 'ExMainUnit.pas',
  NewImageUnit in 'NewImageUnit.pas',
  RGBALoaderUnit in 'RGBALoaderUnit.pas',
  GR32_Types in '..\..\GR32_Types.pas',
  GR32_ExtLayers in '..\..\GR32_ExtLayers.pas';

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFrmNewImage, FrmNewImage);
  Application.CreateForm(TRGBALoaderForm, RGBALoaderForm);
  Application.Run;
end.
