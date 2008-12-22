unit Unit2; 

// WInFF 0.3 Copyright 2006-2008 Matthew Weatherford
// http://winff.org
// Licensed under the GPL v3 or any later version

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, dom, xmlwrite, xmlread, gettext, translations, ExtCtrls,
  ComCtrls, XMLCfg;

type

  { TForm2 }

  TForm2 = class(TForm)
    addpresetbtn: TButton;
    CancelBtn: TButton;
    DeleteBtn: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    export: TButton;
    import: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lbCategory: TListBox;
    ListBox1: TListBox;
    OKbtn: TButton;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    pnlBottom: TPanel;
    SaveDialog1: TSaveDialog;
    Splitter1: TSplitter;
    XMLConfig1: TXMLConfig;
    procedure addpresetbtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure DeleteBtnClick(Sender: TObject);
    procedure Edit4Change(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure exportClick(Sender: TObject);
    procedure importClick(Sender: TObject);
    procedure lbCategoryClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure ListBox1SelectionChange(Sender: TObject; User: Boolean);
    procedure OKbtnClick(Sender: TObject);
    procedure ValidateFields(Var isOkay : Boolean);
    procedure RefreshPresetsBox;

  private
    { private declarations }
  public
    { public declarations }

  end; 

var
  Form2: TForm2; 
  pn:string;
  shown: boolean;

resourcestring
  //captions
   rsform2='Edit Presets';
   rsaddpresetbtn='Add / Update';
   rsexport='Export';
   rsimport='Import';
   rsCancelBtn='Cancel';
   rsOKbtn='Save';
   rsDeleteBtn='Delete';
   rsLabel1='Presets';
   rsLabel2='Preset Name (One word , Only A-z 0-9)';
   rsLabel3='Preset Label';
   rsLabel4='Preset Command Line (no -i or output file)';
   rsLabel5='Output File Extension (no ".")';
   rsLabel6='Category';

  // messages
  rsYouMustEnterNmae = 'You must enter a name.';
  rsYouMustEnterLabel = 'You must enter a label.';
  rsYouMustEnterExtension = 'You must enter the extension.';
  rsUpdatePreset = 'Update Preset:';
  rsLabelMustBeUnique = 'Label must be unique.';
  rsCreatePreset = 'Create Preset:';
  rsRemovePreset = 'Remove Preset:';

implementation

uses unit1;

{ TForm2 }

// get setup
procedure TForm2.FormShow(Sender: TObject);
var
i:integer;
node,subnode: tdomnode;
begin

   TranslateUnitResourceStrings('unit2', PODirectory + 'winff.%s.po', unit1.Lang, unit1.FallbackLang);

   form2.caption:=rsform2;
   addpresetbtn.caption:=rsaddpresetbtn;
   export.caption:=rsexport;
   import.caption:=rsimport;
   cancelbtn.caption:=rsCancelBtn;
   okbtn.caption:=rsOKbtn;
   deletebtn.caption:=rsDeleteBtn;
   label1.caption:=rsLabel1;
   label2.caption:=rsLabel2;
   label3.caption:=rsLabel3;
   label4.caption:=rsLabel4;
   label5.caption:=rsLabel5;
   label6.caption:=rsLabel6;


   lbCategory.Clear;
   lbCategory.Items.AddStrings(form1.categorybox.Items);
   {
   for i:= 0 to presets.ChildNodes.Count -1  do
   begin
    node:= presets.ChildNodes.item[i];
    subnode:= node.FindNode('label');
    listbox1.items.add(subnode.findnode('#text').NodeValue);
   end;
   }

end;



// Get the selected preset's information
procedure TForm2.ListBox1Click(Sender: TObject);
var
i:integer;
selectedtext :string;
node,subnode: tdomnode;
begin
   selectedtext := listbox1.GetSelectedText;
   selectedtext := trim(selectedtext);

   for i:= 0 to presets.childnodes.count -1 do  // find the preset name
   begin
     node := presets.childnodes.item[i];
     subnode:= node.FindNode('label');
     if selectedtext = subnode.findnode('#text').nodevalue then
       pn := node.nodename;
   end;

   if pn <>'' then                    // populate the edit boxes
   begin
     edit1.text:=pn;
     edit2.Text:= presets.FindNode(pn).FindNode('label').FindNode('#text').NodeValue;
     if presets.FindNode(pn).FindNode('params').HasChildNodes then
        edit3.Text:= presets.FindNode(pn).FindNode('params').FindNode('#text').NodeValue
     else
        edit3.Text:='';
     edit4.Text:= presets.FindNode(pn).FindNode('extension').FindNode('#text').NodeValue;
     if presets.FindNode(pn).FindNode('category').HasChildNodes then
        edit5.Text:= presets.FindNode(pn).FindNode('category').FindNode('#text').NodeValue
     else
        edit5.Text:='';
   end;
end;

// add / update a preset
procedure TForm2.addpresetbtnClick(Sender: TObject);
var
s,labeltext: string;
i:integer;

newnode,labelnode,paramsnode,extensionnode,categorynode,
  textl,textp,texte, textc, node,subnode: tdomnode;

isOkay : Boolean;

begin
  if pn = '' then pn := presets.FirstChild.NodeName;
  edit1.Text:=trim(edit1.text);
  edit2.Text:=trim(edit2.text);        // trim everything
  edit3.Text:=trim(edit3.text);
  edit4.Text:=trim(edit4.text);
  edit4.Text:=trim(edit4.text);
  
  ValidateFields(isOkay);             //

  if not (isOkay) then exit;


  if presets.FindNode(pn).NodeName = edit1.text then // update or add
       begin                                       // update preset
       labeltext := presets.findnode(pn).findnode('label').findnode('#text').nodevalue;
       if MessageDlg(rsUpdatePreset + #10#13 + labeltext, mtinformation,
         mbOKCancel, 0) = mrOK then
         begin
         presets.findnode(pn).FindNode('label').FindNode('#text').NodeValue := edit2.text;
         if presets.findnode(pn).FindNode('params').HasChildNodes then
            presets.findnode(pn).FindNode('params').FindNode('#text').NodeValue := edit3.text
         else
            begin
            textp:=presetsfile.CreateTextNode(edit3.Text);
            presets.findnode(pn).FindNode('params').AppendChild(textp);
            end;
         presets.findnode(pn).FindNode('extension').FindNode('#text').NodeValue := edit4.text;
         presets.findnode(pn).FindNode('category').FindNode('#text').NodeValue := edit5.text;
         end;
       end
   else
     begin                               // add a new preset
       for i:= 0 to presets.ChildNodes.Count -1  do
         begin
          node:= presets.ChildNodes.item[i];   // check if label unique
          subnode:= node.FindNode('label');
          if edit2.Text = subnode.findnode('#text').NodeValue then
            begin
            showmessage(rsLabelMustBeUnique);
            exit;
            end;
         end;
      labeltext := edit2.text;
      if MessageDlg(rsCreatePreset + #10#13 + labeltext, mtinformation,
        mbOKCancel, 0) = mrOK then
        begin
         newnode:=presetsfile.CreateElement(edit1.text);  // create the new preset
         presets.AppendChild(newnode);
         labelnode:=presetsfile.CreateElement('label');
         newnode.AppendChild(labelnode);
         paramsnode:=presetsfile.CreateElement('params');
         newnode.AppendChild(paramsnode);
         extensionnode:=presetsfile.CreateElement('extension');
         newnode.AppendChild(extensionnode);
         categorynode:=presetsfile.CreateElement('category');
         newnode.AppendChild(categorynode);

         textl:=presetsfile.CreateTextNode(edit2.text);
         labelnode.AppendChild(textl);
         textp:=presetsfile.CreateTextNode(edit3.Text);
         paramsnode.AppendChild(textp);
         texte:=presetsfile.CreateTextNode(edit4.text);
         extensionnode.AppendChild(texte);
         textc:=presetsfile.CreateTextNode(edit5.text);
         categorynode.AppendChild(textc);
         end;
     end;

  RefreshPresetsBox;
{
  listbox1.Clear;                             // reload the listbox
  for i:= 0 to presets.ChildNodes.Count -1  do
    begin
      node:= presets.ChildNodes.item[i];
      subnode:= node.FindNode('label');
      listbox1.items.add(subnode.findnode('#text').NodeValue);
    end;
}
end;

// delete a preset
procedure TForm2.DeleteBtnClick(Sender: TObject);
var
i:integer;
labeltext :string;
node2delete, node,subnode: tdomnode;
begin
  node2delete:= presets.FindNode(pn);
  labeltext := presets.findnode(pn).findnode('label').findnode('#text').nodevalue;
  if MessageDlg(rsRemovePreset + #10#13 + labeltext, mtinformation, mbOKCancel,
    0) = mrOK then
     begin
       listbox1.Clear;
       presets.RemoveChild(node2delete);
     end;

  RefreshPresetsBox;
{
  listbox1.Clear;
  for i:= 0 to presets.ChildNodes.Count -1  do
    begin
      node:= presets.ChildNodes.item[i];
      subnode:= node.FindNode('label');
      listbox1.items.add(subnode.findnode('#text').NodeValue);
    end;
}
end;

procedure TForm2.Edit4Change(Sender: TObject);
begin
end;

procedure TForm2.FormDropFiles(Sender: TObject; const FileNames: array of String
  );
begin

end;

procedure TForm2.FormResize(Sender: TObject);
begin
{  form2.Height:=429;
  form2.Width:=388;        }
end;


// import a preset
procedure TForm2.importClick(Sender: TObject);
var
 importfile: txmldocument;
 importedpreset: tdomelement;
 i,j:integer;
 newnode,labelnode,paramsnode,extensionnode, categorynode,
  textl,textp,texte, textc, node,subnode: tdomnode;
 nodename,nodelabel,nodeparams,nodeext, nodecategory, testchars:string;
begin
 opendialog1.DefaultExt:='.xml';
 opendialog1.Execute;
 if opendialog1.FileName = '' then exit;
 if not fileexists(opendialog1.FileName) then
    begin
      showmessage(rsFileDoesNotExist);
      exit;
    end;
    
 try
  importfile := TXMLdocument.Create;
 except
 end;
 
 try
   ReadXMLFile(importfile, opendialog1.FileName);
   importedpreset:=importfile.DocumentElement;
 except
  showmessage(rsInvalidPreset);
  exit;
 end;

 if importedpreset.ChildNodes.Count = 0 then exit;

 for j:= 0 to importedpreset.ChildNodes.Count -1 do
 begin

   node:= importedpreset.ChildNodes.Item[j];

   nodename:= node.NodeName;

   for i:= 0 to presets.ChildNodes.Count -1 do
     if presets.ChildNodes.Item[i].NodeName = nodename then
        begin
         showmessage(Format(rsPresetAlreadyExist, ['"', nodename, '"']));
         exit;
        end;

   try
     nodelabel := node.FindNode('label').FindNode('#text').NodeValue;
   except
     begin
       showmessage(rsPresetHasNoLabel);
       exit;
     end;
   end;
 
   try
     testchars := node.FindNode('params').FindNode('#text').NodeValue;
   except
   end;
   for i:= 0 to length(testchars)-1 do
     begin
       if (testchars[i] = #124) or (testchars[i] = #60) or (testchars[i] = #62) or
          (testchars[i] = #59) or (testchars[i] = #38) then
         begin
          showmessage(rsThePresetHasIllegalChars);
          exit;
         end;
     end;
 

   for i:= 0 to presets.ChildNodes.Count -1 do
     if presets.ChildNodes.Item[i].findnode('label').FindNode('#text').NodeValue = nodelabel then
        begin
         showmessage(Format(rsPresetWithLabelExists, ['"', nodelabel, '"']));
         exit;
        end;


   try
     nodeext := node.FindNode('extension').FindNode('#text').NodeValue;
   except
     begin
       showmessage(rsPresethasnoExt);
       exit;
     end;
   end;

   newnode:=presetsfile.CreateElement(nodename);
   presets.AppendChild(newnode);
   labelnode:=presetsfile.CreateElement('label');
   newnode.AppendChild(labelnode);
   paramsnode:=presetsfile.CreateElement('params');
   newnode.AppendChild(paramsnode);
   extensionnode:=presetsfile.CreateElement('extension');
   newnode.AppendChild(extensionnode);
   categorynode:=presetsfile.CreateElement('category');
   newnode.AppendChild(categorynode);

   textl:=presetsfile.CreateTextNode(nodelabel);
   labelnode.AppendChild(textl);

   try
   textp:=presetsfile.CreateTextNode(node.FindNode('params').FindNode('#text').NodeValue);
   except
   textp:=presetsfile.CreateTextNode('');
   end;
   paramsnode.AppendChild(textp);

   texte:=presetsfile.CreateTextNode(nodeext);
   extensionnode.AppendChild(texte);

   try
   textc:=presetsfile.CreateTextNode(node.FindNode('category').FindNode('#text').NodeValue);
   except
   textc:=presetsfile.CreateTextNode('');
   end;
   categorynode.AppendChild(textc);

 end; //for j 1 to childnodes-1

 RefreshPresetsBox;

{
 listbox1.Clear;                             // reload the listbox
  for i:= 0 to presets.ChildNodes.Count -1  do
    begin
      node:= presets.ChildNodes.item[i];
      subnode:= node.FindNode('label');
      listbox1.items.add(subnode.findnode('#text').NodeValue);
    end;
}
end;

procedure TForm2.lbCategoryClick(Sender: TObject);
var i : integer;
    s , cat, pre, ocat : string;
    node, subnode : tdomnode;
begin
  RefreshPresetsBox;
end;

procedure TForm2.RefreshPresetsBox;
var i : integer;
    s , cat, pre, ocat : string;
    node, subnode : tdomnode;
begin

   if lbCategory.SelCount < 1 then exit;
   try
     listbox1.Clear;                             // reload the listbox
     for i:= 0 to presets.ChildNodes.Count -1  do
     begin
          node:= presets.ChildNodes.item[i];
          subnode:= node.FindNode('category');
          cat := subnode.findnode('#text').NodeValue;

          ocat := lbCategory.Items[lbCategory.ItemIndex];
          if cat = ocat then                    // filter presets listbox to match category
          begin;
                subnode:= node.FindNode('label');
                pre := subnode.findnode('#text').NodeValue;
                listbox1.items.add(pre);
          end;
     end;
   except;
   end;
end;


//export a preset
procedure TForm2.exportClick(Sender: TObject);
var
exportfile: txmldocument;
exportpreset: tdomelement;
newnode: tdomnode;
exportfilename:string;
exlabel,exparams,exext,excat: string;
i:integer;
begin
if pn = '' then
  begin
    showmessage(rsPresettoExport);
    exit;
  end;

savedialog1.FileName:=pn + '.wff';
if not savedialog1.Execute then
   exit;

exlabel := presets.FindNode(pn).FindNode('label').FindNode('#text').NodeValue;
exparams := presets.FindNode(pn).FindNode('params').FindNode('#text').NodeValue;
exext := presets.FindNode(pn).FindNode('extension').FindNode('#text').NodeValue;
excat := presets.FindNode(pn).FindNode('category').FindNode('#text').NodeValue;

exportfile := txmldocument.Create;
exportpreset:= exportfile.CreateElement('presets');
exportfile.AppendChild(exportpreset);

newnode := exportfile.CreateElement(pn);
exportpreset.AppendChild(newnode);

newnode := exportfile.CreateElement('label');
exportpreset.FindNode(pn).AppendChild(newnode);
newnode := exportfile.CreateElement('params');
exportpreset.FindNode(pn).AppendChild(newnode);
newnode := exportfile.CreateElement('extension');
exportpreset.FindNode(pn).AppendChild(newnode);
newnode := exportfile.CreateElement('category');
exportpreset.FindNode(pn).AppendChild(newnode);


newnode := exportfile.CreateTextNode(exlabel);
exportpreset.FindNode(pn).FindNode('label').AppendChild(newnode);
newnode := exportfile.CreateTextNode(exparams);
exportpreset.FindNode(pn).FindNode('params').AppendChild(newnode);
newnode := exportfile.CreateTextNode(exext);
exportpreset.FindNode(pn).FindNode('extension').AppendChild(newnode);
newnode := exportfile.CreateTextNode(excat);
exportpreset.FindNode(pn).FindNode('category').AppendChild(newnode);


writexmlfile(exportfile,savedialog1.FileName);


end;

procedure TForm2.ListBox1SelectionChange(Sender: TObject; User: Boolean);
begin

end;

// save & exit
procedure TForm2.OKbtnClick(Sender: TObject);
begin
  writexmlfile(presetsfile, presetspath + 'presets.xml');
  form1.populatepresetbox('');
  form2.close;
end;

// just exit
procedure TForm2.CancelBtnClick(Sender: TObject);
begin
  form1.populatepresetbox('');
  form2.close;
end;

procedure TForm2.ValidateFields(var IsOkay: Boolean);
var i : integer;
    s : string;
begin
  isOkay := False;
  if edit1.text='' then                    // make sure no blanks
   begin
    showmessage(rsYouMustEnterNmae);
    exit;
   end;
  if edit2.text='' then
   begin
    showmessage(rsYouMustEnterLabel);
    exit;
   end;
 // if edit3.text='' then
 //  begin
 //   showmessage('You must enter the parameters.');
 //   exit;
 //  end;
  if edit4.text='' then
   begin
    showmessage(rsYouMustEnterExtension);
    exit;
   end;

  s:=edit1.text;                          // make sure preset name OK
  for i:=1 to length(s) do
   begin
    if  not (  ( ( (ord(s[i])>64) and (ord(s[i])<91) )  or
                 ( (ord(s[i])>96) and (ord(s[i])<123) )     ) or
                 ( ( (ord(s[i])>47) and (ord(s[i])<58) )          )
             )
    then
      begin
        showmessage(rsNameMustBeAllpha);
        exit;
      end;
   end;


  s:=edit4.text;                        // make sure no period in extension

  if pos('.',s) > 0 then                // check for '.' anywhere in extension
                                        //
  //if s[1] = '.' then
   begin
     showmessage(rsExtensionnoperiod);
     exit;
   end;


   isOkay := True;
end;




initialization
  {$I unit2.lrs}

end.

