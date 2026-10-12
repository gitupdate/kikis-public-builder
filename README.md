# KikisApp public Actions builder

This public repo contains only the build workflow and a decrypt helper. Swift source is privately hosted in gitupdate/qiqu_web and fetched with a read-only deploy key. The workflow uses the standard xcode-27 runner.

Manual builds: open Actions > Build private KikisApp > Run workflow, or use:

    gh workflow run build.yml -R gitupdate/kikis-public-builder -f source_ref=codex/ios-widgets-live-activities
    gh run list -R gitupdate/kikis-public-builder --limit 5
    gh run download RUN_ID -R gitupdate/kikis-public-builder

Download the encrypted artifact, then on the Mac run:

    bash /Users/lxk/WebstormProjects/kikis-public-builder/decrypt-ipa.sh KikisApp-unsigned.ipa.enc

The decryption password is stored locally at ~/.config/kikis-public-builder/ipa-password, not in this repository. Diagnostics are also encrypted and can be decrypted with the same helper, then extracted from tar.gz.

Unsigned IPA includes Payload/KikisApp.app/PlugIns/KikisWidgets.appex and requires separate signing identities or matching provisioning profiles as applicable to main app and extension, with compatible App Group entitlements.

All Actions logs are public even though source remains private. Build output, screenshots, and source-derived diagnostic messages are redirected to encrypted artifacts; please do not add steps that print secrets or application source to logs. No pull_request or push triggers are enabled. Standard public hosted runner usage is free subject to GitHub rules and any applicable artifact storage limits.

