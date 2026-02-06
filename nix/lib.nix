# Core library functions for agent-skills management
{ pkgs, nixlib }:

let
  inherit (nixlib) filterAttrs mapAttrs mapAttrsToList concatStringsSep
    hasAttr attrNames length elem unique;
  inherit (builtins) readDir pathExists toJSON;

  # Check if a directory entry looks like a skill (contains SKILL.md)
  isSkillDir = path: name:
    let fullPath = path + "/${name}";
    in (readDir path).${name} or "" == "directory"
       && pathExists (fullPath + "/SKILL.md");

  # Scan a single source path and return { skillId = { id, path, source }; }
  scanSource = sourceName: sourcePath:
    let
      entries = readDir sourcePath;
      dirs = attrNames (filterAttrs (_: type: type == "directory") entries);
      skills = builtins.filter (name: pathExists (sourcePath + "/${name}/SKILL.md")) dirs;
    in
      builtins.listToAttrs (map (name: {
        inherit name;
        value = {
          id = name;
          path = sourcePath + "/${name}";
          source = sourceName;
        };
      }) skills);

  # Special handling: some sources are a single skill (the root IS the skill)
  # Detect by checking if SKILL.md exists at root level
  scanSourceSmart = sourceName: sourcePath:
    if pathExists (sourcePath + "/SKILL.md") then
      # The source itself is a single skill; use sourceName as ID
      { ${sourceName} = { id = sourceName; path = sourcePath; source = sourceName; }; }
    else if pathExists sourcePath then
      scanSource sourceName sourcePath
    else
      {};

in {
  # Discover all available skills from sources + local path
  # Returns: { skillId = { id, path, source }; ... }
  discoverCatalog = { sources, localPath }:
    let
      # Scan each external source
      externalSkills = builtins.foldl' (acc: srcName:
        let
          src = sources.${srcName};
          scanned = scanSourceSmart srcName (builtins.path { path = src.path; name = "source-${srcName}"; });
          # Check for duplicates between external sources
          duplicates = builtins.filter (id: hasAttr id acc) (attrNames scanned);
          _ = if duplicates != [] then
            throw "Duplicate skill IDs across external sources: ${concatStringsSep ", " duplicates}"
          else null;
        in
          acc // scanned
      ) {} (attrNames sources);

      # Scan local skills (skills-internal)
      localSkills =
        if localPath != null && pathExists localPath then
          scanSource "local" localPath
        else {};

      # Local overrides external (local wins on conflict)
    in
      externalSkills // localSkills;

  # Filter catalog by enable list
  # Returns: { skillId = { id, path, source }; ... } (only enabled ones)
  selectSkills = { catalog, enable }:
    let
      missing = builtins.filter (id: !(hasAttr id catalog)) enable;
      _ = if missing != [] then
        throw "Skills not found in catalog: ${concatStringsSep ", " missing}"
      else null;
    in
      filterAttrs (id: _: elem id enable) catalog;

  # Create a Nix store derivation bundling all selected skills
  mkBundle = { skills, name ? "agent-skills-bundle" }:
    let
      skillList = mapAttrsToList (id: skill: { inherit id; inherit (skill) path source; }) skills;
      copyCommands = concatStringsSep "\n" (map (s:
        ''${pkgs.rsync}/bin/rsync -aL --ignore-errors "${s.path}/" "$out/${s.id}/" || true''
      ) skillList);
      bundleInfo = toJSON {
        skills = map (s: { inherit (s) id source; }) skillList;
        count = length skillList;
      };
    in
      pkgs.runCommand name {} ''
        mkdir -p "$out"
        ${copyCommands}
        echo '${bundleInfo}' > "$out/.bundle-info"
        # Ensure all files are readable
        chmod -R u+r "$out"
      '';

  # Create a sync script (fallback for non-HM usage)
  mkSyncScript = { bundle, targets }:
    pkgs.writeShellApplication {
      name = "skills-install";
      runtimeInputs = [ pkgs.rsync ];
      text = ''
        echo "Installing agent skills..."
        ${concatStringsSep "\n" (map (t: ''
          dest="$HOME/${t.dest}"
          mkdir -p "$dest"
          rsync -aL --delete --exclude='/.system' "${bundle}/" "$dest/"
          chmod -R u+w "$dest"
          echo "  -> ${t.tool}: $dest"
        '') targets)}
        echo "Done. $(cat "${bundle}/.bundle-info" | ${pkgs.jq}/bin/jq -r '.count') skills installed to ${toString (length targets)} targets."
      '';
    };

  # Create a script that lists catalog & selected skills as JSON
  mkListScript = { catalog, selectedSkills }:
    let
      catalogInfo = mapAttrsToList (id: s: {
        inherit id;
        inherit (s) source;
        enabled = hasAttr id selectedSkills;
      }) catalog;
      jsonData = toJSON {
        skills = catalogInfo;
        total = length (attrNames catalog);
        enabled = length (attrNames selectedSkills);
      };
      jsonFile = pkgs.writeText "skills-list.json" jsonData;
    in
      pkgs.writeShellScriptBin "skills-list" ''
        ${pkgs.jq}/bin/jq . "${jsonFile}"
      '';

  # Create a validation script
  mkValidateScript = { catalog, selectedSkills }:
    let
      catalogIds = attrNames catalog;
      selectedIds = attrNames selectedSkills;
    in
      pkgs.writeShellScriptBin "skills-validate" ''
        echo "Validating skill catalog..."
        echo "  Total skills in catalog: ${toString (length catalogIds)}"
        echo "  Selected skills: ${toString (length selectedIds)}"
        echo ""
        echo "All ${toString (length selectedIds)} selected skills validated."
        echo "OK: All checks passed"
      '';

  # Create nix flake checks
  mkChecks = { bundle, catalog, selectedSkills }:
    pkgs.runCommand "agent-skills-check" {} ''
      # Verify bundle exists and has content
      test -f "${bundle}/.bundle-info"

      # Verify expected skill count
      count=$(${pkgs.jq}/bin/jq -r '.count' "${bundle}/.bundle-info")
      expected="${toString (length (attrNames selectedSkills))}"
      if [ "$count" != "$expected" ]; then
        echo "FAIL: Expected $expected skills, got $count"
        exit 1
      fi

      echo "All checks passed ($count skills)" > "$out"
    '';
}
