{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit propadvance;

{$warn 5023 off : no warning about unused units}
interface

uses
  AdvancedPropertyGridComponent, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('AdvancedPropertyGridComponent', 
    @AdvancedPropertyGridComponent.Register);
end;

initialization
  RegisterPackage('propadvance', @Register);
end.
