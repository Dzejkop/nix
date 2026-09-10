{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.5.3";
  sources = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-7fkIFP+9ADGW3lTs0uEup23sSqn4aeCSiQ4dHtdBkXk=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-0H3QPT1gYfBVOTBVUcibWZIPybEYMWyabBghYyYY2YM=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-Movqt+yQNfSbNWfSSY0P9hj6oaNB6KcblEDUTrJUt9U=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-OHeUAqJP92nm9tFoTURkPrWqfbmCToPxy7zjjg4vC64=";
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
