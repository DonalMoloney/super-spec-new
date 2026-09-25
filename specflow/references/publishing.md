A spec-kit maintainer submits specflow to the community catalog through the
steps below.

Only a spec-kit maintainer edits the community catalog. Do not open a pull
request against `extensions/catalog.community.json`. The
[Extension Publishing Guide](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md)
forbids it, and every submission goes through an issue instead.

1. Tag the release so `.github/workflows/release.yml` uploads the archive.
2. File an
   [Extension Submission](https://github.com/github/spec-kit/issues/new?template=extension_submission.yml)
   issue. The template asks for the id, the name, the version, the description,
   the author, the license, the repository, the download URL, the required
   spec-kit version, the command and hook counts, the tags, and a testing
   checklist.
3. Paste this entry into the issue's Proposed Catalog Entry field:

   ```json
   {
     "id": "specflow",
     "name": "Specflow",
     "version": "X.Y.Z",
     "description": "Adds brainstorming, task decomposition, TDD execution, and spec review to spec-kit, following obra/superpowers skills when they are installed. The execute command refuses to run until /speckit.analyze reports zero critical inconsistencies. The same command files run on Claude Code and on the GitHub Copilot CLI.",
     "author": "Specflow Contributors",
     "download_url": "https://github.com/DonalMoloney/super-spec-new/releases/download/vX.Y.Z/specflow-vX.Y.Z.zip",
     "repository": "https://github.com/DonalMoloney/super-spec-new",
     "homepage": "https://github.com/DonalMoloney/super-spec-new#readme",
     "changelog": "https://github.com/DonalMoloney/super-spec-new/blob/main/specflow/CHANGELOG.md",
     "license": "MIT",
     "category": "process",
     "effect": "read-write",
     "requires": {
       "speckit_version": ">=0.16.2"
     },
     "provides": {
       "commands": 6,
       "hooks": 5
     },
     "verified": false,
     "created_at": "YYYY-MM-DDT00:00:00Z",
     "updated_at": "YYYY-MM-DDT00:00:00Z",
     "tags": ["superpowers", "brainstorming", "tdd", "code-review", "subagent", "workflow", "claude-code", "copilot"]
   }
   ```

   Swap the released version into all three `X.Y.Z` spots and the release date
   into both `YYYY-MM-DD` spots. Every other value comes from `extension.yml`.
   Read it there, not here. The publishing guide's schema appendix marks
   `downloads` and `stars` as auto-updated, so the entry leaves them out.

   That URL names the release asset `.github/workflows/release.yml` uploads,
   not GitHub's tag ZIP at `archive/refs/tags/vX.Y.Z.zip`. The tag ZIP holds
   the whole repository, so `extension.yml` sits two levels down under
   `super-spec-new-vX.Y.Z/specflow/`, and the install stops with
   `No extension.yml found in archive`.

4. Wait for triage. A spec-kit maintainer applies the `extension-submission`
   label, which starts the catalog validation. A contributor cannot apply that
   label, so there is nothing to label and nothing to ask for.
