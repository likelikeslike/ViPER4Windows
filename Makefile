MSBUILD  ?= MSBuild
FLUTTER  ?= flutter
ISCC     ?= ISCC
APO_PROJ  = ViPER4WindowsAPO\ViPER4WindowsAPO.vcxproj
ISS_FILE  = Installer\ViPER4Windows.iss
UI_DIR    = ViPER4Windows

VERSION_NAME ?= 1.0.0
VERSION_CODE ?= 260409

.PHONY: all app driver installer clean l10n assets

all: installer

driver:
	set "CL=/DVERSION_CODE=$(VERSION_CODE) /DVERSION_NAME=\"$(VERSION_NAME)\"" && $(MSBUILD) $(APO_PROJ) /p:Configuration=Release /p:Platform=x64 /m /v:minimal

l10n:
	cd $(UI_DIR) && $(FLUTTER) gen-l10n

assets:
	copy /y $(UI_DIR)\assets\app_icon.ico $(UI_DIR)\windows\runner\resources\app_icon.ico

app: l10n assets
	cd $(UI_DIR) && $(FLUTTER) clean && $(FLUTTER) pub get && $(FLUTTER) build windows --release

installer: driver app
	$(ISCC) $(ISS_FILE)

clean:
	cd $(UI_DIR) && $(FLUTTER) clean
	if exist ViPER4WindowsAPO\build rmdir /s /q ViPER4WindowsAPO\build
	if exist build\installer rmdir /s /q build\installer
