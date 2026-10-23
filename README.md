# Private iOS public Actions builder

This public repo contains only build workflows and a decrypt helper. KikisApp source is privately hosted in gitupdate/qiqu_web; YongCan source is privately hosted in gitupdate/yongcan. Each workflow fetches its source with a separate read-only deploy key and uses the existing xcode-27 runner.

| App | Manual workflow | Private source | Default ref |
| --- | --- | --- | --- |
| KikisApp | Build private KikisApp (`build.yml`) | gitupdate/qiqu_web | app_widgets |
| YongCan | Build private YongCan IPA (`build-yongcan.yml`) | gitupdate/yongcan | main |

Manual builds: open Actions > Build private KikisApp > Run workflow, or use:

    gh workflow run build.yml -R gitupdate/kikis-public-builder -f source_ref=app_widgets
    gh run list -R gitupdate/kikis-public-builder --limit 5
    gh run download RUN_ID -R gitupdate/kikis-public-builder

Download the encrypted artifact, then on the Mac run:

    bash ~/WebstormProjects/kikis-public-builder/decrypt-ipa.sh KikisApp-unsigned.ipa.enc

The decryption password is stored locally at ~/.config/kikis-public-builder/ipa-password, not in this repository. Diagnostics are also encrypted and can be decrypted with the same helper, then extracted from tar.gz.

The app_widgets IPA includes Payload/KikisApp.app/PlugIns/KikisWidget.appex (the legacy branch uses KikisWidgets.appex). The host app and extension need matching provisioning profiles from the same signing team, with compatible App Group entitlements.

All Actions logs are public even though source remains private. Build output, screenshots, and source-derived diagnostic messages are redirected to encrypted artifacts; please do not add steps that print secrets or application source to logs. No pull_request or push triggers are enabled. Standard public hosted runner usage is free subject to GitHub rules and any applicable artifact storage limits.


## KikisApp: three independent jobs (always run)

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

## YongCan unsigned IPA

Open Actions > **Build private YongCan IPA** > Run workflow. Choose a private
branch, tag or commit with `source_ref` (default `main`); protocol tests are
enabled by default. This independent workflow does not run KikisApp's three jobs.

```sh
gh workflow run build-yongcan.yml -R gitupdate/kikis-public-builder -f source_ref=main
gh run list -R gitupdate/kikis-public-builder --workflow build-yongcan.yml --limit 5
gh run download RUN_ID -R gitupdate/kikis-public-builder
```

The job runs `swift test`, installs XcodeGen if needed, generates the project,
archives the unsigned iPhone app, and checks its bundle ID, iOS 17 minimum,
arm64 executable and IPA archive integrity. The Actions run number supplies
the build number. Signing certificates and provisioning profiles are not needed.

After validating the IPA, the same job builds an isolated `UI_REVIEW` simulator
app, installs it on a temporary iPhone 15, and captures 30 screenshots: 14 real
SwiftUI scenes in light/dark plus two accessibility text layouts. The private
source's `scripts/capture-ui.sh` waits for per-scene readiness, validates scenario
state and PNG dimensions, and produces a source-commit/SHA256 manifest. Sample
data replaces credentials and business requests; the review mode is absent from
the device build. The temporary simulator is shut down and deleted on exit.

The artifact `YongCan-build-RUN_NUMBER` contains only:

- `YongCan-unsigned.ipa.enc`, after a successful package validation.
- `YongCanDiagnostics.tar.gz.enc`, including private build/test logs and the
  plaintext IPA's checksum; diagnostics are uploaded even when building fails.
- `YongCanUIReview.tar.gz.enc`, containing PNGs, readiness metadata and the
  manifest. If screenshot capture fails, available partial outputs are encrypted
  for diagnosis; a successful run requires all 30 images.

Decrypt with the same password file and helper used for KikisApp:

```sh
bash decrypt-ipa.sh YongCan-unsigned.ipa.enc
bash decrypt-ipa.sh YongCanDiagnostics.tar.gz.enc
bash decrypt-ipa.sh YongCanUIReview.tar.gz.enc
tar -xzf YongCanDiagnostics.tar.gz
mkdir -p ui-review && tar -xzf YongCanUIReview.tar.gz -C ui-review
shasum -a 256 -c YongCanPrivateLogs/YongCan-unsigned.ipa.sha256
```

After decryption, sign `YongCan-unsigned.ipa` with your own certificate to install
it. No cleartext source, IPA or source-derived diagnostic output is published.
The workflow is manual-only; pushing either repository does not start it.

Required Actions secrets in this public repository:

- `YONGCAN_PRIVATE_DEPLOY_KEY`: a dedicated read-only deploy key registered on
  `gitupdate/yongcan`, separate from `KIKIS_PRIVATE_DEPLOY_KEY`.
- `KIKIS_ARTIFACT_PASSWORD`: the existing shared artifact encryption password.

Keep the YongCan workflow synchronized with that private project's package,
XcodeGen configuration and iOS SDK requirements. The private repository's
`.github/workflows/ios.yml` remains a separate manual workflow.
