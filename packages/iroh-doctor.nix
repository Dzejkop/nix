{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.101.0";
  sources = {
    aarch64-darwin = {
      target = "darwin-aarch64";
      hash = "sha256-iBrr5K+Vc7j06aKcPANZZpuUUHqzfDMSi8iDOTNsg+s=";
    };
    aarch64-linux = {
      target = "linux-aarch64";
      hash = "sha256-uReQheyWtdwAFX5AXQ24Fk7NMLXdC/1OBzagJrzGv3U=";
    };
    x86_64-darwin = {
      target = "darwin-x86_64";
      hash = "sha256-V+madf+UcwDWxSTtv89+kGheq/I54pQOwF4rXEpqeY0=";
    };
    x86_64-linux = {
      target = "linux-x86_64";
      hash = "sha256-c2Qq2GrkUuZBqCFkcZCHFZ+zjFIqyr/MIMjxyH1fSno=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "iroh-doctor";
  inherit version;

  src = fetchurl {
    url = "https://github.com/n0-computer/iroh-doctor/releases/download/v${version}/iroh-doctor-v${version}-${source.target}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 iroh-doctor "$out/bin/iroh-doctor"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/iroh-doctor" --version | grep -F "${version}"

    runHook postInstallCheck
  '';

  meta = {
    description = "Diagnose and test iroh in your network configuration";
    homepage = "https://github.com/n0-computer/iroh-doctor";
    changelog = "https://github.com/n0-computer/iroh-doctor/releases/tag/v${version}";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "iroh-doctor";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
