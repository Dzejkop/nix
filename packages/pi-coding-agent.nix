{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeBinaryWrapper,
  fd,
  ripgrep,
}:

let
  version = "0.85.1";
  sources = {
    aarch64-darwin = {
      asset = "pi-darwin-arm64.tar.gz";
      hash = "sha256-1fcOPAz3OY6sI5/QJh7gdNmLe6f2tD/jYX8FLtW3nQY=";
    };
    aarch64-linux = {
      asset = "pi-linux-arm64.tar.gz";
      hash = "sha256-BC0grohe5POxAoFfMoC5YsN3sun7RN5AN5CMxTDq5NQ=";
    };
    x86_64-darwin = {
      asset = "pi-darwin-x64.tar.gz";
      hash = "sha256-rbkYuEViXxhNi+pAjVXqyvIaqHI4eTwPW087lze85is=";
    };
    x86_64-linux = {
      asset = "pi-linux-x64.tar.gz";
      hash = "sha256-SU5Jj0fXTSH0CzOG9qXpIaPUlTGhacq1W72soOof4lo=";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };
in
stdenvNoCC.mkDerivation {
  pname = "pi-coding-agent";
  inherit version src;

  nativeBuildInputs = [
    makeBinaryWrapper
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  sourceRoot = "pi";
  dontBuild = true;
  # The Bun runtime is appended to the executable; stripping would corrupt it.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi
    cp -R . $out/lib/pi
    chmod -R u+w $out/lib/pi
    makeWrapper $out/lib/pi/pi $out/bin/pi \
      --prefix PATH : ${
        lib.makeBinPath [
          ripgrep
          fd
        ]
      } \
      --set-default PI_SKIP_VERSION_CHECK 1 \
      --set-default PI_TELEMETRY 0

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    # Bun needs a writable HOME.
    export HOME=$(mktemp -d)

    "$out/bin/pi" --version | grep -F "${version}"

    runHook postInstallCheck
  '';

  passthru.source = src;

  meta = {
    description = "AI coding agent CLI with read, bash, edit and write tools";
    homepage = "https://pi.dev/";
    changelog = "https://github.com/earendil-works/pi/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
