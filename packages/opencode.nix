{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeBinaryWrapper,
  ripgrep,
  sysctl,
  unzip,
}:

let
  version = "1.18.30";
  sources = {
    aarch64-darwin = {
      asset = "opencode-darwin-arm64.zip";
      hash = "sha256-peQ9aIc4bvx9aM5Jrijju9/e49/R1xabYSw85n5Tseg=";
    };
    aarch64-linux = {
      asset = "opencode-linux-arm64.tar.gz";
      hash = "sha256-QRGlXCoCwPrDFL1R6aIzAoDm0p0rhblVT/9tYmElZu0=";
    };
    x86_64-darwin = {
      asset = "opencode-darwin-x64.zip";
      hash = "sha256-dFMAflj/EiQBQ42VzLJDNIdLWQjcrud4g/lsIzldVxA=";
    };
    x86_64-linux = {
      asset = "opencode-linux-x64.tar.gz";
      hash = "sha256-VQByRoWBZUlv+FuhwrZI90IejiATv0GJpoDJ/45pnRc=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };
in
stdenvNoCC.mkDerivation {
  pname = "opencode";
  inherit version src;

  nativeBuildInputs = [
    makeBinaryWrapper
    unzip
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  sourceRoot = ".";
  dontBuild = true;
  # The Bun runtime is appended to the executable; stripping would corrupt it.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 opencode $out/bin/opencode
    wrapProgram $out/bin/opencode \
      --prefix PATH : ${
        lib.makeBinPath ([ ripgrep ] ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [ sysctl ])
      } \
      --set OPENCODE_DISABLE_AUTOUPDATE true

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    # Bun needs a writable HOME and TMPDIR; the build root already contains a
    # file called "opencode", which collides with Bun's temp directory.
    export HOME=$(mktemp -d)
    export TMPDIR=$(mktemp -d)

    "$out/bin/opencode" --version | grep -F "${version}"

    runHook postInstallCheck
  '';

  passthru.source = src;

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://opencode.ai/";
    changelog = "https://github.com/anomalyco/opencode/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
