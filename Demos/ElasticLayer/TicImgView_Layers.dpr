program TicImgView_Layers;

{$R 'Media.res' 'Media.rc'}

uses
  Forms,
  NewImageUnit in '..\ExtLayer\NewImageUnit.pas',
  RGBALoaderUnit in '..\ExtLayer\RGBALoaderUnit.pas',
  TicMainUnit in 'TicMainUnit.pas' {MainForm},
  GR32_ElasticLayers in '..\..\GR32_ElasticLayers.pas';

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFrmNewImage, FrmNewImage);
  Application.CreateForm(TRGBALoaderForm, RGBALoaderForm);
  Application.Run;
end.
