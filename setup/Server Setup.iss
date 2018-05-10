#define APPNAME     "JeonSoft API - Server Setup"
#define APPCODE     "JSAPI"
#define APPVER      "2017"
#define KEY         "string"
#define KEYVALUE    "Parameters"

[Setup]
AppId={#APPNAME}
AppName={#APPNAME}
AppVerName={#APPNAME}
AppVersion={#APPVER}
AppMutex=JEONSOFT_{#APPNAME},Global\JEONSOFT_{#APPNAME}
DefaultDirName={pf}\JeonSoft API
UninstallDisplayName={#APPNAME} {#APPVER}
DefaultGroupName={#APPNAME} {#APPVER}
OutputBaseFilename=JeonSoftAPI - Server Setup
DisableStartupPrompt=True
AppPublisher=Jeonsoft Corporation
AppPublisherURL=http://www.jeonsoft.com
AppSupportURL=http://www.jeonsoft.com
AppUpdatesURL=http://www.jeonsoft.com
ShowLanguageDialog=yes
;WizardImageFile=setupWizard.bmp
;WizardSmallImageFile=setupWizard-small.bmp
PrivilegesRequired=admin
ChangesAssociations=yes
Compression=zip
RestartIfNeededByRun=no
DisableDirPage=yes

[Components]
;ruby components
Name: ruby; Description: Ruby 2.0; Types: full compact custom
;gems
Name: gems; Description: Ruby Gems; Types: full compact custom

[Files]
Source: .\redist\unzip\unzip.exe; DestDir: {tmp}; Components: ruby

[Run]
;Ruby Installation
Filename: {src}\redist\ruby\rubyinstaller-2.0.0-p481.exe; StatusMsg: Installing Ruby 200; Components: ruby; Flags: hidewizard
Filename: {tmp}\unzip.exe; Parameters: "-o ""{src}\redist\ruby\devkit.zip"" -d ""{reg:HKLM\Software\RubyInstaller\MRI\2.0.0,InstallLocation}"""; Statusmsg:  Configuring Ruby on Rails...; Components: ruby
Filename: {reg:HKLM\Software\RubyInstaller\MRI\2.0.0,InstallLocation}\devkit\install.bat; Statusmsg:  Configuring DevKit...; Components: ruby

;Gems
Filename: {reg:HKLM\Software\RubyInstaller\MRI\2.0.0,InstallLocation}\bin\ruby.exe; Parameters: "gem install ""{src}\redist\gems\bundler-1.7.0.gem"""; StatusMsg: Installing gems...; Components: gems
Filename: {reg:HKLM\Software\RubyInstaller\MRI\2.0.0,InstallLocation}\bin\ruby.exe; Parameters: "gem install ""{src}\redist\gems\rack-1.5.2.gem"""; StatusMsg: Installing gems...; Components: gems
Filename: {reg:HKLM\Software\RubyInstaller\MRI\2.0.0,InstallLocation}\bin\ruby.exe; Parameters: "gem install ""{src}\redist\gems\daemons-1.1.9.gem"""; StatusMsg: Installing gems...; Components: gems
Filename: {reg:HKLM\Software\RubyInstaller\MRI\2.0.0,InstallLocation}\bin\ruby.exe; Parameters: "gem install ""{src}\redist\gems\eventmachine-1.0.3-x86-mingw32.gem"""; StatusMsg: Installing gems...; Components: gems
Filename: {reg:HKLM\Software\RubyInstaller\MRI\2.0.0,InstallLocation}\bin\ruby.exe; Parameters: "gem install ""{src}\redist\gems\thin-1.6.2.gem"""; StatusMsg: Installing gems...; Components: gems
Filename: {reg:HKLM\Software\RubyInstaller\MRI\2.0.0,InstallLocation}\bin\ruby.exe; Parameters: "gem install ""{src}\redist\gems\rake-10.3.2.gem"""; StatusMsg: Installing gems...; Components: gems
Filename: {reg:HKLM\Software\RubyInstaller\MRI\2.0.0,InstallLocation}\bin\ruby.exe; Parameters: "gem install ""{src}\redist\gems\thin_service-0.0.7.gem"""; StatusMsg: Installing gems...; Components: gems