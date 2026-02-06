{
  description = "AI Agent Skills Management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";

    # External skill sources (flake = false: raw git repos)
    openai-skills = {
      url = "github:openai/skills";
      flake = false;
    };
    vercel-agent-skills = {
      url = "github:vercel-labs/agent-skills";
      flake = false;
    };
    vercel-agent-browser = {
      url = "github:vercel-labs/agent-browser";
      flake = false;
    };
    ui-ux-pro-max = {
      url = "github:nextlevelbuilder/ui-ux-pro-max-skill";
      flake = false;
    };
    claude-code-orchestra = {
      url = "github:DeL-TaiseiOzaki/claude-code-orchestra";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      flake-utils,
      ...
    }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      # HM module (usable by external flakes)
      homeManagerModules.default = import ./nix/module.nix;

      # HM configuration: `home-manager switch --flake ~/.agents --impure`
      # --impure required: builtins.getEnv for $USER key, builtins.currentSystem for pkgs
      homeConfigurations.${builtins.getEnv "USER"} =
        let
          username = builtins.getEnv "USER";
          homeDirectory = builtins.getEnv "HOME";
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${builtins.currentSystem};
          modules = [
            self.homeManagerModules.default
            ./home.nix
          ];
          extraSpecialArgs = { inherit inputs username homeDirectory; };
        };
    }
    // flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        agentLib = import ./nix/lib.nix {
          inherit pkgs;
          nixlib = nixpkgs.lib;
        };
        sources = import ./nix/sources.nix { inherit inputs; };
        selection = import ./nix/selection.nix;
        catalog = agentLib.discoverCatalog {
          inherit sources;
          localPath = ./skills-internal;
        };
        enableConfig = if selection ? enable then selection.enable else null;
        localSkillIds = nixpkgs.lib.attrNames
          (nixpkgs.lib.filterAttrs (_: skill: skill.source == "local") catalog);
        enableList =
          if enableConfig == null then
            nixpkgs.lib.attrNames catalog
          else
            nixpkgs.lib.unique (enableConfig ++ localSkillIds);
        selectedSkills =
          if enableConfig == null then
            catalog
          else
            agentLib.selectSkills {
              inherit catalog;
              enable = enableList;
            };
        bundle = agentLib.mkBundle {
          skills = selectedSkills;
          name = "agent-skills-bundle";
        };
      in
      {
        packages.default = bundle;
        packages.bundle = bundle;

        apps = {
          install = {
            type = "app";
            program =
              let
                targetsAttr = import ./nix/targets.nix;
                targetsList = nixpkgs.lib.mapAttrsToList
                  (tool: t: { inherit tool; inherit (t) dest; })
                  (nixpkgs.lib.filterAttrs (_: t: t.enable) targetsAttr);
              in
              "${agentLib.mkSyncScript { inherit bundle; targets = targetsList; }}/bin/skills-install";
          };
          list = {
            type = "app";
            program = "${agentLib.mkListScript { inherit catalog selectedSkills; }}/bin/skills-list";
          };
          validate = {
            type = "app";
            program = "${agentLib.mkValidateScript { inherit catalog selectedSkills bundle; }}/bin/skills-validate";
          };
        };

        checks.default = agentLib.mkChecks { inherit bundle catalog selectedSkills; };

        devShells.default = pkgs.mkShell {
          buildInputs = [ home-manager.packages.${system}.default ];
          shellHook = ''
            echo "Agent Skills Dev Shell"
            echo "  home-manager switch --flake . --impure  # Apply skills"
            echo "  nix run .#list                          # List skills"
          '';
        };

        formatter = pkgs.nixfmt;
      }
    );
}
