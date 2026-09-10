{
  lib,
  stdenvNoCC,
  appimageTools,
  fetchurl,
  unzip,
}:

let
  version = "1.18.30";
  sources = {
    aarch64-darwin = {
      asset = "opencode-desktop-mac-arm64.zip";
      hash = "sha256-jIo7wI+465MxbCwCSIQZJy0ruHHIDUjo+C7t/gwJecs=";
    };
    aarch64-linux = {
      asset = "opencode-desktop-linux-arm64.AppImage";
      hash = "sha256-rC+E4lC9MxZl/6gL4zoZ1o4A2JkbUA75z7zj+Y9tJsg=";
    };
    x86_64-darwin = {
      asset = "opencode-desktop-mac-x64.zip";
      hash = "sha256-egkpcE3LOFihWPgDTOouJDZQKUHynoMBFO5RgathFXI=";
    };
    x86_64-linux = {
      asset = "opencode-desktop-linux-x86_64.AppImage";
      hash = "sha256-S2dXAigyiGRPoH57k+1bzEcybMFWuin0Fy0CICXuMYc=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };

  meta = {
    description = "AI coding agent desktop client";
    homepage = "https://opencode.ai/";
    changelog = "https://github.com/anomalyco/opencode/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "opencode-desktop";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
in
if stdenvNoCC.hostPlatform.isDarwin then
  stdenvNoCC.mkDerivation {
    pname = "opencode-desktop";
    inherit version src meta;

    nativeBuildInputs = [ unzip ];

    sourceRoot = ".";
    dontBuild = true;
    # The app bundle is signed upstream; keep the fixup phase from touching it.
    dontStrip = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications $out/bin
      cp -R OpenCode.app $out/Applications/OpenCode.app
      ln -s $out/Applications/OpenCode.app/Contents/MacOS/OpenCode $out/bin/opencode-desktop

      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      found=$(grep -A1 -F '<key>CFBundleShortVersionString</key>' \
        "$out/Applications/OpenCode.app/Contents/Info.plist" |
        sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
      if [ "$found" != "${version}" ]; then
        echo "expected version ${version}, got '$found'" >&2
        exit 1
      fi

      runHook postInstallCheck
    '';

    passthru.source = src;
  }
else
  appimageTools.wrapType2 {
    pname = "opencode-desktop";
    inherit version src meta;
    passthru.source = src;
  }
