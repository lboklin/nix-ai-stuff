# parts taken from https://raw.githubusercontent.com/LoganBarnett/dotfiles/36b903679b2b64deb1fd675cd05dc74eb27a6f36/nix/hacks/comfyui/package.nix
# and https://github.com/NixOS/nixpkgs/pull/268378/files#diff-2a93ba588a0085045942c56bcf38c6af39211f1963e48c9bce5705f20cf7cffb
{ lib,
  python311Packages,
  linkFarm,
  writers,
  writeTextFile,
  fetchFromGitHub,
  stdenv,
  config,
  gpuBackend ? (
    if config.cudaSupport
    then "cuda"
    else if config.rocmSupport
    then "rocm"
    else "none"
  ),
  modelsPath ? "/var/lib/comfyui/models",
  inputPath ? "/var/lib/comfyui/input",
  outputPath ? "/var/lib/comfyui/output",
  tempPath ? "/var/lib/comfyui/temp",
  userPath ? "/var/lib/comfyui/user",
  customNodes ? [],
}:

let
  modelPathsFile = writeTextFile {
    name = "model_paths.yaml";
    text = (lib.generators.toYAML {} {
      comfyui = {
        base_path = modelsPath;
        checkpoints = "${modelsPath}/checkpoints";
        inpaint = "${modelsPath}/inpaint";
        ipadapter = "${modelsPath}/ipadapter";
        clip = "${modelsPath}/clip";
        clip_vision = "${modelsPath}/clip_vision";
        configs = "${modelsPath}/configs";
        controlnet = "${modelsPath}/controlnet";
        embeddings = "${modelsPath}/embeddings";
        loras = "${modelsPath}/loras";
        upscale_models= "${modelsPath}/upscale_models";
        vae = "${modelsPath}/vae";
        vae_approx = "${modelsPath}/vae_approx";
      };
    });
  };

  pythonEnv = (python311Packages.python.withPackages (ps: with ps; [
    (
      if gpuBackend == "cuda"
      then torchWithCuda
      else if gpuBackend == "rocm"
      then torchWithRocm
      else torch
    )
    accelerate
    aiohttp
    einops
    kornia
    pillow
    psutil
    pyyaml
    safetensors
    scipy
    torchaudio
    torchsde
    torchvision
    tqdm
    transformers

    # reactor-nodes
    # insightface # [broken dep: mxnet]

    # controlnet-aux
    matplotlib
    opencv4
    scikit-image

    # this doesn't actually work, so all deps have to be added above
  ] ++ (builtins.concatMap (node: node.dependencies) customNodes)));

  executable = writers.writeDashBin "comfyui" ''
    cd $out && \
    ${pythonEnv}/bin/python comfyui \
      --input-directory ${inputPath} \
      --output-directory ${outputPath} \
      --extra-model-paths-config ${modelPathsFile} \
      --temp-directory ${tempPath} \
      "$@"
  '';

  customNodesCollection = (
    linkFarm "comfyui-custom-nodes" (builtins.map (pkg: { name = pkg.pname; path = pkg; }) customNodes)
  );
in stdenv.mkDerivation rec {
  pname = "comfyui";
  version = "unstable-2024-04-07";

  src = fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = "d644b6bcd8991357de674f72eba02d81875d7847";
    hash = "sha256-jT81Fwjr1uz1HSywHTlDu2dvVe4Z1RvF94UFJ04iYPQ=";
  };

  installPhase = ''
    runHook preInstall
    echo "Preparing bin folder"
    mkdir -p $out/bin/
    echo "Copying comfyui files"
    cp -r $src/comfy $out/
    cp -r $src/comfy_extras $out/
    cp -r $src/app $out/
    cp -r $src/web $out/
    cp -r $src/*.py $out/
    mv $out/main.py $out/comfyui
    echo "Copying ${modelPathsFile} to $out"
    cp ${modelPathsFile} $out/extra_model_paths.yaml
    echo "Setting up input and output folders"
    ln -s ${inputPath} $out/input
    ln -s ${outputPath} $out/output
    mkdir -p $out/${tempPath}
    echo "Setting up custom nodes"
    ln -s ${customNodesCollection} $out/custom_nodes
    echo "Copying executable script"
    cp ${executable}/bin/comfyui $out/bin/comfyui
    substituteInPlace $out/bin/comfyui --replace "\$out" "$out"
    echo "Patching python code..."
    substituteInPlace $out/folder_paths.py --replace "if not os.path.exists(input_directory):" "if False:"
    substituteInPlace $out/nodes.py --replace "os.listdir(custom_node_path)" "os.listdir(os.path.realpath(custom_node_path))"
    substituteInPlace $out/nodes.py --replace "os.listdir(input_dir)" "os.listdir(os.path.realpath(input_dir))"
    substituteInPlace $out/folder_paths.py --replace 'os.path.join(os.path.dirname(os.path.realpath(__file__)), "user")' '"${userPath}"'
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    description = "The most powerful and modular stable diffusion GUI with a graph/nodes interface.";
    license = licenses.gpl3;
    platforms = platforms.all;
    maintainers = with maintainers; [ fazo96 ];
  };
}
