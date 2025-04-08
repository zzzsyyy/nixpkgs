{
  lib,
  fetchFromGitHub,
  rustPlatform,
  fetchurl,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "flaca";
  version = "3.3.1";

  lockFile = fetchurl {
    url = "https://github.com/Blobfolio/flaca/releases/download/v${finalAttrs.version}/Cargo.lock";
    hash = "sha256-SpPXpgDjgoR5ZKpTJtjF3AQwqVM3/ZU8JSo2NM+VjnA=";
  };

  src = fetchFromGitHub {
    owner = "Blobfolio";
    repo = "flaca";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QxyxRYtw0MjJ7n+ntbyYgYRlTfiR0oC/sFWDnS2t4xk=";
  };

  postUnpack = ''
    ln -s ${finalAttrs.lockFile} ${finalAttrs.src.name}/Cargo.lock
  '';

  nativeBuildInputs = [ rustPlatform.bindgenHook ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-D0o6HVuXQb3oED2yXkS8x55wfKhh03wWCpS95i3AFrA=";

  meta = with lib; {
    description = "CLI tool to losslessly compress JPEG and PNG images";
    longDescription = "A CLI tool for x86-64 Linux machines that simplifies the task of maximally, losslessly compressing JPEG and PNG images for use in production web environments";
    homepage = "https://github.com/Blobfolio/flaca";
    changelog = "https://github.com/Blobfolio/flaca/releases/tag/v${finalAttrs.version}";
    maintainers = with maintainers; [ zzzsy ];
    platforms = platforms.linux;
    license = licenses.wtfpl;
    mainProgram = "flaca";
  };
})
