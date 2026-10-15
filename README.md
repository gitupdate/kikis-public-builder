# KikisApp public Actions builder

This public repo contains only the build workflow and a decrypt helper. Swift source is privately hosted in gitupdate/qiqu_web and fetched with a read-only deploy key. The workflow uses the standard xcode-27 runner.

Manual builds: open Actions > Build private KikisApp > Run workflow, or use:

    gh workflow run build.yml -R gitupdate/kikis-public-builder -f source_ref=app_widgets
    gh run list -R gitupdate/kikis-public-builder --limit 5
    gh run download RUN_ID -R gitupdate/kikis-public-builder

Download the encrypted artifact, then on the Mac run:

    bash ~/WebstormProjects/kikis-public-builder/decrypt-ipa.sh KikisApp-unsigned.ipa.enc

The decryption password is stored locally at ~/.config/kikis-public-builder/ipa-password, not in this repository. Diagnostics are also encrypted and can be decrypted with the same helper, then extracted from tar.gz.

The app_widgets IPA includes Payload/KikisApp.app/PlugIns/KikisWidget.appex (the legacy branch uses KikisWidgets.appex). The host app and extension need matching provisioning profiles from the same signing team, with compatible App Group entitlements.

All Actions logs are public even though source remains private. Build output, screenshots, and source-derived diagnostic messages are redirected to encrypted artifacts; please do not add steps that print secrets or application source to logs. No pull_request or push triggers are enabled. Standard public hosted runner usage is free subject to GitHub rules and any applicable artifact storage limits.


## Three independent jobs (always run)

Manual builds now launch these three parallel jobs:

1. Unsigned iOS 27 IPA: compile and encrypt IPA plus diagnostics.
2. iPhone 15 visual review: build simulator app and capture the selected source branch's test-data screenshots, then encrypt screenshots and logs as KikisUIReview.tar.gz.enc.
3. Widget extension validation: on app_widgets, validate models, compile and install the app with its embedded extension, then launch the host on iPhone 15. The legacy branch runs its existing Home Screen UI tests. Encrypt results and logs as KikisWidgetIntegration.tar.gz.enc; export screenshots and xcresult when provided by the source branch.

The latter two are separate jobs that run by default, not optional steps of the IPA job. The same private source_ref is checked out using the read-only deploy key for each job. No cleartext screenshots or test bundles are uploaded to the public repository.

Decrypt these archives on your Mac with the same decrypt helper:

    bash decrypt-ipa.sh KikisUIReview.tar.gz.enc
    tar -xzf KikisUIReview.tar.gz

    bash decrypt-ipa.sh KikisWidgetIntegration.tar.gz.enc
    tar -xzf KikisWidgetIntegration.tar.gz

## app_widgets branch support

Manual builds now default to the private app_widgets branch. The IPA job runs
the balance data / HTTP tests and validates the singular KikisWidget.appex
using the private project's check-widget-package.py. Signing instructions
and entitlements are placed in encrypted diagnostics, never public artifacts.

For app_widgets, the third job checks Widget models, simulator compilation,
packaging, iPhone 15 installation and host launch. This is a real simulator
installation test, not a Home Screen gallery UI test; app_widgets does not
yet include a Widget UI XCTest target. Selecting the earlier source branch
still runs its original test-home-widget.sh gallery tests.

## Keep the builder synchronized

When changing private iOS source, shared models, tests, build scripts, project
layout, SDK requirements or packaging, review and update this repository's
`.github/workflows/build.yml` in the same task. Updating the private workflow
alone does not update this public builder. Keep the IPA and Widget validation
jobs' Swift source lists complete, run new relevant tests, and preserve supported
older source layouts. Validate affected commands and run this public workflow
against the intended private source after pushing build changes. Private source
and source-derived diagnostics must remain private or encrypted.


When the selected private source includes remote notification tests, the encrypted
check step also runs its Swift permission/registration tests and Node APNs transport
and 60-second scheduling tests. The selected source's package validator checks its
required host/Widget identities and exports separate host/Widget signing entitlements
inside encrypted diagnostics. Earlier source layouts remain supported.
