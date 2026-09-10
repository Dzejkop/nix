{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
  makeWrapper,
  nodejs,
  writableTmpDirAsHomeHook,
  versionCheckHook,
}:

buildNpmPackage (finalAttrs: {
  pname = "deepseek-harness";
  version = "0.1.5-rc.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-${finalAttrs.version}.tgz";
    hash = "sha256-9MVIOdaegr8cOlpBqRDDzhQFzZ6dl9dTwMBPQGx9dIA=";
  };

  # The published package lists unpublished workspace packages (e.g.
  # @deepseek-ai/dsh-experimental-code-runtime-python) as devDependencies,
  # which cannot be resolved from the registry. Drop them and use the vendored
  # lockfile, which was generated the same way.
  postPatch = ''
    ${lib.getExe jq} 'del(.devDependencies)' package.json > package.json.new
    mv package.json.new package.json
    cp ${./deepseek-harness-package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-y302Y7dSA1mX3m3XDsCvrubKqEi31QNSahs3ebhGEMk=";

  nativeBuildInputs = [ makeWrapper ];

  # The published tarball ships the built lib/; there is nothing to compile.
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    packageDir=$out/lib/node_modules/@deepseek-ai/dsh
    mkdir -p "$packageDir" $out/bin
    cp -R lib package.json README.md README.zh.md LICENSE "$packageDir/"
    cp -R node_modules "$packageDir/node_modules"

    makeWrapper ${lib.getExe nodejs} $out/bin/dsh \
      --add-flags "$packageDir/lib/bin.js"

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Plugin-based agent harness for coding and long-running tasks";
    homepage = "https://www.deepseek.com/harness/en/";
    changelog = "https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
  };
})
