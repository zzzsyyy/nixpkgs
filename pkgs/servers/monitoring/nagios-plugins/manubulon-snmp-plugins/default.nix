{
  fetchFromGitHub,
  lib,
  makeWrapper,
  nix-update-script,
  perlPackages,
  stdenv,
  versionCheckHook,
}:
stdenv.mkDerivation rec {
  pname = "manubulon-snmp-plugins";
  version = "2.1.0-unstable-2024-03-13";

  src = fetchFromGitHub {
    owner = "SteScho";
    repo = "manubulon-snmp";
    rev = "1a5afb2486802034146277010d956eba9c2ad54b";
    hash = "sha256-B5CCGMkNv1wGnLQIl0yiGTH2j5MOlj5+MrRqbLNIwhE=";
  };

  buildInputs = with perlPackages; [
    CryptDES
    CryptRijndael
    DigestHMAC
    DigestSHA1
    GetoptLongDescriptive
    NetSNMP
    perl
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall
    mkdir --parents $out/bin
    install --mode=0755 plugins/*.pl $out/bin
    runHook postInstall
  '';

  postFixup = ''
    for f in $out/bin/* ; do
      wrapProgram $f --set PERL5LIB $PERL5LIB --set LC_ALL C
    done
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/check_snmp_int.pl";
  preVersionCheck = ''
    version=${builtins.head (lib.splitString "-" version)}
  '';

  passthru = {
    updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
  };

  meta = {
    changelog = "https://github.com/SteScho/manubulon-snmp/releases/tag/v${version}";
    description = "Set of Icinga/Nagios plugins to check hosts and hardware with the SNMP protocol";
    homepage = "https://github.com/SteScho/manubulon-snmp";
    license = with lib.licenses; [ gpl2Only ];
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ jwillikers ];
  };
}
