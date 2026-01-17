# TestFlight GitHub Actions Setup Guide (macOS)

This guide explains how to configure the required secrets for the TestFlight upload workflow for the **macOS version** of ShaderTune.

## Auto-Incrementing Build Numbers

The workflow automatically increments the build number using GitHub's run number. Each time the workflow runs, the build number is set to the workflow run number, ensuring every build has a unique identifier. You don't need to manually increment build numbers.

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:
**Settings > Secrets and variables > Actions > New repository secret**

### 1. BUILD_CERTIFICATE_BASE64
**What it is:** Your Apple Distribution certificate exported as a .p12 file, then base64 encoded.

**How to get it:**
1. Open **Keychain Access** on your Mac
2. Find your **Apple Distribution** certificate (should be under "My Certificates")
   - Look for: "Apple Distribution: [Your Name] ([Team ID])"
3. Right-click the certificate and select **Export "Apple Distribution..."**
4. Choose **File Format: Personal Information Exchange (.p12)**
5. Save it with a password (you'll need this for P12_PASSWORD)
6. Convert to base64:
   ```bash
   base64 -i Certificates.p12 | pbcopy
   ```
7. The base64 string is now in your clipboard - paste it as the secret value

**Note:** If you don't have a distribution certificate:
- Go to https://developer.apple.com/account/resources/certificates
- Click **+** to create a new certificate
- Select **Apple Distribution** under "Software"
- Follow the prompts to create and download the certificate
- Double-click the downloaded .cer file to install it in Keychain Access
- Then follow the export steps above

---

### 2. P12_PASSWORD
**What it is:** The password you used when exporting the .p12 certificate file.

**How to get it:** This is the password you chose in step 5 above when exporting the certificate.

---

### 3. BUILD_PROVISION_PROFILE_BASE64
**What it is:** Your Mac App Store provisioning profile, base64 encoded.

**How to get it:**
1. Go to https://developer.apple.com/account/resources/profiles
2. Find or create a **Mac App Store** provisioning profile for your app
   - Platform: **macOS**
   - Bundle ID: `me.apardee.ShaderTune`
   - Type: **Mac App Store**
   - Certificates: Include your Distribution certificate
3. Download the provisioning profile (.provisionprofile file)
4. Convert to base64:
   ```bash
   base64 -i ShaderTune_MacAppStore.provisionprofile | pbcopy
   ```
5. The base64 string is now in your clipboard - paste it as the secret value

**Note:** If you need to create a new provisioning profile:
- Click **+** on the Profiles page
- Select **Mac App Store** under Distribution
- Choose App ID: `me.apardee.ShaderTune`
- Select your Distribution certificate
- Download and convert to base64

---

### 4. KEYCHAIN_PASSWORD
**What it is:** A temporary password for the CI keychain (can be any secure random string).

**How to get it:** Generate a random password and store it as a secret:
```bash
openssl rand -base64 32 | pbcopy
```

---

### 5. EXPORT_OPTIONS_PLIST
**What it is:** Export options for xcodebuild, base64 encoded.

**How to get it:**
1. Create a file named `ExportOptions.plist` with this content:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>method</key>
       <string>app-store</string>
       <key>teamID</key>
       <string>2HG25473GL</string>
       <key>uploadSymbols</key>
       <true/>
       <key>signingStyle</key>
       <string>manual</string>
       <key>provisioningProfiles</key>
       <dict>
           <key>me.apardee.ShaderTune</key>
           <string>YOUR_PROVISIONING_PROFILE_NAME</string>
       </dict>
   </dict>
   </plist>
   ```
2. Replace `YOUR_PROVISIONING_PROFILE_NAME` with the name of your Mac provisioning profile
   - Find it at https://developer.apple.com/account/resources/profiles
   - Look for the "Name" column (e.g., "ShaderTune Mac App Store")
3. Convert to base64:
   ```bash
   base64 -i ExportOptions.plist | pbcopy
   ```
4. Paste the base64 string as the secret value

---

### 6. APP_STORE_CONNECT_API_KEY_ID
**What it is:** The Key ID from your App Store Connect API key.

**How to get it:**
1. Go to https://appstoreconnect.apple.com/access/integrations/api
2. Click **App Store Connect API** (under "Integrations")
3. If you don't have a key yet, click **Generate API Key**
   - Name: "GitHub Actions" or similar
   - Access: **App Manager** or **Admin**
4. Once generated, you'll see the **Key ID** (format: ABC12DEF34)
5. Copy the Key ID and save it as the secret value

**Important:** The Key ID looks like `ABC12DEF34` (10 alphanumeric characters)

---

### 7. APP_STORE_CONNECT_ISSUER_ID
**What it is:** Your App Store Connect Issuer ID (identifies your team).

**How to get it:**
1. Go to https://appstoreconnect.apple.com/access/integrations/api
2. At the top of the page, you'll see **Issuer ID**
3. Copy the UUID format string (e.g., `12345678-1234-1234-1234-123456789abc`)
4. Save it as the secret value

**Important:** The Issuer ID is a UUID that's shared across all your API keys.

---

### 8. APP_STORE_CONNECT_API_KEY_CONTENT
**What it is:** The private key (.p8 file) for your App Store Connect API key, base64 encoded.

**How to get it:**
1. When you create the API key in step 6, click **Download API Key**
2. You can only download this **once** - if you lose it, you must create a new key
3. Save the downloaded `.p8` file (e.g., `AuthKey_ABC12DEF34.p8`)
4. Convert to base64:
   ```bash
   base64 -i AuthKey_ABC12DEF34.p8 | pbcopy
   ```
5. Paste the base64 string as the secret value

**Important:** Store the .p8 file securely - you cannot re-download it!

---

## Quick Checklist

- [ ] `BUILD_CERTIFICATE_BASE64` - Distribution cert from Keychain Access
- [ ] `P12_PASSWORD` - Password you used when exporting the cert
- [ ] `BUILD_PROVISION_PROFILE_BASE64` - App Store provisioning profile
- [ ] `KEYCHAIN_PASSWORD` - Random password for CI keychain
- [ ] `EXPORT_OPTIONS_PLIST` - Export options with your provisioning profile name
- [ ] `APP_STORE_CONNECT_API_KEY_ID` - Key ID from App Store Connect API
- [ ] `APP_STORE_CONNECT_ISSUER_ID` - Issuer ID from App Store Connect API
- [ ] `APP_STORE_CONNECT_API_KEY_CONTENT` - .p8 private key file

---

## Testing the Workflow

1. Push to the `main` branch or create a tag starting with `v` (e.g., `v1.0.0`)
2. Go to **Actions** tab in your GitHub repository
3. Watch the "Build and Upload to TestFlight" workflow run
4. If successful, check App Store Connect for the build (may take 5-10 minutes to process)

---

## Common Issues

**"No signing certificate"**
- Ensure your Distribution certificate is valid and not expired
- Check that the certificate matches your Team ID (2HG25473GL)
- Verify the P12_PASSWORD is correct

**"No provisioning profile found"**
- Ensure the provisioning profile's Bundle ID matches `me.apardee.ShaderTune`
- Check that the profile is for **macOS** platform
- Check that the profile includes your Distribution certificate
- Verify the profile type is **Mac App Store** (not Developer ID or Development)

**"Invalid API Key"**
- Ensure all three API key values match (Key ID, Issuer ID, and .p8 content)
- Check that the API key has sufficient permissions (App Manager or Admin)
- Verify the .p8 file is base64 encoded correctly

**"Build version already exists"**
- This shouldn't happen since build numbers are auto-incremented
- If it does, verify the workflow is using `agvtool` correctly
- Each workflow run uses a unique GitHub run number as the build number

---

## Important Notes

1. **Platform:** This workflow builds the **macOS** version of ShaderTune (not iOS)
2. **Team ID:** Your Team ID is `2HG25473GL` - this must match in all certificates and profiles
3. **Bundle ID:** Your app's Bundle ID is `me.apardee.ShaderTune`
4. **First Upload:** The first upload to TestFlight requires manual app creation in App Store Connect
   - Go to https://appstoreconnect.apple.com/apps
   - Create a new app if it doesn't exist yet
   - Platform: **macOS**
   - Bundle ID must match `me.apardee.ShaderTune`
5. **Build Numbers:** Automatically incremented using GitHub workflow run numbers - no manual intervention needed

---

## Links

- **App Store Connect:** https://appstoreconnect.apple.com
- **Apple Developer Certificates:** https://developer.apple.com/account/resources/certificates
- **Provisioning Profiles:** https://developer.apple.com/account/resources/profiles
- **App Store Connect API:** https://appstoreconnect.apple.com/access/integrations/api
