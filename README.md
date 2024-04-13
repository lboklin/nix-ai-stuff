# ComfyUI-centric fork of [nix-ai-stuff](https://github.com/BatteredBunny/nix-ai-stuff)
A hacky (but successful) attempt at making ComfyUI work properly. It has a set of [custom nodes](./pkgs/comfyui/custom-nodes.nix). Specifically, it has the [required extensions](https://github.com/Acly/krita-ai-diffusion/wiki/ComfyUI-Setup) for the Stable Diffusion [Krita plugin](https://github.com/Acly/krita-ai-diffusion).

It's a Frankenstein's Monster of other attempts that all don't quite work or are incomplete in various ways. References used:
- [LoganBarnett's ComfyUI package](https://github.com/LoganBarnett/dotfiles/blob/master/nix/hacks/comfyui/)
- [comfyui: init #268378](https://github.com/NixOS/nixpkgs/pull/268378)

`cachix use lboklin` for recent CUDA builds. Build times are extremely painful.

# Additional links pertaining to Nix and ComfyUI
- Custom nodes issue: https://github.com/BatteredBunny/nix-ai-stuff/issues/7
- Nixpkgs package request: https://github.com/NixOS/nixpkgs/issues/227006

# Problems to solve

- [ ] Required models and misc files are not included and must be separately downloaded. (Maybe a starting point: https://github.com/LoganBarnett/dotfiles/blob/master/nix/hacks/comfyui/fetch-model.nix)
- [ ] The [IP Adapter](https://github.com/cubiq/ComfyUI_IPAdapter_plus) custom nodes don't seem to have everything it needs
- [ ] `insightface` dependency is required by [reactor-node](https://github.com/Gourieff/comfyui-reactor-node), but it depends on currently broken `mxnet` (at least with CUDA).
- [ ] Nix packaging practices could most likely use improvements
- [ ] Ensure it's generic enough to be useful for others
  - [ ] Don't hardcode path parameters
  - [ ] Don't hardcode my preferred set of custom nodes
  - [ ] The custom nodes are not quite modular because I couldn't add dependencies to them individually using the same Python environment as the main package
    - [ ] Move custom node dependencies out of ./pkgs/comfyui/default.nix and into ./pkgs/comfyui/custom-nodes.nix

## Packages
- [exllamav2](https://github.com/turboderp/exllamav2) 0.0.9
- [autogptq](https://github.com/PanQiWei/AutoGPTQ) 0.5.1
- [lmstudio](https://lmstudio.ai/) 0.2.17
- [ava](https://www.avapls.com/) 2024-02-05
- [tensor_parallel](https://github.com/BlackSamorez/tensor_parallel) 2.0.0
- [text-generation-inference](https://github.com/huggingface/text-generation-inference) 1.3.3
- [comfyui](https://github.com/comfyanonymous/ComfyUI) unstable-2024-04-07 (patched to run without having to include web files)
- [open-clip-torch](https://github.com/mlfoundations/open_clip) 2.23.0
- [dadaptation](https://github.com/facebookresearch/dadaptation) 3.1
- [prodigyopt](https://github.com/konstmish/prodigy) 1.0
- [lycoris-lora](https://github.com/KohakuBlueleaf/LyCORIS) 2.0.2
- [kohya_ss](https://github.com/bmaltais/kohya_ss) 22.6.1 (patched to run without having to include web files)
