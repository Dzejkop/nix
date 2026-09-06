{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.5.1";
  sources = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-YBHX9wRREBkqqU9PST/gJHGz8R1d/zwxc8bcwqZh4RM=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-vycSjlTSjTGv8XmlUdWW3P2e6t/GoDI3i0Bjzi/Rb3I=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-6LQpsbL732vDMQH5NlmuFyGrThR37GPeLCE0tRBo3G8=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-H00/EvkCnKbMw3ONFb3w+JouDeDHZNNgiX5QgQLktb4=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "maki";
  inherit version;

  src = fetchurl {
    url = "https://github.com/tontinton/maki/releases/download/v${version}/maki-v${version}-${source.target}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 maki "$out/bin/maki"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/maki" --version | grep -F "${version}"

    runHook postInstallCheck
  '';

  meta = {
    description = "Efficient AI coding agent extendable with Lua plugins";
    homepage = "https://maki.sh/";
    changelog = "https://github.com/tontinton/maki/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "maki";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
