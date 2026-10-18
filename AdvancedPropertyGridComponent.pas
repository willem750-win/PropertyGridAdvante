unit AdvancedPropertyGridComponent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, Grids, Controls, Dialogs, StdCtrls, ObjectInspector,
  PropEdits, RTTIGrids, ColorBox, Clipbrd, Graphics, ExtCtrls,forms, Variants, FGL, LConvEncoding,
  IniFiles,Buttons,LResources,ComCtrls, RxTextHolder, HtmlView, RichMemo, StrHolder, LCLIntf,
  LMessages,LCLType;

type
    TRowTag = record
    IntValue: Integer;
    StrValue: String;
  end;

   TLanguage = (lgDutch, lgEnglish, lgFrench, lgGerman);
   TStrDict = specialize TFPGMap<TLanguage, TStringList>;

  TInputBoxForm = class(TForm)
  private
    FEdit: TEdit;
    FLabel: TLabel;
    FOkButton: TButton;
  public
    constructor Create(AOwner: TComponent); override;
    function Execute(const ACaption, APrompt, ADefault: string; out AResult: string): Boolean;
  end;

  TInfoBoxForm = class(TForm)
  private
    FImageList:TImageList;
    FHtml:THtmlViewer;
    FButtonPanel:TPanel;
    FCloseButton:TSpeedButton;
    FFhotoButton:TSpeedButton;
    procedure TitleBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FCloseBClick(Sender: TObject);
    Procedure FFhotoBClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ShowInfo(HtmlText: string);
  public

  end;

 TAdvancedStringList = class(TStringList)
  public
    procedure AddProperties(const Properties: string);
  end;

  TAdvancedTranslationList = class(TStringList)
  public
    function GetTranslation(const Key: string): string;
  end;

  TAdvancedPropertyGrid = class(TStringGrid)
  private
     FInternalTIPropertyGrid: TTIPropertyGrid;
     FObject: TComponent;
     FInternalObject: TObject; // Toegevoegd veld
     FComboBox: TComboBox; // Toegevoegd voor True of False waarden
     FColorBox: TColorBox; // Toegevoegd veld voor kleuren
     FRelevantProperties: TAdvancedStringList;// Toegevoegd voor lijst van relevante propertys
     FSelectedRow: Integer; // Houdt de geselecteerde rij bij new
     FMouseDown: Boolean; // Houdt bij of de muis is ingedrukt
     FIgnoreSelection: Boolean;
     FProcessing: Boolean;
     FRowTags: array of TRowTag;  // Array om tags op te slaan per rij
     FTranslations: TStrDict;
     FColumnHeaders: TStrDict;
     FLanguage: TLanguage;// vertalen
     FCurrentLanguage: TLanguage;
     FComboBoxLanguage: TComboBox;
     FSaveButton: TSpeedButton;
     FLoadButton: TSpeedButton;
     FInfoButton: TSpeedButton;
     FDefaultButton:TSpeedButton;
     FMemButton:TSpeedButton;
     FPhoto:TSpeedButton;
     FImageList: TImageList; // Bevat de iconen in FSaveButton en FMemButton enz
     FNote: TPageControl;
     FStrHolder: TStrHolder;
     FDefaultPropHolder: TStrHolder;
     FRxTextHolder:TRxTextHolder;
     procedure ClearSelectionForRow(ARow: Integer);
     procedure SetNote(Value: TPageControl);
     procedure SetStringHolder(AValue: TStrHolder);
     function GetTranslation(const ObjName: string): string;// vertalen
     procedure SetTranslationsFromStringHolder;
     procedure SetRowTag(ARow: Integer; const ATag: TRowTag);
     function GetRowTag(ARow: Integer): TRowTag;

     procedure SyncRowTags;
     procedure OnCellEdit(Sender: TObject; ACol, ARow: Integer; const Value: string);
     procedure SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
     procedure ComboBoxChange(Sender: TObject);
     procedure ColorBoxChange(Sender: TObject);
     procedure SetInternalObject(AObject: TObject);
     procedure SetRelevantProperties(Value: TAdvancedStringList);
     procedure SetRelevantPropertiesString(const Properties: string);
     procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
     procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
     procedure DrawCellHandler(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
     procedure SaveIniClick(Sender: TObject);
     procedure GetClick(Sender: TObject);
     Procedure PhotoClick(Sender: TObject);

     procedure ChangeLanguage(Sender: TObject);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SyncWithTIObject(TIGrid: TTIPropertyGrid);
    procedure DisplayProperties;
    procedure SetObject(AObject: TComponent);
    procedure SetLanguage(Value: TLanguage);// vertalen
    procedure AddRowWithProperty(const PropName: string; const PropValue: Variant; const PropType: string);
    property RowTags[ARow: Integer]: TRowTag read GetRowTag write SetRowTag; default;
    property Language: TLanguage read FLanguage write SetLanguage; // kies taal
    procedure UpdateHeaders;// vertalen
    procedure PopulateGridWithProperties;
    procedure SaveToIniFile(const FileName: string);
    procedure InfoGrid(Sender: TObject);
    procedure UpdateLanguageSelection(NewLanguageText: string);
  public
    FCloseButton: TSpeedButton;
  published
    property ConnectObject: TComponent read FObject write SetObject;
    property InternalObject: TObject read FInternalObject write SetInternalObject;
    property RelevantProperties: TAdvancedStringList read FRelevantProperties write SetRelevantProperties;
    procedure AddRelevantProperties(const Properties: string);
    property DefaultPropHolder: TStrHolder read FDefaultPropHolder write FDefaultPropHolder;
    procedure SetTranslations(const Translations: string);
    property TranslationHolder: TStrHolder read FStrHolder write SetStringHolder;
    property CurrentLanguage: TLanguage read FCurrentLanguage write FCurrentLanguage;
    property Note: TPageControl read FNote write SetNote;
    // koppel TRxTextHolder van mainForm
    property InfoTextHolder: TRxTextHolder read FRxTextHolder write FRxTextHolder;
  end;

procedure Register;

implementation

 {$R resources.res} // knoppen

 {$R test.res}  // Hier koppel je de resource file voor rtf bestanden





{ TInfoBoxForm }
 constructor TInfoBoxForm.Create(AOwner: TComponent);
 var
   Bmp:TBitmap;
 begin
   inherited CreateNew(AOwner); // Gebruik CreateNew in plaats van Create
   Width := 380;
   Height := 250;
   Position := poScreenCenter;
   BorderStyle := bsNone;
   BorderWidth:=2;
   color:= clGradientActiveCaption;
   // maken van FButtonPanel
   FButtonPanel:=TPanel.Create(self);
   FButtonPanel.Parent:= Self;
   FButtonPanel.Height:=20;
   FButtonPanel.Align:=alTop;
   FButtonPanel.Color:= clMenuHighlight;
   FButtonPanel.Font.Style:=[fsBold];
   FButtonPanel.Font.Color:=clYellow;
   FButtonPanel.OnMouseDown := @TitleBarMouseDown;  // laat toe het panel te verplaatsen
   // maken van FCloseButton
   FCloseButton:= TSpeedButton.Create(self);
   FCloseButton.Parent:=FButtonPanel;
   FCloseButton.Width := 18;
   FCloseButton.Align := alRight;
   FCloseButton.Flat:=True;
   FCloseButton.OnClick := @FCloseBClick; // Hier wordt de correcte event-handler toegewezen
   // maken van FFhotoButton
   FFhotoButton:= TSpeedButton.Create(self);
   FFhotoButton.Parent:=FButtonPanel;
   FFhotoButton.Width := 18;
   FFhotoButton.Height:= 18;
   FFhotoButton.Align := alLeft;
   FFhotoButton.Flat:=True;
   FFhotoButton.Transparent:= True;
   FFhotoButton.Hint:='Capture';
   FFhotoButton.ShowHint:=True;
   FFhotoButton.OnClick := @FFhotoBClick; // Hier wordt de correcte event-handler toegewezen
   // Maak de ImageList aan
   FImageList := TImageList.Create(Self);
   FImageList.Width := 16;  // Pas de breedte aan naar je icoon-grootte
   FImageList.Height := 16;
   Bmp := TBitmap.Create;
   try
    // Laad de 'close.bmp' uit de resource
    Bmp.LoadFromResourceName(HINSTANCE, 'SLUIT_BMP');
    FImageList.Add(Bmp, nil);
    // Laad de PHOTO BMP
    Bmp.LoadFromResourceName(HINSTANCE, 'PHOTO_BMP');
    FImageList.Add(Bmp, nil);
   finally
    Bmp.Free;
   end;
    FCloseButton.Glyph := nil; // Geen standaard afbeelding
    FCloseButton.Images := FImageList;
    FCloseButton.ImageIndex := 0;  // Index van de afbeelding in de ImageList  Deurtje


    FFhotoButton.Glyph := nil; // Geen standaard afbeelding
    FFhotoButton.Images := FImageList;
    FFhotoButton.ImageIndex := 1;  // Index van de afbeelding in de ImageList  FOTO

    // maken van FHtml:THtmlViewer;
    FHtml:= THtmlViewer.Create(self);
    FHtml.Parent:= Self;
    FHtml.Align:=alClient;
    FHtml.Color:=clInfoBK;
    FHtml.Height:=170;
 end;

 procedure TInfoBoxForm.TitleBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
 Begin
  ReleaseCapture;
  SendMessage(Handle, LM_SYSCOMMAND, $F012, 0);
 end;

procedure TAdvancedPropertyGrid.GetClick(Sender: TObject);
var
  Ini: TIniFile;
  IniPath, FileName: string;
  RowCountL, i: Integer;
  PropName, PropValue: string;
begin
  // Zonder gekoppeld object heeft dit geen zin
  if FObject = nil then
  begin
    ShowMessage('Geen ConnectObject gekoppeld.');
    Exit;
  end;
  // Pad naar .\ini\defaultgrid.ini
  IniPath  := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'ini';
  FileName := IncludeTrailingPathDelimiter(IniPath) + 'defaultgrid.ini';
  if not FileExists(FileName) then
  begin
    ShowMessage('defaultgrid.ini niet gevonden: ' + FileName);
    Exit;
  end;
  Ini := TIniFile.Create(FileName);
  try
    // aantal rijen uit [Settings]
    RowCountL := Ini.ReadInteger('Settings', 'RowCount', 0);
    for i := 1 to RowCountL do
    begin
      // propertynaam staat in [Properties] RowX_Name
      PropName := Ini.ReadString('Properties',
                                 'Row' + IntToStr(i) + '_Name',
                                 '');
      if PropName = '' then
        Continue;

      // echte waarde staat in dezelfde sectie onder de propertynaam
      PropValue := Ini.ReadString('Properties', PropName, '');
      // leeg laten we gewoon overslaan
      if PropValue = '' then
        Continue;
      try
        // RTTI zet zelf om (Boolean, Integer, Color, Enum, ...)
        SetPropValue(FObject, PropName, PropValue);
      except
        // Als iets niet gezet kan worden, negeren we dat stilletjes
        // ShowMessage('Kon property ' + PropName + ' niet zetten: ' + PropValue);
      end;
    end;
    // Na toepassen van alle waarden: grid opnieuw vullen
    PopulateGridWithProperties;
    // En gekoppelde control (bv. jouw Grid) hertekenen
    if FObject is TControl then
      TControl(FObject).Invalidate;
  finally
    Ini.Free;
  end;
// laden volgende ini voor defaultschakel.ini
 // Pad naar .\ini\defaultschalel.ini
  IniPath  := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'ini';
  FileName := IncludeTrailingPathDelimiter(IniPath) + 'defaultschakel.ini';
  if not FileExists(FileName) then
  begin
    ShowMessage('defaultschakel.ini niet gevonden: ' + FileName);
    Exit;
  end;
  Ini := TIniFile.Create(FileName);
  try
    // aantal rijen uit [Settings]
    RowCountL := Ini.ReadInteger('Settings', 'RowCount', 0);
    for i := 1 to RowCountL do
    begin
      // propertynaam staat in [Properties] RowX_Name
      PropName := Ini.ReadString('Properties',
                                 'Row' + IntToStr(i) + '_Name',
                                 '');
      if PropName = '' then
        Continue;

      // echte waarde staat in dezelfde sectie onder de propertynaam
      PropValue := Ini.ReadString('Properties', PropName, '');
      // leeg laten we gewoon overslaan
      if PropValue = '' then
        Continue;
      try
        // RTTI zet zelf om (Boolean, Integer, Color, Enum, ...)
        SetPropValue(FObject, PropName, PropValue);
      except
        // Als iets niet gezet kan worden, negeren we dat stilletjes
        // ShowMessage('Kon property ' + PropName + ' niet zetten: ' + PropValue);
      end;
    end;
    // Na toepassen van alle waarden: grid opnieuw vullen
    PopulateGridWithProperties;
    // En gekoppelde control (bv. jouw Box) hertekenen
    if FObject is TControl then
      TControl(FObject).Invalidate;
  finally
    Ini.Free;
  end;
end;




procedure TAdvancedPropertyGrid.PhotoClick(Sender: TObject);
var
Bitmap: TBitmap;
begin
    //Werkt enkel indien ProB2.note is gekoppeld aan de TPageControl
    Bitmap := TBitmap.Create;
      // Stel de grootte in op TPageControl
      Bitmap.Width := FNote.Width;
      Bitmap.Height := FNote.Height;
      // Kopieer de inhoud van TPageControl naar de bitmap
      Bitmap.Canvas.CopyRect(Rect(0, 0, Bitmap.Width, Bitmap.Height),Canvas ,FNote.ClientRect);
      Clipboard.Clear;
      Clipboard.Assign(Bitmap); // Kopieer naar klembord
     // ShowMessage('Screenshot van TPageControl is vastgelegd!');
end;



procedure TInfoBoxForm.ShowInfo(HtmlText: string);
  begin
  FHtml.LoadFromString(HtmlText);  // Laad de HTML in THtmlViewer
  ShowModal;  // Toon het venster
  end;

procedure TInfoBoxForm.FCloseBClick(Sender: TObject);
begin
  Close;
end;

 Procedure TInfoBoxForm.FFhotoBClick(Sender: TObject);
  var
   Screenshot: TBitmap;
 begin
   // Maak een bitmap aan en teken enkel de THtmlViewer-component
   Screenshot := TBitmap.Create;
   try
     Screenshot.Width := FHtml.Width;
     Screenshot.Height := FHtml.Height;
     // Capture alleen FHtml
     FHtml.PaintTo(Screenshot.Canvas, 0, 0);

     // Kopieer de afbeelding naar het klembord
     Clipboard.Assign(Screenshot);
   finally
     Screenshot.Free;
   end;
 end;

{ TInputBoxForm }

constructor TInputBoxForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner); // Gebruik CreateNew in plaats van Create
  Width := 300;
  Height := 150;
  Position := poScreenCenter;
  BorderStyle := bsDialog;

  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  FLabel.Top := 10;
  FLabel.Left := 10;
  FLabel.Width := ClientWidth - 20;

  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.Top := 40;
  FEdit.Left := 10;
  FEdit.Width := ClientWidth - 20;

  FOkButton := TButton.Create(Self);
  FOkButton.Parent := Self;
  FOkButton.Caption := 'OK';
  FOkButton.ModalResult := mrOk;
  FOkButton.Top := 80;
  FOkButton.Left := (ClientWidth-80) div 2;
end;




function TInputBoxForm.Execute(const ACaption, APrompt, ADefault: string; out AResult: string): Boolean;
begin
  Caption := ACaption;
  FLabel.Caption := APrompt;
  FEdit.Text := ADefault;
  Result := ShowModal = mrOk;
  if Result then
    AResult := FEdit.Text;
end;
{ TAdvancedTranslationList }

function TAdvancedTranslationList.GetTranslation(const Key: string): string;
var
  Index: Integer;
begin
  Index := IndexOfName(Key);
  if Index <> -1 then
    Result := ValueFromIndex[Index]
  else
    Result := ''; // Geen vertaling gevonden
end;

{ TAdvancedStringList }

procedure TAdvancedPropertyGrid.ClearSelectionForRow(ARow: Integer);
begin
  if (ARow <= 0) or (ARow >= RowCount) then
    Exit;

  // Checkbox uitzetten in kolom 2
  Cells[2, ARow] := '0';

  // Optioneel: visuele rijselectie ook weg
  if goRowSelect in Options then
    Row := -1;

  Invalidate; // opnieuw tekenen zodat highlight verdwijnt
end;


procedure TAdvancedPropertyGrid.SetNote(Value: TPageControl);
begin
  if FNote <> Value then
  begin
    FNote := Value;
  end;
end;


procedure TAdvancedPropertyGrid.InfoGrid(Sender: TObject);
var
  InfoForm: TInfoBoxForm;
  HtmlText, PropText: string;
  Index: Integer;
  PropName: string;
begin
  if Assigned(FRxTextHolder) then
  begin
    PropName := Self.Name; // Dynamische property name (bijv. PropB22)
    Index := FRxTextHolder.IndexByName(PropName);

    if Index >= 0 then
      PropText := FRxTextHolder.Items[Index].Lines.Text
    else
      PropText := 'Geen informatie beschikbaar voor ' + PropName;

    HtmlText:=Proptext;

  end
  else
  begin
    HtmlText := '<html><body><p>Geen informatie beschikbaar.</p></body></html>';
  end;
  InfoForm := TInfoBoxForm.Create(nil);
  try
    InfoForm.ShowInfo(HtmlText);
  finally
    InfoForm.Free;
  end;
end;


procedure TAdvancedPropertyGrid.UpdateLanguageSelection(NewLanguageText: string);
var
  i: Integer;
begin
  if Assigned(FComboBoxLanguage) then
  begin
    for i := 0 to FComboBoxLanguage.Items.Count - 1 do
    begin
      if SameText(FComboBoxLanguage.Items[i], NewLanguageText) then
      begin
        FComboBoxLanguage.ItemIndex := i;
        Break;
      end;
    end;
  end;
end;




procedure TAdvancedPropertyGrid.SaveIniClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  IniPath: string;
begin
  IniPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'ini';

  // Controleer of de map bestaat, zo niet, maak deze aan
  if not DirectoryExists(IniPath) then
    CreateDir(IniPath);

  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.InitialDir := IniPath;
    SaveDialog.Filter := 'INI bestanden (*.ini)|*.ini|Alle bestanden (*.*)|*.*';
    SaveDialog.DefaultExt := 'ini';
    SaveDialog.FileName := IniPath + '\comboColor.ini';

    if SaveDialog.Execute then
      self.SaveToIniFile(SaveDialog.FileName);
  finally
    SaveDialog.Free;
  end;
end;




procedure TAdvancedPropertyGrid.ChangeLanguage(Sender: TObject);
begin
  CurrentLanguage := TLanguage(TComboBox(Sender).ItemIndex);
  SetLanguage(CurrentLanguage);
  Self.UpdateHeaders;
  Invalidate;
end;


procedure TAdvancedPropertyGrid.SaveToIniFile(const FileName: string);
var
  IniFile: TIniFile;
  RowIndex: Integer;
  PropName, PropValue, ConnectObjectName: string;
  i: Integer;
  RelevantProps: string;
begin
  IniFile := TIniFile.Create(FileName);
  try
    // Sla de verbonden objectnaam op
    if Assigned(FObject) then
      IniFile.WriteString('Settings', 'ConnectObject', FObject.Name);

    // Sla de relevante properties op als een enkele komma-gescheiden string
    RelevantProps := '';
    for i := 0 to FRelevantProperties.Count - 1 do
    begin
      if i > 0 then
        RelevantProps := RelevantProps + ',';
      RelevantProps := RelevantProps + FRelevantProperties[i];
    end;
    IniFile.WriteString('Settings', 'RelevantProperties', RelevantProps);

    // Sla de taalinstelling op

     // Sla de taalinstelling op als string
    IniFile.WriteString('Settings', 'Language', GetEnumName(TypeInfo(TLanguage), Ord(CurrentLanguage)));
    // Sla het aantal rijen op
    IniFile.WriteInteger('Settings', 'RowCount', RowCount - 1);

    // Sla de grid-inhoud en RowTags op
    for RowIndex := 1 to RowCount - 1 do
    begin
      PropName := Cells[0, RowIndex];
      PropValue := Cells[1, RowIndex];
      IniFile.WriteString('Properties', 'Row' + IntToStr(RowIndex) + '_Name', PropName);
      IniFile.WriteString('Properties', PropName, PropValue);
      IniFile.WriteInteger('RowTags', 'Row' + IntToStr(RowIndex) + '_IntValue', FRowTags[RowIndex].IntValue);
      IniFile.WriteString('RowTags', 'Row' + IntToStr(RowIndex) + '_StrValue', FRowTags[RowIndex].StrValue);
    end;
  finally
    IniFile.Free;
  end;
end;



//StrHolder

procedure TAdvancedPropertyGrid.SetStringHolder(AValue: TStrHolder);
begin
  if FStrHolder <> AValue then
  begin
    FStrHolder := AValue;
    if Assigned(FStrHolder) then
    begin
      SetTranslationsFromStringHolder;
    end;
  end;
end;

procedure TAdvancedPropertyGrid.SetTranslationsFromStringHolder;
var
  Ini: TMemIniFile;
  Section, Key, Value: string;
  StringList: TStringList;
  Lang: TLanguage;
  I: Integer;
begin
  if not Assigned(FStrHolder) or (FStrHolder.Strings.Count = 0) then Exit;

  Ini := TMemIniFile.Create('');
  try
    // Laad de strings uit TStringHolder in het INI-formaat
    Ini.SetStrings(FStrHolder.Strings);

    for Lang := Low(TLanguage) to High(TLanguage) do
    begin
      Section := GetEnumName(TypeInfo(TLanguage), Ord(Lang)); // vb. 'lgDutch'

      if Ini.SectionExists(Section) then
      begin
        StringList := TStringList.Create;
        try
          Ini.ReadSectionValues(Section, StringList);

          for I := 0 to StringList.Count - 1 do
          begin
            Key := StringList.Names[I];
            Value := StringList.ValueFromIndex[I];

            if (Key <> '') and (Value <> '') then
              FTranslations.KeyData[Lang].Values[Key] := Value;
          end;
        finally
          StringList.Free;
        end;
      end;
    end;
  finally
    Ini.Free;
  end;

  UpdateHeaders;
  PopulateGridWithProperties;
end;



procedure TAdvancedStringList.AddProperties(const Properties: string);
var
  Prop: string;
  DelimPos: Integer;
  Remaining: string;
begin
  Remaining := Properties;
  while Remaining <> '' do
  begin
    DelimPos := Pos(',', Remaining);
    if DelimPos > 0 then
    begin
      Prop := Trim(Copy(Remaining, 1, DelimPos - 1));
     System.Delete(Remaining, 1, DelimPos);
    end
    else
    begin
      Prop := Trim(Remaining);
      Remaining := '';
    end;
    if Prop <> '' then
      Add(Prop);
  end;
end;

 { TAdvancedPropertyGrid }
constructor TAdvancedPropertyGrid.Create(AOwner: TComponent);
var
  Lang: TLanguage;
  ControlPanel: TPanel;
  BtnWidth, BtnSpacing, ComboWidth: Integer;
  Bmp: TBitmap;
begin
  inherited Create(AOwner);
  //procedure TAdvancedPropertyGrid.UpdateHeaders; ophalen vertalingen

  // Instantieer de interne TTIPropertyGrid
  FInternalTIPropertyGrid := TTIPropertyGrid.Create(Self);
  FInternalTIPropertyGrid.Visible := False; // Verborgen houden
  FInternalTIPropertyGrid.Parent := Self;
  FInternalTIPropertyGrid.Align:=alBottom;

  // Initialiseer de grid
  RowCount := 2;
  ColCount := 4; // verhoogt met 1
  FixedCols := 0;
  FixedRows := 1;
  Options := Options + [goEditing];
  Width := 350;

  ColWidths[0] := 0;
  ColWidths[1] := 135;

  ColWidths[2] := 80; // Breedte van de "Select"-kolom
  ColWidths[3] := 135;

  Cells[0, 0] := 'Eigenschap';
  Cells[1, 0] := 'Waarde';
  Cells[2, 0] := 'Select'; // Nieuwe kolom "Select"
  Cells[3, 0] := 'Eigenschap'; // Nieuwe kolom "Select"
  Flat:=True;
  ScrollBars:= ssNone;
  ExtendedSelect:=true;
 
  // Maak de ImageList aan
  FImageList := TImageList.Create(Self);
  FImageList.Width := 16;  // Pas de breedte aan naar je icoon-grootte
  FImageList.Height := 16;

  // laad SAVE_BMP en LOAD_BMP van Bestand
 {Bmp := TBitmap.Create;
  try
    Bmp.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'save.bmp');
    FImageList.Add(Bmp, nil);
    Bmp.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'load.bmp');
    FImageList.Add(Bmp, nil);
  finally
    Bmp.Free;
  end;}

  { laad SAVE_BMP en LOAD_BMP van resource
    Werkwijze:
    Stap 1: Maak een resourcebestand (.rc)
    Maak een nieuw tekstbestand in je projectmap en noem het bijvoorbeeld resources.rc.
    Voeg hierin regels toe voor je afbeeldingen. Bijvoorbeeld:

    SAVE_BMP  BITMAP "save.bmp"
    LOAD_BMP  BITMAP "load.bmp"

    Met Tool  Resource Hacker (downloaden van het internet
     open  resources.rc  dan action compile script

  }
  Bmp := TBitmap.Create;
  try
    // Laad de 'save.bmp' uit de resource
    Bmp.LoadFromResourceName(HINSTANCE, 'SAVE_BMP');
    FImageList.Add(Bmp, nil);

    // Laad de 'load.bmp' uit de resource
    Bmp.LoadFromResourceName(HINSTANCE, 'LOAD_BMP');
    FImageList.Add(Bmp, nil);

    // Laad de 'close.bmp' uit de resource
    Bmp.LoadFromResourceName(HINSTANCE, 'CLOSE_BMP');
    FImageList.Add(Bmp, nil);

    // Laad de 'close.bmp' uit de resource
    Bmp.LoadFromResourceName(HINSTANCE, 'HELP_BMP');
    FImageList.Add(Bmp, nil);

    // Laad de 'PHOTO.bmp' uit de resource
    Bmp.LoadFromResourceName(HINSTANCE, 'PHOTO_BMP');
    FImageList.Add(Bmp, nil);

    // Laad de 'sluit.bmp' uit de resource
    Bmp.LoadFromResourceName(HINSTANCE, 'SLUIT_BMP');
    FImageList.Add(Bmp, nil);

  finally
    Bmp.Free;
  end;
  FIgnoreSelection:=False;
  FProcessing:=False;
  FMouseDown := False;
  // Initialiseer de relevante properties lijst
  FRelevantProperties :=  TAdvancedStringList.Create;
  FSelectedRow := -1; // Initialiseer met een ongeldige waarde

  // Instantieer de combobox
  FComboBox := TComboBox.Create(Self);// Initialiseer FComboBox
  FComboBox.Visible := False;
  FComboBox.BorderStyle:=bsNone;
  FComboBox.Style := csDropDownList;
  FComboBox.Parent := Self;
  FComboBox.OnChange := @ComboBoxChange;

  FColorBox := TColorBox.Create(Self); // Initialiseer TColorBox
  FColorBox.Visible := False;
  FColorBox.Parent := Self;
  FColorBox.OnChange := @ColorBoxChange;

  // bijkomende buttons en comboBox taal
  // Bepaal de breedtes dynamisch
  BtnWidth := 37;
  BtnSpacing := 4;
  ComboWidth := 102;

   // Voeg een TPanel toe onderaan het grid
   ControlPanel := TPanel.Create(Self);
   ControlPanel.Parent := Self;
   ControlPanel.Align := alBottom;
   ControlPanel.Height := 30;
   ControlPanel.Width := Self.Width -4;
   ControlPanel.Left:=2;
   ControlPanel.BorderStyle:=bsSingle;

   // Save Ini knop
  FSaveButton := TSpeedButton.Create(ControlPanel);
  with FSaveButton do
  begin
  Parent := ControlPanel;
  Left := 4;
  Top := 1;
  Width := BtnWidth;
  Height := 23;
  Glyph := nil; // Geen standaard afbeelding
  Images := FImageList;
  ImageIndex := 0;  // Index van de afbeelding in de ImageList
  OnClick := @SaveIniClick;
  ShowHint := True;
  Hint := 'Save INI'; // Tooltip
  end;

  // Load Ini knop
  FLoadButton := TSpeedButton.Create(ControlPanel);
  with FLoadButton do
  begin
  Parent := self;//ControlPanel;
  Left := 3 + BtnWidth + 4;
  Top := 1;
  Width := BtnWidth;
  Height := 23;
  Glyph := nil; // Geen standaard afbeelding
 // Images := FImageList;
 // ImageIndex := 1;  // Index van de afbeelding in de ImageList
 // OnClick := @LoadIniClick;
  ShowHint := True;
  Hint := 'Load INI'; // Tooltip
  visible:=false;
  end;

   // FMemButton:TSpeedButton;  knop laad default ini's
   FMemButton := TSpeedButton.Create(ControlPanel);
     with FMemButton do
     begin
     Parent := ControlPanel;
     Left := 3 + BtnWidth + 4 ;
     Top := 1;
     Width := BtnWidth;
     Height := 23;
     Glyph := nil; // Geen standaard afbeelding
      Images := FImageList;
     ImageIndex := 1;  // Index van de afbeelding in de ImageList}
     OnClick := @GetClick;
     ShowHint := True;
     //willem
     Hint := 'Laad Standaard settings'; // Tooltip
  end;

   // Taalkeuze combobox
   FComboBoxLanguage := TComboBox.Create(ControlPanel);
   with FComboBoxLanguage do
   begin
   Parent := ControlPanel;
   Left := 3 + BtnWidth + 4 + BtnWidth + 4;
   Top := 1;
   Width := ComboWidth;
   Height := 16;
   Style := csDropDownList;
   ShowHint := True;
   Hint := 'Wijzig Taal van Eigenschappen in Grid'; // Tooltip
     Items.Add('Nederlands');
     Items.Add('Engels');
     Items.Add('Frans');
     Items.Add('Duits');
     ItemIndex := 0; // Stelt 'Nederlands' in als standaard
   OnChange := @ChangeLanguage;
   end;
   // FInfoButton: TSpeedButton;
   FInfoButton := TSpeedButton.Create(ControlPanel);
    with FInfoButton do
    begin
     Parent := ControlPanel;
     //Left := 3 + BtnWidth + 4 + BtnWidth + 4 + ComboWidth + 4 + BtnWidth+4;
      Align:=alRight;
     Top := 1;
     Width := BtnWidth;
     Height := 23;
     ShowHint := True;
     Transparent:=true;
     Hint := 'Info'; // Tooltip
     Glyph := nil; // Geen standaard afbeelding
     Images := FImageList;
     ImageIndex := 3;  // Index van de afbeelding in de ImageList
     FInfoButton.OnClick := @InfoGrid;
   end;

   // FPhoto:TSpeedButton;
    FPhoto := TSpeedButton.Create(ControlPanel);
     with FPhoto do
     begin
     Parent := ControlPanel;
     //Left := 3 + BtnWidth + 4 + BtnWidth + 4 + ComboWidth + 4 + BtnWidth+4 + BtnWidth +4 + BtnWidth +4;
      Align:=alRight;
     Top := 1;
     Width := BtnWidth;
     Height := 23;
     Glyph := nil; // Geen standaard afbeelding
     Images := FImageList;
     ImageIndex := 4;  // Index van de afbeelding in de ImageList
     OnClick := @PhotoClick;
     ShowHint := True;
     Hint := 'Capture'; // Tooltip
  end;
   FCloseButton := TSpeedButton.Create(ControlPanel);
    with FCloseButton do
    begin
     Parent := ControlPanel;
    // Left := 3 + BtnWidth + 4 + BtnWidth + 4+ComboWidth+4;
    Align:=alRight;
     Top := 1;
     Width := BtnWidth;
     Height := 23;
     ShowHint := True;
     Hint := 'Close'; // Tooltip
     Glyph := nil; // Geen standaard afbeelding
     Images := FImageList;
     ImageIndex := 5;  // Index van de afbeelding in de ImageList
     //FCloseButton.OnClick := @CloseGrid;
     FCloseButton.Visible:=True;
   end;


   OnSetEditText := @OnCellEdit;
   OnSelectCell := @SelectCell;
   // Stel de derde kolom in als checkbox-kolom
   DefaultDrawing := False; // Schakel standaard tekenen uit als voorbereiding
   OnDrawCell := @DrawCellHandler; // Voeg een DrawCell-handler toe
   SetLength(FRowTags, RowCount); // Zorg ervoor dat tags zijn gesynchroniseerd met rijen
   // Initialiseer TFPGMap dictionaries
  FTranslations := TStrDict.Create;
  FColumnHeaders := TStrDict.Create;

  // Voeg alle talen toe
  for Lang := Low(TLanguage) to High(TLanguage) do
  begin
    FTranslations.Add(Lang, TStringList.Create);
    FColumnHeaders.Add(Lang, TStringList.Create);
  end;

  { PropB2.InfoTextHolder := InfoTextHolder;
   PropB22.InfoTextHolder := InfoTextHolder;
   PropB222.InfoTextHolder := InfoTextHolder; }

  // Voeg Nederlandse vertalingen toe voor headers
  FColumnHeaders.KeyData[lgDutch].Values['0'] := 'Eigenschap';
  FColumnHeaders.KeyData[lgDutch].Values['1'] := 'Waarde';
  FColumnHeaders.KeyData[lgDutch].Values['2'] := 'Select';
  FColumnHeaders.KeyData[lgDutch].Values['3'] := 'Eigenschap';

  // Voeg Engelse vertalingen toe voor headers
  FColumnHeaders.KeyData[lgEnglish].Values['0'] := 'Property';
  FColumnHeaders.KeyData[lgEnglish].Values['1'] := 'Value';
  FColumnHeaders.KeyData[lgEnglish].Values['2'] := 'Select';
  FColumnHeaders.KeyData[lgEnglish].Values['3'] := 'Property';

  // Voeg Franse vertalingen toe voor headers
  FColumnHeaders.KeyData[lgFrench].Values['0'] := 'Propriété';
  FColumnHeaders.KeyData[lgFrench].Values['1'] := 'Valeur';
  FColumnHeaders.KeyData[lgFrench].Values['2'] := 'Sélectionner';
  FColumnHeaders.KeyData[lgFrench].Values['3'] := 'Propriété';

  // Voeg Duitse vertalingen toe voor headers
  FColumnHeaders.KeyData[lgGerman].Values['0'] := 'Eigenschaft';
  FColumnHeaders.KeyData[lgGerman].Values['1'] := 'Wert';
  FColumnHeaders.KeyData[lgGerman].Values['2'] := 'Auswählen';
  FColumnHeaders.KeyData[lgGerman].Values['3'] := 'Eigenschaft';

  // Standaard taal instellen
  FLanguage := lgDutch;
  UpdateHeaders;
end;

destructor TAdvancedPropertyGrid.Destroy;
var
  Lang: TLanguage;
begin

  // Controleer of FTranslations en FColumnHeaders bestaan vóór vrijgave
  if Assigned(FTranslations) then
  begin
    for Lang := Low(TLanguage) to High(TLanguage) do
    begin
      if Assigned(FTranslations.KeyData[Lang]) then
        FTranslations.KeyData[Lang].Free;
    end;
    FTranslations.Free;
  end;

  if Assigned(FColumnHeaders) then
  begin
    for Lang := Low(TLanguage) to High(TLanguage) do
    begin
      if Assigned(FColumnHeaders.KeyData[Lang]) then
        FColumnHeaders.KeyData[Lang].Free;
    end;
    FColumnHeaders.Free;
  end;

  // Controleer en vernietig overige objecten correct
  FreeAndNil(FRelevantProperties);
  FreeAndNil(FComboBox);
  FreeAndNil(FColorBox);
  FreeAndNil(FInternalTIPropertyGrid);


  inherited Destroy;
end;


procedure TAdvancedPropertyGrid.UpdateHeaders;
var
  ColIndex: Integer;
  HeaderList: TStringList;
begin
  // Kijk of de vertalingen voor de kolommen bestaan
  if FColumnHeaders.TryGetData(FLanguage, HeaderList) then
  begin
    for ColIndex := 0 to ColCount - 1 do
    begin
      if HeaderList.IndexOfName(IntToStr(ColIndex)) <> -1 then
      begin
        Cells[ColIndex, 0] := HeaderList.Values[IntToStr(ColIndex)];
      end;
    end;
  end
  else
  begin
    ShowMessage('Geen vertalingen gevonden voor de kolommen in ' + GetEnumName(TypeInfo(TLanguage), Ord(FLanguage)));
  end;
begin
  case FLanguage of
    lgDutch:
      begin

        FSaveButton.Hint := 'Bewaar INI';
       // FLoadButton.Hint := 'Laad INI';
        FCloseButton.Hint:= 'Sluit Instellingen';
        FMemButton.Hint:='Laad standaard setting';
        FComboBoxLanguage.Hint:= 'Wijzig Taal';
      end;
    lgEnglish:
      begin
        FSaveButton.Hint := 'Save INI';
       // FLoadButton.Hint := 'Load INI';
        FCloseButton.Hint:='Close Settings';
        FMemButton.Hint:='Load default settings';
        FComboBoxLanguage.Hint:= 'Change Language';
      end;
    lgFrench:
      begin
        FSaveButton.Hint := 'Sauvegarder INI';
        //FLoadButton.Hint := 'Charger INI';
        FCloseButton.Hint:='Fermer les paramètres';
        FMemButton.Hint:='Charger les paramètres par défaut';
        FComboBoxLanguage.Hint:= 'Changer de langue';
      end;
    lgGerman:
      begin
        FSaveButton.Hint := 'INI speichern';
        //FLoadButton.Hint := 'INI laden';
        FCloseButton.Hint:='Schließen Sie die Einstellungen';
        FMemButton.Hint:='Standardeinstellungen laden';
        FComboBoxLanguage.Hint:= 'Sprache ändern';
      end;
  end;
end;
Invalidate;  // Dwing hertekenen af
end;


function TAdvancedPropertyGrid.GetTranslation(const ObjName: string): string;
var
  LangIndex: Integer;
begin
  LangIndex := FTranslations.IndexOf(FLanguage);
  if LangIndex <> -1 then
    // Converteer van UTF-8 naar Lazarus string encoding
    Result := UTF8Decode(FTranslations.KeyData[FLanguage].Values[ObjName])
  else
    Result := ObjName;
end;


procedure TAdvancedPropertyGrid.SetLanguage(Value: TLanguage);
begin
  if FLanguage <> Value then
  begin
    FLanguage := Value;
    FCurrentLanguage := Value;
    if Assigned(FStrHolder) then
    begin
      SetTranslationsFromStringHolder;
    end;
    UpdateHeaders;
    PopulateGridWithProperties;
  end;
end;
//----------------------------------------------------------------

procedure TAdvancedPropertyGrid.SetRowTag(ARow: Integer; const ATag: TRowTag);
begin
  if (ARow >= 0) and (ARow < Length(FRowTags)) then
    FRowTags[ARow] := ATag;
 //  ShowMessage('SetRowTag -> Row: '+ IntToStr(ARow) +', IntValue: '+ IntToStr(ATag.IntValue)+ ' StrValue: '+ ATag.StrValue);

 end;

function TAdvancedPropertyGrid.GetRowTag(ARow: Integer): TRowTag;
begin
  if (ARow >= 0) and (ARow < Length(FRowTags)) then
    Result := FRowTags[ARow]
  else
    Result := Default(TRowTag); // Geen tag ingesteld
end;

procedure TAdvancedPropertyGrid.SyncRowTags;
begin
  SetLength(FRowTags, RowCount);
end;

procedure TAdvancedPropertyGrid.AddRowWithProperty(const PropName: string; const PropValue: Variant; const PropType: string);
var
  NewRow: Integer;
  NewTag: TRowTag;
  PropTranslation: string;
begin
  NewRow := RowCount;
  RowCount := RowCount + 1;
  SyncRowTags;

  // Haal de vertaling op voor de eigenschap
  PropTranslation := GetTranslation(PropName);

  // Vul de grid-cellen
  Cells[0, NewRow] := PropName;        // Originele naam
  Cells[1, NewRow] := VarToStr(PropValue); // Eigenschapwaarde
  Cells[3, NewRow] := PropTranslation; // Vertaling van de eigenschap

  // Stel de tag in op basis van het propertytype
  if PropType = 'TGraphicsColor' then
  begin
    NewTag.IntValue := 1;
    NewTag.StrValue := 'Color';
  end
  else if PropType = 'Boolean' then
  begin
    NewTag.IntValue := 2;
    NewTag.StrValue := 'Boolean';
  end
  else
  begin
    NewTag.IntValue := 0;
    NewTag.StrValue := '';
  end;

  SetRowTag(NewRow, NewTag); // Koppel de tag aan de rij
end;



procedure TAdvancedPropertyGrid.SetRelevantProperties(Value: TAdvancedStringList);
begin
  FRelevantProperties.Assign(Value);
 // Vul het grid opnieuw
  if Assigned(FObject) then
    PopulateGridWithProperties;
end;


procedure TAdvancedPropertyGrid.SetRelevantPropertiesString(const Properties: string);
begin
  FRelevantProperties.Clear;                  // Zorg dat oude waarden worden verwijderd
  FRelevantProperties.AddProperties(Properties); // Voeg nieuwe relevante properties toe
  PopulateGridWithProperties;                 // Vul het grid met de relevante properties
end;

procedure TAdvancedPropertyGrid.AddRelevantProperties(const Properties: string);
begin
  SetRelevantPropertiesString(Properties);
end;

procedure TAdvancedPropertyGrid.SetTranslations(const Translations: string);
var
  StrList: TStringList;
  i: Integer;
  Key, Value: string;
begin
  StrList := TStringList.Create;
  try
    StrList.Delimiter := ',';
    StrList.StrictDelimiter := True;
    StrList.DelimitedText := Translations;

    for i := 0 to StrList.Count - 1 do
    begin
      Key := StrList.Names[i];
      Value := StrList.ValueFromIndex[i];

      if Key <> '' then
        // Zet om naar UTF-8 voor opslag
        FTranslations.KeyData[FLanguage].Values[Key] := UTF8Encode(Value);
    end;
  finally
    StrList.Free;
  end;

  UpdateHeaders;
  PopulateGridWithProperties;
end;




procedure TAdvancedPropertyGrid.DrawCellHandler(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  RowTag: TRowTag;
  CellColor: TColor;
  CheckBoxRect, ColorRect: TRect;
  Checked: Boolean;
  DrawFlags: Integer;
  MyTextStyle: TTextStyle;
begin
  // Set default text alignment (Center)
  MyTextStyle := Canvas.TextStyle;
  MyTextStyle.Alignment := taCenter;
  Canvas.TextStyle := MyTextStyle;

  // Set default font color
  Canvas.Font.Color := clNavy;

  // Set bold font for columns 0 and 3
  if (aCol = 1) or (aCol = 3) then
    Canvas.Font.Style := [fsBold]
  else
    Canvas.Font.Style := []; // Reset for other columns

  // Check if the row is selected and change the background color
  if (aRow > 0) and (Cells[2, aRow] = '1') then
  begin
    Canvas.Brush.Color := clInfoBk; // Highlight selected row
    Canvas.FillRect(aRect);
  end
  else
  begin
    Canvas.Brush.Color := Color; // Default background
    Canvas.FillRect(aRect);
  end;

  // Draw checkbox in column 2
  if (aCol = 2) and (aRow > 0) then
  begin
    // Calculate checkbox position
    CheckBoxRect := Rect(
      aRect.Left + (aRect.Width - 16) div 2,
      aRect.Top + (aRect.Height - 16) div 2,
      aRect.Left + (aRect.Width + 16) div 2,
      aRect.Top + (aRect.Height + 16) div 2
    );

    // Check if checkbox is checked
    Checked := Cells[aCol, aRow] = '1';

    // Draw checkbox
    DrawFlags := DFCS_BUTTONCHECK;
    if Checked then
      DrawFlags := DrawFlags or DFCS_CHECKED;
    DrawFrameControl(Canvas.Handle, CheckBoxRect, DFC_BUTTON, DrawFlags);
  end
  // Draw color box in column 1
  else if (aCol = 1) and (aRow > 0) then
  begin
    RowTag := RowTags[aRow];
    if RowTag.StrValue = 'Color' then
    begin
      try
        CellColor := StringToColor(Cells[aCol, aRow]);
      except
        CellColor := clWhite; // Fallback naar wit bij een fout
      end;

      // **Maak de tekstkleur gelijk aan de achtergrondkleur**
      Canvas.Font.Color := CellColor;

      ColorRect := Rect(
        aRect.Left + (aRect.Width - 70) div 2,
        aRect.Top + (aRect.Height - 12) div 2,
        aRect.Left + (aRect.Width + 70) div 2,
        aRect.Top + (aRect.Height + 12) div 2
      );
      Canvas.Brush.Color := CellColor;
      Canvas.FillRect(ColorRect);

      // Teken een rand om het kleurvlakje
      Canvas.Brush.Style := bsClear;
      Canvas.Rectangle(ColorRect);
    end;
  end;
    if RowTag.StrValue = 'Color' then
    begin
      Canvas.Font.Color := CellColor;
      Canvas.TextRect(aRect, aRect.Left + 2, aRect.Top + 2, Cells[aCol, aRow]);
    end
    else
        Canvas.TextRect(aRect, aRect.Left + 2, aRect.Top + 2, Cells[aCol, aRow]);
end;

procedure TAdvancedPropertyGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  GridCol, GridRow: Integer; // Gebruik alternatieve namen
  i: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  MouseToCell(X, Y, GridCol, GridRow);

  // Controleer of het de "Select"-kolom is
  if (GridCol = 2) and (GridRow > 0) then
  begin
    // Deselecteer alle andere checkboxes in de kolom
    for i := 1 to RowCount - 1 do
      if i <> GridRow then
        Cells[GridCol, i] := '0';

    // Schakel de huidige checkbox
    if Cells[GridCol, GridRow] = '1' then
      Cells[GridCol, GridRow] := '0'
    else
      Cells[GridCol, GridRow] := '1';

    // Selecteer de rij
    Selection := TGridRect(Rect(0, GridRow, ColCount - 1, GridRow));

    // Herteken de grid
    Invalidate;
  end;
end;

procedure TAdvancedPropertyGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  FMouseDown := False;
end;

procedure TAdvancedPropertyGrid.SetObject(AObject: TComponent);
begin
  FObject := AObject; // TComponent
  if Assigned(FRelevantProperties) and (FRelevantProperties.Count > 0) then
  PopulateGridWithProperties;
end;

procedure TAdvancedPropertyGrid.PopulateGridWithProperties;
var
  PropList: PPropList;
  PropCount, I, NewRow: Integer;
  PropInfo: PPropInfo;
  PropName, PropType, PropTranslation: string;
  PropValue: Variant;
  RowTag: TRowTag;
begin
  if not Assigned(FObject) then Exit;

  // Haal de lijst van properties op
  PropCount := GetPropList(FObject.ClassInfo, tkAny, nil);
  if PropCount = 0 then Exit;

  GetMem(PropList, PropCount * SizeOf(PPropInfo));
  try
    GetPropList(FObject.ClassInfo, tkAny, PropList);

    // Reset grid
    RowCount := 1; // Alleen de header behouden
    SyncRowTags;   // Zorg dat RowTags synchroon loopt

    for I := 0 to PropCount - 1 do
    begin
      PropInfo := PropList^[I];
      PropName := string(PropInfo^.Name);
      PropType := string(PropInfo^.PropType^.Name);

      // Controleer of de property relevant is
      if (FRelevantProperties.Count = 0) or (FRelevantProperties.IndexOf(PropName) <> -1) then
      begin
        // Voeg een nieuwe rij toe
        NewRow := RowCount;
        RowCount := RowCount + 1;
        SyncRowTags;
        PropTranslation := GetTranslation(PropName); // Haal de vertaling op

        // Vul de cellen in met originele naam, waarde, en vertaling
        Cells[0, NewRow] := PropName; // Originele naam
        Cells[3, NewRow] := PropTranslation; // Vertaling

        // Stel de waarde en tags in
        if PropType = 'Boolean' then
        begin
          PropValue := GetPropValue(FObject, PropName, False);
          Cells[1, NewRow] := BoolToStr(Boolean(PropValue), 'True', 'False');
          RowTag.IntValue := 2;
          RowTag.StrValue := 'Boolean';
        end
        else if PropType = 'TGraphicsColor' then
        begin
          PropValue := GetPropValue(FObject, PropName, True);
          Cells[1, NewRow] := VarToStr(PropValue);
          RowTag.IntValue := 1;
          RowTag.StrValue := 'Color';
        end
        else
        begin
          PropValue := GetPropValue(FObject, PropName, True);
          Cells[1, NewRow] := VarToStr(PropValue);
          RowTag.IntValue := 0;
          RowTag.StrValue := '';
        end;
       // Sla de tags op
        SetRowTag(NewRow, RowTag);
      end;
    end;
    GetTranslation(PropName);
    Invalidate; // Forceer hertekening van het grid
  finally
    FreeMem(PropList);
  end;
end;



procedure TAdvancedPropertyGrid.SetInternalObject(AObject: TObject);
begin
  FInternalObject := AObject; // Sla de waarde op

  if Assigned(FInternalTIPropertyGrid) then
  begin
    SetOrdProp(FInternalTIPropertyGrid, 'TIObject', PtrInt(AObject));
    SyncWithTIObject(FInternalTIPropertyGrid);
  end;
end;

procedure TAdvancedPropertyGrid.DisplayProperties;
var
  PropList: PPropList;
  PropCount, I, RowIndex: Integer;
  PropInfo: PPropInfo;
  BoolValue: Boolean;
  PropName, PropTranslation: string;
begin
  if not Assigned(FObject) then Exit;

  // Haal alleen de relevante propertytypen op
  PropCount := GetPropList(FObject.ClassInfo, [tkInteger, tkString, tkAString, tkFloat, tkBool, tkEnumeration], nil);
  if PropCount = 0 then Exit;

  GetMem(PropList, PropCount * SizeOf(PPropInfo));
  try
    GetPropList(FObject.ClassInfo, [tkInteger, tkString, tkAString, tkFloat, tkBool, tkEnumeration], PropList);

    // Stel het aantal rijen correct in, inclusief de header
    RowCount := 1; // Begin met alleen de header
    RowIndex := 1;

    for I := 0 to PropCount - 1 do
    begin
      PropInfo := PropList^[I];
      PropName := string(PropInfo^.Name);

      // Controleer of de property relevant is
      if (FRelevantProperties.Count = 0) or (FRelevantProperties.IndexOf(PropName) <> -1) then
      begin
        if RowIndex >= RowCount then
          RowCount := RowIndex + 1; // Voeg extra rijen toe als nodig

        // Stel de originele naam van de eigenschap in
        Cells[0, RowIndex] := PropName;

        // Haal de waarde van de eigenschap op
        case PropInfo^.PropType^.Name of
          'Boolean':
            begin
              BoolValue := GetPropValue(FObject, PropName, False);
              Cells[1, RowIndex] := BoolToStr(BoolValue, 'True', 'False');
              Objects[1, RowIndex] := TObject(1); // Boolean marker
            end;
          else
            Cells[1, RowIndex] := GetPropValue(FObject, PropName, True);
        end;

        // Voeg de vertaling toe
        PropTranslation := GetTranslation(PropName);
        Cells[3, RowIndex] := PropTranslation; // Vertaling

        Inc(RowIndex);
      end;
    end;

    // Werk het aantal rijen bij
    if RowCount > RowIndex then
      RowCount := RowIndex;
   // if ColCount > 1 then  Columns[1].ReadOnly := True;
  finally
    FreeMem(PropList);
  end;
end;



procedure TAdvancedPropertyGrid.SyncWithTIObject(TIGrid: TTIPropertyGrid);
var
  PropInfo: PPropInfo;
  TargetObject: TObject;
begin
  if not Assigned(TIGrid) then Exit;

  PropInfo := TypInfo.GetPropInfo(TIGrid.ClassInfo, 'TIObject');

  if Assigned(PropInfo) and (PropInfo^.PropType^.Kind = tkClass) then
  begin
    TargetObject := GetObjectProp(TIGrid, PropInfo);
    if Assigned(TargetObject) and (TargetObject is TComponent) then
    begin
      ConnectObject := TComponent(TargetObject);
    //  DisplayProperties;
    end;
  end;
end;

procedure TAdvancedPropertyGrid.SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
var
  Rect: TRect;
  GridScreenPos, CellScreenPos: TPoint;
  PropName, Value: string;
  PropInfo: PPropInfo;
  InputValue: string;
  PropKindName: string;
  FType: string;
  EnumTypeInfo: PTypeInfo;
  EnumTypeData: PTypeData;
  I: Integer;
  EnumValue: string;
  ParentPageControl: TPageControl;
  NewVal: Integer;
begin
  // Controleer of de checkbox in de "Select"-kolom is aangevinkt
  if (ARow > 0) and (Cells[2, ARow] <> '1') then
  begin
    CanSelect := False;
    Exit;
  end;
  // Initialiseer variabelen
  PropName := '';
  Value := '';
  InputValue := '';
  PropKindName := '';
  FType := '';

  if (ARow > 0) and (ACol = 1) then
  begin
    PropName := Cells[0, ARow];
    Value := Cells[ACol, ARow];
    PropInfo := GetPropInfo(FObject, PropName);
    FSelectedRow := ARow;
    if Assigned(PropInfo) then
    begin
     PropKindName := GetEnumName(TypeInfo(TTypeKind), Ord(PropInfo^.PropType^.Kind));
     FType := PropInfo^.PropType^.Name;
     case FType of
         'NativeInt':
          begin
           // ShowMessage(FType);  // mag weg als debug niet meer nodig
           with TInputBoxForm.Create(Self) do
            try
             if Execute('Wijzig Eigenschap', 'Wijzig de waarde voor ' + PropName + ':',Value, InputValue) then
               begin
                if TryStrToInt(InputValue, NewVal) then
                  begin
                  // 1) ECHT de property zetten
                  SetOrdProp(FObject, PropName, NewVal);
                  // 2) Grid-cel bijwerken
                  Cells[ACol, ARow] := IntToStr(NewVal);
                  // 3) Selectie (checkbox) uitzetten als je ClearSelectionForRow hebt
                  ClearSelectionForRow(ARow);
                  // 4) Als het een visuele control is (zoals jouw Grid): hertekenen
                  if FObject is TControl then TControl(FObject).Invalidate;

                  CanSelect := False;
                  FColorBox.Visible := False;
                  FComboBox.Visible := False;
               end
               else
                  begin
                  ShowMessage('Ongeldige numerieke waarde: ' + InputValue);
                  end;
               end;
                  finally
                 Free;
          end;
      end;
        'TGraphicsColor':
          begin
            Rect := CellRect(ACol, ARow);
            GridScreenPos := ClientToScreen(Point(0, 0));
            CellScreenPos := Point(GridScreenPos.X + Rect.Left, GridScreenPos.Y + Rect.Top);
            CellScreenPos := Parent.ScreenToClient(CellScreenPos);
            FColorBox.SetBounds(
              CellScreenPos.X - Left, //  - 2
              CellScreenPos.Y - Top - 2,
              Rect.Right - Rect.Left,
              Rect.Bottom - Rect.Top
            );
            FColorBox.Selected := TColor(GetOrdProp(FObject, PropName));
            FColorBox.Visible := True;
            FComboBox.Visible := False;
            CanSelect := False;
            FObject.HasParent;
          end;
        'Boolean':
          begin
            Rect := CellRect(ACol, ARow);
            GridScreenPos := ClientToScreen(Point(0, 0));
            CellScreenPos := Point(GridScreenPos.X + Rect.Left, GridScreenPos.Y + Rect.Top);
            CellScreenPos := Parent.ScreenToClient(CellScreenPos);
            FComboBox.SetBounds(
              CellScreenPos.X - Left,
              CellScreenPos.Y - Top - 2,
              Rect.Right - Rect.Left,
              Rect.Bottom - Rect.Top
            );
            FComboBox.Items.Clear;
            FComboBox.Items.Add('True');
            FComboBox.Items.Add('False');
            FComboBox.Text := Value;
            FComboBox.Visible := True;
            FColorBox.Visible := False;
            CanSelect := False;
            FObject.HasParent;
          end;

        'TTranslateString', 'AnsiString', 'LongInt' ,'Integer' :
          begin
            with TInputBoxForm.Create(Self) do
            try
              if Execute('Wijzig Eigenschap', 'Wijzig de tekst voor ' + PropName + ':', Value, InputValue) then
              begin
                SetPropValue(FObject, PropName, InputValue);
                Cells[ACol, ARow] := InputValue;
                // selectie (checkbox) van deze rij weghalen
                 ClearSelectionForRow(FSelectedRow);
                CanSelect := False;
                FColorBox.Visible := False;
                FComboBox.Visible := False;

                FObject.HasParent;
              end;
            finally
              Free;
            end;
          end;
        else
          begin
            if PropInfo^.PropType^.Kind = tkEnumeration then
            begin
              EnumTypeInfo := PropInfo^.PropType;
              EnumTypeData := GetTypeData(EnumTypeInfo);

              FComboBox.SetBounds(
                ColWidths[0] + 2, DefaultRowHeight * ARow, ColWidths[1] - 4, DefaultRowHeight
              );
              FComboBox.Items.Clear;

              for I := EnumTypeData^.MinValue to EnumTypeData^.MaxValue do
              begin
                EnumValue := GetEnumName(EnumTypeInfo, I);
                FComboBox.Items.Add(EnumValue);
              end;

              FComboBox.Text := GetEnumName(EnumTypeInfo, GetOrdProp(FObject, PropName));
              FComboBox.Visible := True;
              FColorBox.Visible := False;
              CanSelect := False;

              FObject.HasParent;
            end
            else
            begin
              FComboBox.Visible := False;
              FColorBox.Visible := False;
              CanSelect := False;
              FObject.HasParent;
            end;
          end;
      end;
    end
    else
    begin
      CanSelect := False;
      FComboBox.Visible := False;
      FColorBox.Visible := False;
    end;
  end
  else
  begin
    CanSelect := False;
    FComboBox.Visible := False;
    FColorBox.Visible := False;
  end;
  ClearSelectionForRow(FSelectedRow);
   FObject.HasParent;
end;

procedure TAdvancedPropertyGrid.ComboBoxChange(Sender: TObject);
var
  PropName: string;
  BoolValue: Boolean;
begin

  if Assigned(FObject) and Assigned(FComboBox) and (FSelectedRow > 0) then
  begin
    // Haal de propertynaam uit de geselecteerde rij
    PropName := Cells[0, FSelectedRow];
    try
      // Controleer of het een booleanwaarde is en zet deze correct om
      if Assigned(Objects[1, FSelectedRow]) and (Objects[1, FSelectedRow] = TObject(1)) then
      begin
        BoolValue := SameText(FComboBox.Text, 'True');
        SetPropValue(FObject, PropName, BoolValue);
        Cells[1, FSelectedRow] := BoolToStr(BoolValue, 'True', 'False'); // Werk de grid bij
      end
      else
      begin
        // Voor niet-booleanwaarden
        SetPropValue(FObject, PropName, FComboBox.Text);
        Cells[1, FSelectedRow] := FComboBox.Text; // Werk de grid bij
      end;

      // Verberg de combobox na een wijziging
      FComboBox.Visible := False;
      FColorBox.visible:=false;

      // selectie (checkbox) van deze rij weghalen
    ClearSelectionForRow(FSelectedRow);
    FObject.HasParent;
    except
      on E: Exception do
        ShowMessage('Fout bij het wijzigen van de waarde: ' + E.Message);
    end;
  end;
end;
procedure TAdvancedPropertyGrid.ColorBoxChange(Sender: TObject);
var
  PropName: string;
  PropValue: Variant;
begin
  if (FSelectedRow > 0) and Assigned(FObject) then
  begin
    PropName := Cells[0, FSelectedRow];
    try
      // 1) Kleur in het object zetten
      SetOrdProp(FObject, PropName, FColorBox.Selected);

      // 2) De tekst in de grid-cel bijwerken (zoals bij het initialiseren)
      PropValue := GetPropValue(FObject, PropName, True);
      Cells[1, FSelectedRow] := VarToStr(PropValue);

    except
      on E: Exception do
        ShowMessage('Fout bij het wijzigen van de kleur: ' + E.Message);
    end;
  end;

  // 3) ColorBox en ComboBox verbergen
  FColorBox.Visible := False;
  FComboBox.Visible := False;

  // 4) Net als bij Boolean: selectie (checkbox) van deze rij uitzetten
  ClearSelectionForRow(FSelectedRow);
  FObject.HasParent;
end;

procedure TAdvancedPropertyGrid.OnCellEdit(Sender: TObject; ACol, ARow: Integer; const Value: string);
var
  PropName: string;
  PropInfo: PPropInfo;
begin
  if (ARow > 0) and (ACol = 1) and Assigned(FObject) then
  begin
    PropName := Cells[0, ARow];
    PropInfo := GetPropInfo(FObject, PropName);
    if Assigned(PropInfo) then
    begin
      try
        case PropInfo^.PropType^.Kind of
          tkBool:
            if SameText(Value, 'True') then
              SetPropValue(FObject, PropName, True)
            else if SameText(Value, 'False') then
              SetPropValue(FObject, PropName, False)
            else
              raise Exception.Create('Invalid value for Boolean');
          else
            SetPropValue(FObject, PropName, Value);
        end;
      except
        on E: Exception do
          ShowMessage('Error setting value for ' + PropName + ': ' + E.Message);
      end;
       // Na edit ook selectie/checkbox uit:
// ClearSelectionForRow(ARow);
     // DisplayProperties;
      FObject.HasParent;
    end;
  end;
end;

procedure Register;
begin
  RegisterComponents('JWHA', [TAdvancedPropertyGrid]);
end;

  {$I propadvance.lrs}
  {$I paneel.lrs}
  end;

end.
