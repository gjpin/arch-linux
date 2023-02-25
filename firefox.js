// Set homepage
user_pref("browser.startup.homepage", "chrome://browser/content/blanktab.html");

// Enable FFMPEG VA-API
user_pref("media.ffmpeg.vaapi.enabled", true);

// Disable title bar
user_pref("browser.tabs.inTitlebar", 1);

// Disable View feature
user_pref("browser.tabs.firefox-view", false);

// Disable List All Tabs button
user_pref("browser.tabs.tabmanager.enabled", false);

// Disable password manager
user_pref("signon.rememberSignons", false);

// Disable default browser check
user_pref("browser.shell.checkDefaultBrowser", false);

// Enable scrolling with middle mouse button
user_pref("general.autoScroll", true);

// Dev tools zoom
user_pref("devtools.toolbox.zoomValue", 1.1);

// Enable Firefox Tracking Protection
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("network.cookie.cookieBehavior", 5);

// Disable Mozilla telemetry/experiments
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("experiments.supported", false);
user_pref("experiments.enabled", false);
user_pref("experiments.manifest.uri", "");

// Disallow Necko to do A/B testing
user_pref("network.allow-experiments", false);

// Disable collection/sending of the health report
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.healthreport.service.enabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("browser.discovery.enabled", false);

// Disable Pocket
user_pref("browser.pocket.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);

// Disable Location-Aware Browsing (geolocation)
user_pref("geo.enabled", false);

// Disable "beacon" asynchronous HTTP transfers (used for analytics)
user_pref("beacon.enabled", false);

// Disable speech recognition
user_pref("media.webspeech.recognition.enable", false);

// Disable speech synthesis
user_pref("media.webspeech.synth.enabled", false);

// Disable pinging URIs specified in HTML <a> ping= attributes
user_pref("browser.send_pings", false);

// Don't try to guess domain names when entering an invalid domain name in URL bar
user_pref("browser.fixup.alternate.enabled", false);

// Opt-out of add-on metadata updates
user_pref("extensions.getAddons.cache.enabled", false);

// Opt-out of themes (Persona) updates
user_pref("lightweightThemes.update.enabled", false);

// Disable Flash Player NPAPI plugin
user_pref("plugin.state.flash", 0);

// Disable Java NPAPI plugin
user_pref("plugin.state.java", 0);

// Disable Gnome Shell Integration NPAPI plugin
user_pref("plugin.state.libgnome-shell-browser-plugin", 0);

// Updates addons automatically
user_pref("extensions.update.enabled", true);

// Enable add-on and certificate blocklists (OneCRL) from Mozilla
user_pref("extensions.blocklist.enabled", true);
user_pref("services.blocklist.update_enabled", true);

// Disable Extension recommendations
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr", false);

// Disable sending Firefox crash reports to Mozilla servers
user_pref("breakpad.reportURL", "");

// Disable sending reports of tab crashes to Mozilla
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.enabled", false);

// Disable Shield/Heartbeat/Normandy
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("extensions.shield-recipe-client.enabled", false);
user_pref("app.shield.optoutstudies.enabled", false);

// Disable Firefox Hello metrics collection
user_pref("loop.logDomains", false);

// Enable blocking reported web forgeries
user_pref("browser.safebrowsing.phishing.enabled", true);

// Enable blocking reported attack sites
user_pref("browser.safebrowsing.malware.enabled", true);

// Disable downloading homepage snippets/messages from Mozilla
user_pref("browser.aboutHomeSnippets.updateUrl", "");

// Enable Content Security Policy (CSP)
user_pref("security.csp.experimentalEnabled", true);

// Enable Subresource Integrity
user_pref("security.sri.enable", true);

// Don't send referer headers when following links across different domains
user_pref("network.http.referer.XOriginPolicy", 2);

// Disable new tab tile ads & preload
user_pref("browser.newtabpage.enhanced", false);
user_pref("browser.newtab.preload", false);
user_pref("browser.newtabpage.directory.ping", "");
user_pref("browser.newtabpage.directory.source", "data:text/plain,{}");

// Enable HTTPS-Only Mode
user_pref("dom.security.https_only_mode", true);

// Enable HSTS preload list
user_pref("network.stricttransportsecurity.preloadlist", true);